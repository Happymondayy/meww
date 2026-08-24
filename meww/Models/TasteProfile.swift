//
//  TasteProfile.swift
//  meww
//
//  Created by yunseo on 8/16/26.
//

import Foundation

/// 저장된 `Record`들을 분석한 결과 — Gemini에게 취향 추천을 요청하는 프롬프트의 재료가 된다.
struct TasteProfile {
    struct CreatorStat: Identifiable {
        var id: String { "\(category.rawValue)-\(creator)" }
        let creator: String
        let category: RecordCategory
        let count: Int
        let averageRating: Double
    }

    /// 평점 4점 이상을 준 아티스트/저자 — 기록 개수 많은 순.
    let favoriteCreators: [CreatorStat]
    /// "다시 듣고 싶어요"로 표시한 음악 기록.
    let revisitMusic: [Record]
    /// "다시 읽고 싶어요"로 표시한 독서 기록.
    let revisitBooks: [Record]
    /// 음악/독서 기록 개수.
    ///
    /// `Record`엔 장르(에세이/판타지 등) 필드가 없어서 "장르별 빈도"를 문자 그대로는 낼 수
    /// 없다 — 대신 실제로 있는 데이터인 카테고리(음악/독서)별 빈도를 쓴다.
    let musicCount: Int
    let bookCount: Int
    /// 전체 기록 개수 — "총 기록" 통계 카드용.
    let totalCount: Int
    /// 전체 기록의 평균 별점 — "평균 별점" 통계 카드용. 기록이 없으면 0.
    let averageRating: Double

    var isEmpty: Bool {
        favoriteCreators.isEmpty && revisitMusic.isEmpty && revisitBooks.isEmpty
    }
}

extension Array where Element == Record {
    /// 평점 4점 이상 아티스트/저자, 다시 듣고/읽고 싶어요 표시, 카테고리별 빈도를 뽑아낸다.
    func tasteProfile() -> TasteProfile {
        let highRated = filter { $0.rating >= 4 }
        let groupedByCreator = Dictionary(grouping: highRated) { "\($0.category.rawValue)|\($0.creator)" }

        let favoriteCreators = groupedByCreator
            .compactMap { _, records -> TasteProfile.CreatorStat? in
                guard let first = records.first else { return nil }
                let average = Double(records.reduce(0) { $0 + $1.rating }) / Double(records.count)
                return TasteProfile.CreatorStat(
                    creator: first.creator,
                    category: first.category,
                    count: records.count,
                    averageRating: average
                )
            }
            .sorted {
                $0.count != $1.count ? $0.count > $1.count : $0.averageRating > $1.averageRating
            }

        return TasteProfile(
            favoriteCreators: favoriteCreators,
            revisitMusic: filter { $0.wantsToRevisit && $0.category == .music },
            revisitBooks: filter { $0.wantsToRevisit && $0.category == .book },
            musicCount: filter { $0.category == .music }.count,
            bookCount: filter { $0.category == .book }.count,
            totalCount: count,
            averageRating: isEmpty ? 0 : Double(reduce(0) { $0 + $1.rating }) / Double(count)
        )
    }
}
