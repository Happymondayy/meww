//
//  RevisitRecordRowView.swift
//  meww
//
//  Created by yunseo on 8/18/26.
//

import SwiftUI

/// "❤️ 다시 보고 싶은 기록" 목록 행 — `RevisitRecordsView`(미분류)와 `FolderDetailView`(폴더별)가
/// 같은 모양의 행을 쓴다. 오른쪽 폴더 아이콘을 탭하면 길게 누르기/스와이프 없이도 바로
/// 폴더 이동 다이얼로그를 띄운다.
struct RevisitRecordRowView: View {
    let record: Record
    let onTapFolderIcon: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.recordPlaceholderArt)
                .overlay {
                    if let artworkURL = record.artworkURL {
                        AsyncImage(url: artworkURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: record.category.systemImage)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
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

            Button(action: onTapFolderIcon) {
                Image(systemName: "folder")
                    .foregroundStyle(Color.recordTextSecondary)
                    .padding(8)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    RevisitRecordRowView(
        record: Record(category: .music, title: "1989", creator: "Taylor Swift", rating: 5, wantsToRevisit: true),
        onTapFolderIcon: {}
    )
    .padding()
}
