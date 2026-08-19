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

    private let gemini = GeminiService()
    private let musicSearch = MusicSearchService()
    private let bookSearch = BookSearchService()

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

        // 선호 아티스트/저자가 많아도 순차 API 호출이 과도해지지 않도록 상위 5명까지만.
        for stat in profile.favoriteCreators.prefix(5) {
            if let section = await loadSection(for: stat) {
                sections.append(section)
            }
        }

        if sections.isEmpty {
            errorMessage = gemini.errorMessage ?? "취향 추천을 만들지 못했어요. 다시 시도해주세요"
        }
    }

    private func loadSection(for stat: TasteProfile.CreatorStat) async -> CreatorRecommendationSection? {
        guard let text = await gemini.generate(prompt: stat.similarRecommendationPrompt()) else {
            return nil
        }
        guard let items = try? Self.parse(text), !items.isEmpty else {
            return nil
        }

        var cards = items.prefix(4).map { TasteRecommendationCard(item: $0, category: stat.category) }

        // 표지는 하나씩 순서대로 찾는다 — MusicSearchService/BookSearchService는 검색 결과를
        // published 프로퍼티 하나에 담는 구조라, 동시에 여러 개를 돌리면 서로 덮어써버린다.
        for index in cards.indices {
            cards[index].artworkURL = await fetchArtwork(for: cards[index])
        }

        return CreatorRecommendationSection(
            creator: stat.creator,
            category: stat.category,
            title: stat.sectionTitle,
            cards: Array(cards)
        )
    }

    private func fetchArtwork(for card: TasteRecommendationCard) async -> URL? {
        let query = "\(card.item.title) \(card.item.creator)"
        switch card.category {
        case .music:
            await musicSearch.search(query)
            return musicSearch.results.first?.artworkURL
        case .book:
            await bookSearch.search(query)
            return bookSearch.results.first?.coverURL
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
