//
//  CreatorRecommendationSection.swift
//  meww
//
//  Created by yunseo on 8/19/26.
//

import Foundation

/// "취향 추천 전체보기" — Figma node 165:2에서 아티스트/저자별로 반복되는 섹션 하나.
/// 카드들은 사용자가 실제로 기록한 항목이 아니라, `creator`와 비슷한 새로운 추천이다.
struct CreatorRecommendationSection: Identifiable {
    var id: String { "\(category.rawValue)-\(creator)" }
    let creator: String
    let category: RecordCategory
    let title: String
    let cards: [TasteRecommendationCard]
}

/// 창작자 여러 명 분을 한 번에 요청한 Gemini 응답 형식 — `sections`는 프롬프트에 나열한
/// 창작자 순서와 정확히 대응한다(응답에 창작자 이름을 다시 안 실어서 파싱을 단순하게 유지).
struct CombinedSimilarRecommendationResult: Decodable {
    struct Section: Decodable {
        let items: [TasteRecommendationItem]
    }
    let sections: [Section]
}

extension TasteProfile.CreatorStat {
    /// "Taylor Swift 선호" / "무라카미 하루키 작가 즐겨 읽음" — 아티스트 이름과 카테고리로만
    /// 만든다. `Record`엔 장르 필드가 없어서 "에세이 장르" 같은 문구는 지어낼 수 없다.
    var sectionTitle: String {
        switch category {
        case .music: "\(creator) 선호"
        case .book: "\(creator) 작가 즐겨 읽음"
        }
    }
}

extension Array where Element == TasteProfile.CreatorStat {
    /// 창작자마다 "비슷한 스타일 3개 추천해줘"를 따로따로 요청하면(개당 Gemini 왕복 1회)
    /// 창작자 수만큼 지연이 그대로 늘어난다 — 한 프롬프트에 다 묶어서 Gemini 호출을 1회로
    /// 줄인다. 창작자 본인의 다른 작품이 아니라 비슷한 스타일의 **다른** 아티스트/저자 작품이어야
    /// 하므로 `TasteProfile.geminiPrompt`(전체 취향 기반 5+5개 추천)와는 별도로 다룬다.
    func combinedSimilarRecommendationPrompt() -> String {
        let creatorLines = enumerated().map { index, stat in
            let itemLabel = stat.category == .music ? "곡" : "책"
            return "\(index + 1). \(stat.category.creatorLabel) '\(stat.creator)'의 \(stat.category.rawValue) 기록 \(stat.count)개에 평균 \(String(format: "%.1f", stat.averageRating))점(\(itemLabel) 3개 추천 필요)"
        }.joined(separator: "\n")

        return """
        사용자의 취향 정보 — 아래 각 항목의 아티스트/저자를 사용자가 좋아해요:
        \(creatorLines)

        각 항목마다, 그 아티스트/저자 본인의 다른 작품 말고 비슷한 스타일의 **다른** 아티스트/저자 작품을 3개씩 추천해줘 — 사용자가 아직 안 접해봤을 만한 걸로. 실제로 존재하는 작품만 추천하고, 각 추천마다 원래 아티스트/저자와 왜 비슷한지 한 줄 이유를 붙여줘.
        답변은 아래 JSON 형식으로만 출력하고, 마크다운 코드블록이나 다른 설명 문장은 절대 붙이지 마:
        {"sections":[{"items":[{"title":"제목","creator":"이름","reason":"추천 이유 한 줄"}]}]}
        sections 배열은 위 목록과 정확히 같은 순서로 \(count)개를 넣고, 각 섹션의 items는 정확히 3개씩 넣어줘.
        """
    }
}
