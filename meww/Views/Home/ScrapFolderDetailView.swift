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
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Record.recordedAt, order: .reverse) private var records: [Record]
    @Query(sort: \Folder.createdAt) private var folders: [Folder]

    let folder: Folder

    @State private var selectedRecord: Record?
    @State private var recordPendingFolderAssignment: Record?
    @State private var showRenameAlert = false
    @State private var renameFolderName = ""
    @State private var showDeleteConfirmation = false

    private var folderScraps: [Record] {
        records.filter {
            $0.isScrapped
                && !$0.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.folder === folder
        }
    }

    var body: some View {
        List {
            if folderScraps.isEmpty {
                emptyState
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(folderScraps) { record in
                    scrapCard(record)
                        .listRowInsets(EdgeInsets(top: .recordSpacingXS, leading: 0, bottom: .recordSpacingXS, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                unscrap(record)
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .contentMargins(.all, .recordSpacingXL, for: .scrollContent)
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        renameFolderName = folder.name
                        showRenameAlert = true
                    } label: {
                        Label("이름 변경", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("폴더 삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("폴더 이름 변경", isPresented: $showRenameAlert) {
            TextField("폴더 이름", text: $renameFolderName)
            Button("취소", role: .cancel) {}
            Button("변경") { renameFolder() }
        }
        .confirmationDialog(
            "이 폴더를 삭제할까요?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) { deleteFolder() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("폴더 안의 기록은 삭제되지 않고 '전체'로 이동해요.")
        }
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

    /// 스크랩 목록에서만 지운다 — 기록 자체(코멘트 포함)는 그대로 두고 `isScrapped`만 끈다.
    private func unscrap(_ record: Record) {
        record.isScrapped = false
        try? modelContext.save()
    }

    private func assignFolder(_ newFolder: Folder?) {
        guard let record = recordPendingFolderAssignment else { return }
        record.folder = newFolder
        try? modelContext.save()
        recordPendingFolderAssignment = nil
    }

    private func renameFolder() {
        let trimmed = renameFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        folder.name = trimmed
        try? modelContext.save()
    }

    private func deleteFolder() {
        modelContext.delete(folder)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ScrapFolderDetailView(folder: Folder(name: "인사이트"))
    }
    .modelContainer(.recordPreviewContainer)
}
