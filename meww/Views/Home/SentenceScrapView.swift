//
//  SentenceScrapView.swift
//  meww
//
//  Created by yunseo on 8/16/26.
//

import SwiftUI
import SwiftData

/// "📑 문장 스크랩" — Figma node 17:2. `HomeView`의 "문장스크랩" 칩에서 진입한다.
/// 사용자가 북마크로 직접 체크한(`isScrapped`) 기록만 모아 보여준다 — `comment`가 채워졌다고
/// 자동으로 여기 들어가지 않는다. 홈 화면 칩의 개수(`HomeView.scrapCount`)와 같은 기준이라
/// 숫자가 항상 일치한다.
///
/// Figma 목업엔 사용자가 만든 폴더(힐링 문장/인사이트/+ 새 폴더)가 있지만, `Record`엔 폴더를
/// 저장할 데이터가 없다 — 동작하지 않는 폴더를 가짜로 보여주는 대신 실제로 전부를 보여주는
/// "전체" 칩만 남겨뒀다.
struct SentenceScrapView: View {
    @Query(sort: \Record.recordedAt, order: .reverse) private var records: [Record]

    private var scraps: [Record] {
        records.filter { $0.isScrapped && !$0.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("내가 밑줄 그은 문장들만 모아봤어요")
                    .font(.footnote)
                    .foregroundStyle(Color.recordTabInactive)

                folderChip

                if scraps.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(scraps) { record in
                            scrapCard(record)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("문장 스크랩")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var folderChip: some View {
        Text("📁 전체 \(scraps.count)")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.recordFilterActiveBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    private func scrapCard(_ record: Record) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.recordStatBook)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 10) {
                Text(record.comment)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.recordScrapCardText)

                HStack(spacing: 4) {
                    Text(record.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.recordScrapCardMetaTitle)
                    Text("· \(record.creator) · \(record.recordedAtCompact)")
                        .foregroundStyle(Color.recordScrapCardMetaSecondary)
                }
                .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.recordScrapCardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bookmark")
                .font(.title)
                .foregroundStyle(Color.recordTextSecondary)
            Text("아직 스크랩한 문장이 없어요")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.recordTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

#Preview {
    NavigationStack {
        SentenceScrapView()
    }
    .modelContainer(.recordPreviewContainer)
}
