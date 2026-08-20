//
//  CreatorTasteRecommendationEngine.swift
//  meww
//
//  Created by yunseo on 8/19/26.
//

import Foundation
import Combine

/// "취향 추천 전체보기" 화면의 아티스트/저자별 섹션을 만든다.
///
/// `TasteRecommendationEngine`은 취향 전체를 한 번에 묶어 음악 5개·책 5개를 추천받지만,
/// 여기서는 `TasteProfile.favoriteCreators` 상위 5명을 한 프롬프트에 묶어 "이 아티스트/저자와
/// 비슷한 추천"을 창작자별로 나눠서 한 번에 요청한다 — 그래야 "OO 선호" 섹션마다 그
/// 아티스트/저자와 실제로 관련 있는 카드만 모이면서도 Gemini 왕복은 한 번으로 끝난다.
@MainActor
final class CreatorTasteRecommendationEngine: ObservableObject {
    @Published private(set) var sections: [CreatorRecommendationSection] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    /// 마지막으로 추천을 받았을 때의 전체 기록 수 — 이 값과 현재 기록 수가 다르면 캐시를
    /// 오래된 것으로 보고 자동으로 다시 추천을 받는다.
    private var cachedRecordCount: Int?

    private static let cacheKey = "creatorTasteRecommendationCache"

    init() {
        loadCache()
    }

    /// 앱을 껐다 켜거나 "더보기"에 다시 들어와도 캐시를 먼저 보여주고, 그 이후 기록이
    /// 추가·삭제돼 캐시가 안 맞을 때만 자동으로 다시 추천을 받는다.
    func loadSectionsIfNeeded(from profile: TasteProfile) async {
        guard cachedRecordCount != profile.totalCount else { return }
        await loadSections(from: profile)
    }

    func loadSections(from profile: TasteProfile) async {
        guard !profile.favoriteCreators.isEmpty else {
            sections = []
            errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // 창작자별로 Gemini를 따로 부르면(예전 방식) 창작자 수만큼 왕복 시간이 그대로
        // 늘어난다 — 상위 5명을 한 프롬프트에 묶어서 Gemini는 딱 한 번만 부른다. 창작자별
        // 카드 표지·링크 검색만 아래에서 병렬로 돈다.
        let stats = Array(profile.favoriteCreators.prefix(5))
        let gemini = GeminiService()

        guard let text = await gemini.generate(prompt: stats.combinedSimilarRecommendationPrompt()) else {
            // 실패해도 기존 sections(캐시)는 그대로 둔다 — 백그라운드 자동 갱신이 실패했다고
            // 화면에 이미 떠 있던 카드를 지울 이유는 없다.
            errorMessage = gemini.errorMessage ?? "취향 추천을 만들지 못했어요. 다시 시도해주세요"
            return
        }

        guard let itemSections = try? Self.parse(text), !itemSections.isEmpty else {
            errorMessage = "추천 형식이 이상해요. 다시 시도해주세요"
            return
        }

        // Gemini 응답의 sections 배열은 프롬프트에 나열한 순서와 대응한다 — zip으로 개수가
        // 안 맞아도(응답이 일부 누락돼도) 안전하게 앞에서부터 짝지운다.
        var newSections: [CreatorRecommendationSection] = []
        await withTaskGroup(of: CreatorRecommendationSection?.self) { group in
            for (stat, items) in zip(stats, itemSections) {
                group.addTask { await Self.buildSection(for: stat, items: items) }
            }
            for await section in group {
                if let section {
                    newSections.append(section)
                }
            }
        }

        guard !newSections.isEmpty else {
            errorMessage = "취향 추천을 만들지 못했어요. 다시 시도해주세요"
            return
        }

        sections = newSections
        cachedRecordCount = profile.totalCount
        saveCache(recordCount: profile.totalCount)
    }

    /// 창작자 하나의 섹션을 만든다. 카드 표지·링크 검색만 여기서 창작자별로 병렬로 돈다.
    private static func buildSection(
        for stat: TasteProfile.CreatorStat,
        items: [TasteRecommendationItem]
    ) async -> CreatorRecommendationSection? {
        guard !items.isEmpty else { return nil }

        let musicSearch = MusicSearchService()
        let bookSearch = BookSearchService()
        var cards = items.prefix(4).map { TasteRecommendationCard(item: $0, category: stat.category) }

        // 같은 섹션 안의 카드끼리도 동시에 찾는다 — fetchArtworkAndLink가 published 상태를
        // 건드리지 않는 firstResult(for:)를 쓰기 때문에 병렬로 돌려도 서로 덮어쓰지 않는다.
        // 창작자(섹션)끼리는 이미 서로 다른 인스턴스라 병렬로 돈다.
        await withTaskGroup(of: (Int, URL?, URL?).self) { group in
            for index in cards.indices {
                let card = cards[index]
                group.addTask {
                    let (artworkURL, linkURL) = await fetchArtworkAndLink(
                        for: card,
                        musicSearch: musicSearch,
                        bookSearch: bookSearch
                    )
                    return (index, artworkURL, linkURL)
                }
            }
            for await (index, artworkURL, linkURL) in group {
                cards[index].artworkURL = artworkURL
                cards[index].linkURL = linkURL
            }
        }

        return CreatorRecommendationSection(
            creator: stat.creator,
            category: stat.category,
            title: stat.sectionTitle,
            cards: Array(cards)
        )
    }

    private static func fetchArtworkAndLink(
        for card: TasteRecommendationCard,
        musicSearch: MusicSearchService,
        bookSearch: BookSearchService
    ) async -> (artworkURL: URL?, linkURL: URL?) {
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

    /// Gemini가 ```json ... ``` 코드블록이나 설명 문장을 앞뒤로 붙이는 경우가 있어서,
    /// 첫 "{"부터 마지막 "}"까지만 잘라내고 그 부분만 파싱한다.
    private static func parse(_ text: String) throws -> [[TasteRecommendationItem]] {
        guard
            let start = text.firstIndex(of: "{"),
            let end = text.lastIndex(of: "}"),
            start <= end
        else {
            throw ParseError.noJSONFound
        }

        guard let data = String(text[start...end]).data(using: .utf8) else {
            throw ParseError.noJSONFound
        }

        let decoded = try JSONDecoder().decode(CombinedSimilarRecommendationResult.self, from: data)
        return decoded.sections.map { $0.items }
    }

    private enum ParseError: Error {
        case noJSONFound
    }

    // MARK: - Cache

    private struct CachedSections: Codable {
        let sections: [CreatorRecommendationSection]
        let recordCount: Int
    }

    private func loadCache() {
        guard
            let data = UserDefaults.standard.data(forKey: Self.cacheKey),
            let cached = try? JSONDecoder().decode(CachedSections.self, from: data)
        else { return }
        sections = cached.sections
        cachedRecordCount = cached.recordCount
    }

    private func saveCache(recordCount: Int) {
        let cached = CachedSections(sections: sections, recordCount: recordCount)
        guard let data = try? JSONEncoder().encode(cached) else { return }
        UserDefaults.standard.set(data, forKey: Self.cacheKey)
    }
}
