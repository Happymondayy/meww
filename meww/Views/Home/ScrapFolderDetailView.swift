//
//  ScrapFolderDetailView.swift
//  meww
//
//  Created by yunseo on 8/21/26.
//

import SwiftUI
import SwiftData

/// `SentenceScrapView`의 폴더 칩을 탭하면 들어오는 폴더 전용 화면. 여기서 다른 폴더로(또는
/// 미분류로) 옮기면 이 목록에서 바로 사라진다 — `RevisitRecordsView`/`FolderDetailView`와
/// 같은 `Folder`를 공유하지만, 스크랩 카드 스타일로 보여준다는 점만 다르다.
struct ScrapFolderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Record.recordedAt, order: .reverse) private var records: [Record]
    @Query(sort: \Folder.createdAt) private var folders: [Folder]

    let folder: Folder

    @State private var selectedRecord: Record?
    @State private var recordPendingFolderAssignment: Record?

    private var folderScraps: [Record] {
        records.filter {
            $0.isScrapped
                && !$0.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.folder === folder
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if folderScraps.isEmpty {
                    emptyState
                } else {
                    ForEach(folderScraps) { record in
                        scrapCard(record)
                    }
                }
            }
            .padding(.horizontal, .recordSpacingXL)
            .padding(.top, .recordSpacingXL)
            .padding(.bottom, .recordSpacingXL)
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "폴더 선택",
            isPresented: Binding(
                get: { recordPendingFolderAssignment != nil },
                set: { if !$0 { recordPendingFolderAssignment = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("전체(폴더 없음)") { assignFolder(nil) }
            ForEach(folders) { candidate in
                Button(candidate.name) { assignFolder(candidate) }
            }
            Button("취소", role: .cancel) {}
        }
        .sheet(item: $selectedRecord) { record in
            RecordDetailView(record: record)
                .presentationDetents([.fraction(0.72), .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(20)
        }
    }

    private func scrapCard(_ record: Record) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: .recordRadiusXS)
                .fill(Color.recordStatBook)
                .frame(width: 3)

            Button {
                selectedRecord = record
            } label: {
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
            .buttonStyle(.plain)

            Button {
                recordPendingFolderAssignment = record
            } label: {
                Image(systemName: "folder")
                    .foregroundStyle(Color.recordTextSecondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.recordSpacingL)
        .background(Color.recordScrapCardBackground, in: RoundedRectangle(cornerRadius: .recordRadiusM))
        .contextMenu {
            Button {
                recordPendingFolderAssignment = record
            } label: {
                Label("폴더로 이동", systemImage: "folder")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder")
                .font(.title)
                .foregroundStyle(Color.recordTextSecondary)
            Text("이 폴더엔 스크랩이 없어요")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.recordTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, .recordSpacingXXL)
    }

    private func assignFolder(_ newFolder: Folder?) {
        guard let record = recordPendingFolderAssignment else { return }
        record.folder = newFolder
        try? modelContext.save()
        recordPendingFolderAssignment = nil
    }
}

#Preview {
    NavigationStack {
        ScrapFolderDetailView(folder: Folder(name: "인사이트"))
    }
    .modelContainer(.recordPreviewContainer)
}
