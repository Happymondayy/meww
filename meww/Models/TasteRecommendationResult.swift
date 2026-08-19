//
//  TasteRecommendationResult.swift
//  meww
//
//  Created by yunseo on 8/16/26.
//

import Foundation

/// Gemini에게 요청하는 취향 추천 결과 — music/books 각 5개, 항목마다 한 줄 이유.
/// 홈 화면에서 음악/독서 탭으로 필터링해도 4~5개는 남도록 카테고리당 5개를 받는다.
struct TasteRecommendationResult: Decodable {
    let music: [TasteRecommendationItem]
    let books: [TasteRecommendationItem]
}

struct TasteRecommendationItem: Decodable, Identifiable, Hashable {
    var id: String { title + creator }
    let title: String
    let creator: String
    let reason: String
}

/// 화면에 뿌릴 카드 하나 — Gemini가 준 항목 + Apple Music/Google Books에서 찾은 실제 표지·링크.
struct TasteRecommendationCard: Identifiable {
    var id: String { "\(category.rawValue)-\(item.id)" }
    let item: TasteRecommendationItem
    let category: RecordCategory
    var artworkURL: URL?
    /// 아직 기록 안 한 추천이라 Apple Music/Google Books 상세 페이지로 대신 연결한다.
    var linkURL: URL?
}

extension TasteProfile {
    /// `TasteProfile`을 자연스러운 한글 문장으로 풀어서, Gemini에게 JSON 형식으로만
    /// 답하도록 요청하는 프롬프트를 만든다.
    ///
    /// - Parameter excluding: 이전에 이미 추천했던 항목들. "다시 추천받기"를 눌렀을 때
    ///   똑같은 목록이 반복되지 않도록, 있으면 프롬프트에 "이건 빼고" 조건으로 덧붙인다.
    func geminiPrompt(excluding previousItems: [TasteRecommendationItem] = []) -> String {
        var lines: [String] = ["사용자의 음악·독서 취향 기록을 분석한 결과예요."]

        if !favoriteCreators.isEmpty {
            let described = favoriteCreators.prefix(6).map { stat in
                "\(stat.creator)(\(stat.category.rawValue), \(stat.count)개, 평균 \(String(format: "%.1f", stat.averageRating))점)"
            }.joined(separator: ", ")
            lines.append("평점 4점 이상을 준 아티스트/저자: \(described)")
        }

        if !revisitMusic.isEmpty {
            let titles = revisitMusic.prefix(6).map { "\($0.title)(\($0.creator))" }.joined(separator: ", ")
            lines.append("다시 듣고 싶다고 표시한 음악: \(titles)")
        }

        if !revisitBooks.isEmpty {
            let titles = revisitBooks.prefix(6).map { "\($0.title)(\($0.creator))" }.joined(separator: ", ")
            lines.append("다시 읽고 싶다고 표시한 책: \(titles)")
        }

        lines.append("지금까지 음악 \(musicCount)개, 독서 \(bookCount)개를 기록했어요.")

        if !previousItems.isEmpty {
            let previous = previousItems.prefix(20).map { "\($0.title)(\($0.creator))" }.joined(separator: ", ")
            lines.append("다음은 이전에 이미 추천했던 항목이니 이번엔 겹치지 않게 다른 걸 추천해줘: \(previous)")
        }

        lines.append(
            """
            이 정보를 바탕으로 이 사용자가 좋아할 만한 음악 5개, 책 5개를 추천해줘. \
            실제로 존재하는 곡·책으로 추천하고, 각 추천마다 왜 추천하는지 한 줄 이유를 붙여줘. \
            답변은 아래 JSON 형식으로만 출력하고, 마크다운 코드블록이나 다른 설명 문장은 절대 붙이지 마:
            {"music":[{"title":"곡 제목","creator":"아티스트","reason":"추천 이유 한 줄"}],"books":[{"title":"책 제목","creator":"저자","reason":"추천 이유 한 줄"}]}
            music과 books 배열은 각각 정확히 5개씩 넣어줘.
            """
        )

        return lines.joined(separator: "\n")
    }
}
