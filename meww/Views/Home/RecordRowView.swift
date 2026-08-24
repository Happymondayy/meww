//
//  RecordRowView.swift
//  meww
//
//  Created by yunseo on 8/15/26.
//

import SwiftUI

struct RecordRowView: View {
    let record: Record

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: .recordRadiusXS)
                .fill(Color.recordPlaceholderArt)
                .overlay {
                    if let artworkURL = record.artworkURL {
                        AsyncImage(url: artworkURL) { image in
                            image.resizable().scaledToFill()
                                .frame(width: 48, height: 48)
                        } placeholder: {
                            Image(systemName: record.category.systemImage)
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(width: 48, height: 48)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: .recordRadiusXS))
                    } else {
                        Image(systemName: record.category.systemImage)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.recordTextPrimary)
                    .lineLimit(1)

                Text(record.creator)
                    .font(.caption)
                    .foregroundStyle(Color.recordTextSecondary)
                    .lineLimit(1)

                revisitTag
            }

            Spacer(minLength: 8)

            Text(record.ratingStars)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.recordRatingGold)
        }
        .padding(.vertical, .recordSpacingS)
    }

    @ViewBuilder
    private var revisitTag: some View {
        Text(record.wantsToRevisit
            ? (record.category == .music ? "다시 듣고 싶어요" : "다시 읽고 싶어요")
            : "한 번이면 충분해요"
        )
            .font(.caption2)
            .fontWeight(record.wantsToRevisit ? .semibold : .regular)
            .foregroundStyle(record.wantsToRevisit ? Color.recordRevisitTagText : Color.recordTextSecondary)
            .padding(.horizontal, .recordSpacingS)
            .padding(.vertical, .recordSpacingXS)
            .background(
                record.wantsToRevisit ? Color.recordRevisitTagBackground : Color.recordOnceTagBackground,
                in: RoundedRectangle(cornerRadius: .recordRadiusXS)
            )
    }
}

#Preview {
    List {
        RecordRowView(record: Record(category: .book, title: "사피엔스", creator: "유발 하라리", rating: 3))
        RecordRowView(record: Record(category: .music, title: "Lover", creator: "Taylor Swift", rating: 4, wantsToRevisit: true))
        RecordRowView(record: Record(category: .music, title: "EARFQUAKE", creator: "Tyler the creator", rating: 5))
    }
    .listStyle(.plain)
}
