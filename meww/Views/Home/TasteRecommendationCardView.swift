//
//  TasteRecommendationCardView.swift
//  meww
//
//  Created by yunseo on 8/16/26.
//

import SwiftUI

/// 취향 추천 카드 하나. 아직 기록되지 않은 항목이라 표지는 검색해서 채운 것(`card.artworkURL`)이고,
/// 없으면 다른 카드처럼 아이콘 플레이스홀더로 대체한다. 탭하면 음악은 Apple Music 상세 페이지,
/// 독서는 예스24 검색 결과(`card.linkURL`)로 연결한다 — 마음에 들어도 더 볼 방법이 없었던 걸 보완한다.
struct TasteRecommendationCardView: View {
    let card: TasteRecommendationCard
    /// 더보기 화면에서만 추천 이유를 같이 보여준다 — 홈 화면 미리보기는 짧게 유지.
    var showsReason = false

    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            guard let linkURL = card.linkURL else { return }
            openURL(linkURL)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                artwork

                HStack(spacing: 2) {
                    Text(card.item.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.recordTextPrimary)
                        .lineLimit(1)

                    if card.linkURL != nil {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color.recordTextSecondary)
                    }
                }

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
        .buttonStyle(.plain)
    }

    private var artwork: some View {
        RoundedRectangle(cornerRadius: .recordRadiusS)
            .fill(Color.recordPlaceholderArt)
            .overlay {
                if let artworkURL = card.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image.resizable().scaledToFill()
                            .frame(width: 96, height: 96)
                    } placeholder: {
                        Image(systemName: card.category.systemImage)
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 96, height: 96)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: .recordRadiusS))
                } else {
                    Image(systemName: card.category.systemImage)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(width: 96, height: 96)
    }
}

#Preview {
    TasteRecommendationCardView(
        card: TasteRecommendationCard(
            item: TasteRecommendationItem(title: "1989", creator: "Taylor Swift", reason: "신스팝 취향과 잘 맞아요"),
            category: .music,
            linkURL: URL(string: "https://music.apple.com")
        ),
        showsReason: true
    )
    .padding()
}
