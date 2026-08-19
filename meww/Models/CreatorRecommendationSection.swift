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

/// "이 아티스트/저자와 비슷한 걸 3개 추천해줘" 요청에 대한 Gemini 응답 형식.
struct SimilarRecommendationResult: Decodable {
    let items: [TasteRecommendationItem]
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

    /// `creator` 본인의 다른 작품이 아니라, 비슷한 스타일의 **다른** 아티스트/저자 작품 3개를
    /// 새로 추천해달라는 프롬프트. 사용자가 이미 기록한 항목이 아니라 새로운 추천이어야 하므로
    /// `TasteProfile.geminiPrompt`(전체 취향 기반 5+5개 추천)와는 별도로 아티스트/저자 하나당
    /// 하나씩 나눠서 요청한다.
    func similarRecommendationPrompt() -> String {
        let categoryLabel = category.rawValue
        let creatorLabel = category.creatorLabel
        let itemLabel = category == .music ? "곡" : "책"

        return """
        사용자는 \(creatorLabel) '\(creator)'의 \(categoryLabel) 기록 \(count)개에 평균 \(String(format: "%.1f", averageRating))점을 줬어요. 이 사용자는 '\(creator)'을(를) 좋아해요.
        '\(creator)'와(과) 비슷한 스타일의 \(categoryLabel) \(itemLabel) 3개를 추천해줘. '\(creator)' 본인의 작품 말고, 사용자가 아직 안 접해봤을 만한 다른 \(creatorLabel)의 작품으로 추천해줘.
        실제로 존재하는 \(itemLabel)만 추천하고, 각 추천마다 '\(creator)'와(과) 왜 비슷한지 한 줄 이유를 붙여줘.
        답변은 아래 JSON 형식으로만 출력하고, 마크다운 코드블록이나 다른 설명 문장은 절대 붙이지 마:
        {"items":[{"title":"\(itemLabel) 제목","creator":"\(creatorLabel) 이름","reason":"추천 이유 한 줄"}]}
        items 배열엔 정확히 3개를 넣어줘.
        """
    }
}
