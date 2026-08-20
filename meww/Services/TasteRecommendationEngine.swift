//
//  TasteRecommendationEngine.swift
//  meww
//
//  Created by yunseo on 8/16/26.
//

import Foundation
import Combine

/// 기록 분석 → 프롬프트 생성 → Gemini 호출 → JSON 파싱 → 표지 검색까지 잇는다.
@MainActor
final class TasteRecommendationEngine: ObservableObject {
    @Published private(set) var cards: [TasteRecommendationCard] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let gemini = GeminiService()
    private let musicSearch = MusicSearchService()
    private let bookSearch = BookSearchService()

    /// 이번 세션에서 이미 보여준 항목 — "다시 추천받기"를 눌렀을 때 겹치지 않게 프롬프트에 넣는다.
    private var previouslyRecommendedItems: [TasteRecommendationItem] = []

    /// 마지막으로 추천을 받았을 때의 전체 기록 수 — 캐시를 불러왔을 때/새로 추천받았을 때 갱신된다.
    /// 이 값과 현재 기록 수가 다르면 기록이 추가·삭제된 것이므로 캐시를 오래된 것으로 본다.
    private var cachedRecordCount: Int?

    private static let cacheKey = "tasteRecommendationCache"

    init() {
        loadCache()
    }

    /// 앱을 껐다 켜도 마지막 추천이 바로 보이도록 캐시를 먼저 쓰고, 그 이후 기록이
    /// 추가·삭제돼 캐시가 안 맞을 때만 자동으로 다시 추천을 받는다 — 매번 새로 부르면
    /// 느리고 Gemini 호출도 낭비라 "달라졌을 때만" 갱신한다.
    func loadIfNeeded(from records: [Record]) async {
        guard cachedRecordCount != records.count else { return }
        await recommend(from: records)
    }

    /// - Parameter records: 전체 기록. `wantsToRevisit`·평점 등에서 취향 프로필을 매번 새로
    ///   뽑기 때문에, 기록이 쌓일수록(별점 4점 이상, 다시 보고 싶어요 표시가 늘수록) 프롬프트에
    ///   담기는 정보도 늘어나 추천이 더 정교해진다.
    func recommend(from records: [Record]) async {
        let profile = records.tasteProfile()
        guard !profile.isEmpty else {
            errorMessage = "기록이 더 쌓이면 추천해줄게요"
            return
        }

        isLoading = true
        errorMessage = nil

        let prompt = profile.geminiPrompt(excluding: previouslyRecommendedItems)
        guard let text = await gemini.generate(prompt: prompt) else {
            errorMessage = gemini.errorMessage ?? "추천을 받아오지 못했어요"
            isLoading = false
            return
        }

        do {
            let result = try Self.parse(text)
            var newCards = result.music.map { TasteRecommendationCard(item: $0, category: .music) }
            newCards += result.books.map { TasteRecommendationCard(item: $0, category: .book) }

            // 표지·링크는 카드마다 동시에 찾는다 — fetchArtworkAndLink는 published 상태를
            // 건드리지 않는 firstResult(for:)를 쓰기 때문에 병렬로 돌려도 서로 덮어쓰지 않는다.
            await withTaskGroup(of: (Int, URL?, URL?).self) { group in
                for index in newCards.indices {
                    let card = newCards[index]
                    group.addTask { [weak self] in
                        guard let self else { return (index, nil, nil) }
                        let (artworkURL, linkURL) = await self.fetchArtworkAndLink(for: card)
                        return (index, artworkURL, linkURL)
                    }
                }
                for await (index, artworkURL, linkURL) in group {
                    newCards[index].artworkURL = artworkURL
                    newCards[index].linkURL = linkURL
                }
            }

            cards = newCards
            previouslyRecommendedItems += result.music + result.books
            cachedRecordCount = records.count
            saveCache(recordCount: records.count)
        } catch {
            // LLM이 JSON 형식을 안 지켰을 때(마크다운 코드블록, 설명 문장 등)를 대비한 처리.
            errorMessage = "추천 형식이 이상해요. 다시 시도해주세요"
        }

        isLoading = false
    }

    private func fetchArtworkAndLink(for card: TasteRecommendationCard) async -> (artworkURL: URL?, linkURL: URL?) {
        let query = "\(card.item.title) \(card.item.creator)"
        switch card.category {
        case .music:
            let result = await musicSearch.firstResult(for: query)
            return (result?.artworkURL, result?.linkURL)
        case .book:
            let result = await bookSearch.firstResult(for: query)
            return (result?.coverURL, result?.linkURL)
        }
    }

    /// Gemini가 ```json ... ``` 코드블록이나 "네, 추천해드릴게요:" 같은 설명을 앞뒤로
    /// 붙이는 경우가 있어서, 첫 "{"부터 마지막 "}"까지만 잘라내고 그 부분만 파싱한다.
    private static func parse(_ text: String) throws -> TasteRecommendationResult {
        guard
            let start = text.firstIndex(of: "{"),
            let end = text.lastIndex(of: "}"),
            start <= end
        else {
            throw TasteRecommendationParseError.noJSONFound
        }

        guard let data = String(text[start...end]).data(using: .utf8) else {
            throw TasteRecommendationParseError.noJSONFound
        }

        let decoded = try JSONDecoder().decode(TasteRecommendationResult.self, from: data)
        guard !decoded.music.isEmpty || !decoded.books.isEmpty else {
            throw TasteRecommendationParseError.emptyResult
        }
        return decoded
    }

    // MARK: - Cache

    private struct CachedRecommendation: Codable {
        let cards: [TasteRecommendationCard]
        let recordCount: Int
    }

    private func loadCache() {
        guard
            let data = UserDefaults.standard.data(forKey: Self.cacheKey),
            let cached = try? JSONDecoder().decode(CachedRecommendation.self, from: data)
        else { return }
        cards = cached.cards
        cachedRecordCount = cached.recordCount
    }

    private func saveCache(recordCount: Int) {
        let cached = CachedRecommendation(cards: cards, recordCount: recordCount)
        guard let data = try? JSONEncoder().encode(cached) else { return }
        UserDefaults.standard.set(data, forKey: Self.cacheKey)
    }
}

private enum TasteRecommendationParseError: Error {
    case noJSONFound
    case emptyResult
}
