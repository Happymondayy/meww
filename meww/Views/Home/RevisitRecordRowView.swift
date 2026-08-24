//
//  RevisitRecordRowView.swift
//  meww
//
//  Created by yunseo on 8/18/26.
//

import SwiftUI

/// "❤️ 다시 보고 싶은 기록" 목록 행 — `RevisitRecordsView`(미분류)와 `FolderDetailView`(폴더별)가
/// 같은 모양의 행을 쓴다. 폴더 이동은 스와이프/길게 누르기로 한다 — 폴더 칩을 스크롤해서
/// 옮겨 다닐 수 있게 된 뒤로는 행마다 따로 폴더 아이콘을 둘 필요가 없어졌다.
struct RevisitRecordRowView: View {
    let record: Record

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: .recordRadiusXS)
                .fill(Color.recordPlaceholderArt)
                .overlay {
                    if let artworkURL = record.artworkURL {
                        AsyncImage(url: artworkURL) { image in
                            image.resizable().scaledToFill()
                                .frame(width: 52, height: 52)
                        } placeholder: {
                            Image(systemName: record.category.systemImage)
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(width: 52, height: 52)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: .recordRadiusXS))
                    } else {
                        Image(systemName: record.category.systemImage)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.recordTextPrimary)
                    .lineLimit(1)
                Text(record.creator)
                    .font(.caption)
                    .foregroundStyle(Color.recordTextSecondary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text("♥")
                        .foregroundStyle(Color.recordStatBook)
                    Text(record.recordedAtCompact)
                        .foregroundStyle(Color.recordTextSecondary)
                }
                .font(.caption2)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, .recordSpacingS)
    }
}

#Preview {
    RevisitRecordRowView(
        record: Record(category: .music, title: "1989", creator: "Taylor Swift", rating: 5, wantsToRevisit: true)
    )
    .padding()
}
