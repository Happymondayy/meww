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
/// 여기서는 `TasteProfile.favoriteCreators`를 하나씩 순회하면서 "이 아티스트/저자와 비슷한
/// 추천"을 카테고리별로 나눠서 요청한다 — 그래야 "OO 선호" 섹션마다 그 아티스트/저자와
/// 실제로 관련 있는 카드만 모인다.
@MainActor
final class CreatorTasteRecommendationEngine: ObservableObject {
    @Published private(set) var sections: [CreatorRecommendationSection] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    func loadSections(from profile: TasteProfile) async {
        guard !profile.favoriteCreators.isEmpty else {
            sections = []
            errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil
        sections = []
        defer { isLoading = false }

        // 선호 아티스트/저자가 많아도 API 호출이 과도해지지 않도록 상위 5명까지만, 그리고
        // 창작자별로 별도 Gemini/검색 인스턴스를 써서 병렬로 요청한다 — 순서대로 기다리면
        // 창작자 수만큼 왕복 시간이 그대로 늘어나 화면이 눈에 띄게 느려진다.
        let stats = Array(profile.favoriteCreators.prefix(5))
        var lastErrorMessage: String?

        await withTaskGroup(of: (CreatorRecommendationSection?, String?).self) { group in
            for stat in stats {
                group.addTask { await Self.loadSection(for: stat) }
            }
            for await (section, failureMessage) in group {
                if let section {
                    sections.append(section)
                } else if let failureMessage {
                    lastErrorMessage = failureMessage
                }
            }
        }

        if sections.isEmpty {
            errorMessage = lastErrorMessage ?? "취향 추천을 만들지 못했어요. 다시 시도해주세요"
        }
    }

    /// 창작자 하나를 처리한다. 매번 새 `GeminiService`/`MusicSearchService`/`BookSearchService`
    /// 인스턴스를 만드는 이유는, 이 서비스들이 검색 결과를 published 프로퍼티 하나에 담는
    /// 구조라 여러 창작자가 동시에 같은 인스턴스를 공유하면 서로 결과를 덮어써버리기 때문이다.
    private static func loadSection(for stat: TasteProfile.CreatorStat) async -> (CreatorRecommendationSection?, String?) {
        let gemini = GeminiService()
        guard let text = await gemini.generate(prompt: stat.similarRecommendationPrompt()) else {
            return (nil, gemini.errorMessage)
        }
        guard let items = try? parse(text), !items.isEmpty else {
            return (nil, "추천 형식이 이상해요. 다시 시도해주세요")
        }

        let musicSearch = MusicSearchService()
        let bookSearch = BookSearchService()
        var cards = items.prefix(4).map { TasteRecommendationCard(item: $0, category: stat.category) }

        // 같은 섹션 안의 카드끼리는 순서대로 찾는다 — 위와 같은 이유로 동시에 여러 개를
        // 돌리면 서로 덮어써버린다. 창작자(섹션)끼리는 서로 다른 인스턴스라 병렬로 돈다.
        for index in cards.indices {
            let (artworkURL, linkURL) = await fetchArtworkAndLink(
                for: cards[index],
                musicSearch: musicSearch,
                bookSearch: bookSearch
            )
            cards[index].artworkURL = artworkURL
            cards[index].linkURL = linkURL
        }

        let section = CreatorRecommendationSection(
            creator: stat.creator,
            category: stat.category,
            title: stat.sectionTitle,
            cards: Array(cards)
        )
        return (section, nil)
    }

    private static func fetchArtworkAndLink(
        for card: TasteRecommendationCard,
        musicSearch: MusicSearchService,
        bookSearch: BookSearchService
    ) async -> (artworkURL: URL?, linkURL: URL?) {
        let query = "\(card.item.title) \(card.item.creator)"
        switch card.category {
        case .music:
            await musicSearch.search(query)
            let result = musicSearch.results.first
            return (result?.artworkURL, result?.linkURL)
        case .book:
            await bookSearch.search(query)
            let result = bookSearch.results.first
            return (result?.coverURL, result?.linkURL)
        }
    }

    /// Gemini가 ```json ... ``` 코드블록이나 설명 문장을 앞뒤로 붙이는 경우가 있어서,
    /// 첫 "{"부터 마지막 "}"까지만 잘라내고 그 부분만 파싱한다.
    private static func parse(_ text: String) throws -> [TasteRecommendationItem] {
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

        return try JSONDecoder().decode(SimilarRecommendationResult.self, from: data).items
    }

    private enum ParseError: Error {
        case noJSONFound
    }
}
