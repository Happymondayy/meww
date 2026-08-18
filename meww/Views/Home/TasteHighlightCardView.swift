//
//  TasteHighlightCardView.swift
//  meww
//
//  Created by yunseo on 8/15/26.
//

import SwiftUI

/// A single card in the horizontal "취향 추천" strip — highlights a highly-rated record.
struct TasteHighlightCardView: View {
    let record: Record

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.recordPlaceholderArt)
                .overlay {
                    if let artworkURL = record.artworkURL {
                        AsyncImage(url: artworkURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: record.category.systemImage)
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(systemName: record.category.systemImage)
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(width: 96, height: 96)

            Text(record.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.recordTextPrimary)
                .lineLimit(1)

            Text(record.creator)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(Color.recordAccentPink)
                .lineLimit(1)
        }
        .frame(width: 96, alignment: .leading)
    }
}

#Preview {
    TasteHighlightCardView(record: Record(category: .music, title: "1989", creator: "Taylor Swift", rating: 5))
        .padding()
}
