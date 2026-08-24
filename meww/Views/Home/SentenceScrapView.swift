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
/// 폴더는 `RevisitRecordsView`와 같은 `Folder`/`Record.folder`를 그대로 공유한다 — 폴더는
/// 기록 자체에 붙는 속성이고, "다시 보고 싶어요"/"문장 스크랩"은 그 위에 얹힌 독립된 필터일
/// 뿐이라 화면마다 폴더를 따로 두지 않는다(애플 메모/인스타페이퍼와 같은 방식).
struct SentenceScrapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Record.recordedAt, order: .reverse) private var records: [Record]
    @Query(sort: \Folder.createdAt) private var folders: [Folder]

    @State private var selectedRecord: Record?
    @State private var recordPendingFolderAssignment: Record?
    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var folderPendingRename: Folder?
    @State private var renameFolderName = ""
    @State private var folderPendingDeletion: Folder?

    private var scraps: [Record] {
        records.filter { $0.isScrapped && !$0.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// 아직 어느 폴더에도 넣지 않은 스크랩 — "전체" 칩의 목록.
    private var unclassifiedScraps: [Record] {
        scraps.filter { $0.folder == nil }
    }

    var body: some View {
        List {
            Section {
                Text("내가 밑줄 그은 문장들만 모아봤어요")
                    .font(.footnote)
                    .foregroundStyle(Color.recordTabInactive)

                folderChipRow
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            if unclassifiedScraps.isEmpty {
                emptyState
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(unclassifiedScraps) { record in
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
        .navigationTitle("문장 스크랩")
        .navigationBarTitleDisplayMode(.inline)
        .alert("새 폴더", isPresented: $showNewFolderAlert) {
            TextField("폴더 이름", text: $newFolderName)
            Button("취소", role: .cancel) { newFolderName = "" }
            Button("만들기") { createFolder() }
        }
        .alert(
            "폴더 이름 변경",
            isPresented: Binding(
                get: { folderPendingRename != nil },
                set: { if !$0 { folderPendingRename = nil } }
            )
        ) {
            TextField("폴더 이름", text: $renameFolderName)
            Button("취소", role: .cancel) { folderPendingRename = nil }
            Button("변경") { renameFolder() }
        }
        .confirmationDialog(
            "이 폴더를 삭제할까요?",
            isPresented: Binding(
                get: { folderPendingDeletion != nil },
                set: { if !$0 { folderPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) { deleteFolder() }
            Button("취소", role: .cancel) { folderPendingDeletion = nil }
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
            ForEach(folders) { folder in
                Button(folder.name) { assignFolder(folder) }
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

    // MARK: - Folder chips

    private var folderChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                folderChipLabel(title: "전체 \(unclassifiedScraps.count)", isSelected: true)

                ForEach(folders) { folder in
                    NavigationLink {
                        ScrapFolderDetailView(folder: folder)
                    } label: {
                        folderChipLabel(title: "\(folder.name) \(count(in: folder))", isSelected: false)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            renameFolderName = folder.name
                            folderPendingRename = folder
                        } label: {
                            Label("이름 변경", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            folderPendingDeletion = folder
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
                }

                Button {
                    showNewFolderAlert = true
                } label: {
                    Text("+ 새 폴더")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.recordTabInactive)
                        .padding(.horizontal, .recordSpacingM)
                        .padding(.vertical, .recordSpacingS)
                        .overlay(
                            RoundedRectangle(cornerRadius: .recordRadiusM)
                                .stroke(Color.recordDragHandle, lineWidth: 1)
                        )
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, .recordSpacingXS)
        }
    }

    private func folderChipLabel(title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(isSelected ? .white : Color.recordFilterInactiveText)
            .padding(.horizontal, .recordSpacingM)
            .padding(.vertical, .recordSpacingS)
            .background(
                isSelected ? Color.recordFilterActiveBackground : Color.recordFilterInactiveBackground,
                in: RoundedRectangle(cornerRadius: .recordRadiusM)
            )
    }

    private func count(in folder: Folder) -> Int {
        scraps.filter { $0.folder === folder }.count
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
            Image(systemName: "bookmark")
                .font(.title)
                .foregroundStyle(Color.recordTextSecondary)
            Text("아직 스크랩한 문장이 없어요")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.recordTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, .recordSpacingXXL)
    }

    // MARK: - Folder actions

    private func createFolder() {
        let trimmed = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        newFolderName = ""
        guard !trimmed.isEmpty else { return }
        let folder = Folder(name: trimmed)
        modelContext.insert(folder)
    }

    /// 스크랩 목록에서만 지운다 — 기록 자체(코멘트 포함)는 그대로 두고 `isScrapped`만 끈다.
    private func unscrap(_ record: Record) {
        record.isScrapped = false
        try? modelContext.save()
    }

    private func assignFolder(_ folder: Folder?) {
        guard let record = recordPendingFolderAssignment else { return }
        record.folder = folder
        try? modelContext.save()
        recordPendingFolderAssignment = nil
    }

    private func renameFolder() {
        let trimmed = renameFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let folder = folderPendingRename, !trimmed.isEmpty else {
            folderPendingRename = nil
            return
        }
        folder.name = trimmed
        try? modelContext.save()
        folderPendingRename = nil
    }

    private func deleteFolder() {
        guard let folder = folderPendingDeletion else { return }
        modelContext.delete(folder)
        try? modelContext.save()
        folderPendingDeletion = nil
    }
}

#Preview {
    NavigationStack {
        SentenceScrapView()
    }
    .modelContainer(.recordPreviewContainer)
}
