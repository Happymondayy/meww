//
//  TasteRecommendationCardView.swift
//  meww
//
//  Created by yunseo on 8/16/26.
//

import SwiftUI

/// 취향 추천 카드 하나 — `TasteHighlightCardView`와 같은 크기·레이아웃을 쓴다.
/// 아직 기록되지 않은 항목이라 표지는 검색해서 채운 것(`card.artworkURL`)이고, 없으면
/// 다른 카드처럼 아이콘 플레이스홀더로 대체한다.
struct TasteRecommendationCardView: View {
    let card: TasteRecommendationCard
    /// 더보기 화면에서만 추천 이유를 같이 보여준다 — 홈 화면 미리보기는 짧게 유지.
    var showsReason = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.recordPlaceholderArt)
                .overlay {
                    if let artworkURL = card.artworkURL {
                        AsyncImage(url: artworkURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: card.category.systemImage)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(systemName: card.category.systemImage)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(width: 96, height: 96)

            Text(card.item.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.recordTextPrimary)
                .lineLimit(1)

            Text(card.item.creator)
                .font(.caption2)
                .foregroundStyle(Color.recordAccentPink)
                .fontWeight(.bold)
                .lineLimit(1)

            if showsReason {
                Text(card.item.reason)
                    .font(.caption2)
                    .foregroundStyle(Color.recordTextSecondary)
                    .lineLimit(2)
            }
        }
        .frame(width: 96, alignment: .leading)
    }
}

#Preview {
    TasteRecommendationCardView(
        card: TasteRecommendationCard(
            item: TasteRecommendationItem(title: "1989", creator: "Taylor Swift", reason: "신스팝 취향과 잘 맞아요"),
            category: .music
        ),
        showsReason: true
    )
    .padding()
}
