//
//  RevisitRecordsView.swift
//  meww
//
//  Created by yunseo on 8/16/26.
//

import SwiftUI
import SwiftData

/// "❤️ 다시 보고 싶은 기록" — Figma node 44:2. `HomeView`의 "다시듣고싶어요" 칩에서 진입한다.
/// `wantsToRevisit == true`인 기록만 모으고, 사용자가 직접 만드는 `Folder`로 정리할 수 있다.
///
/// 기록은 항상 "미분류(전체)" 또는 폴더 한 곳에만 속한다 — 폴더로 옮기면 이 화면(미분류
/// 목록)에서는 빠지고, 폴더 칩을 탭하면 `FolderDetailView`로 들어가 그 폴더 안 기록만 본다.
struct RevisitRecordsView: View {
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

    private var revisitRecords: [Record] {
        records.filter(\.wantsToRevisit)
    }

    /// 아직 어느 폴더에도 넣지 않은 기록 — "전체" 칩의 목록.
    private var unclassifiedRecords: [Record] {
        revisitRecords.filter { $0.folder == nil }
    }

    var body: some View {
        List {
            Section {
                folderChipRow
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }

            if unclassifiedRecords.isEmpty {
                emptyState
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            } else {
                ForEach(unclassifiedRecords) { record in
                    Button {
                        selectedRecord = record
                    } label: {
                        RevisitRecordRowView(record: record) {
                            recordPendingFolderAssignment = record
                        }
                    }
                    .buttonStyle(.borderless)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparatorTint(Color.recordSeparator)
                    .swipeActions(edge: .trailing) {
                        Button {
                            recordPendingFolderAssignment = record
                        } label: {
                            Label("폴더", systemImage: "folder")
                        }
                        .tint(Color.recordFilterActiveBackground)
                    }
                    .contextMenu {
                        Button {
                            recordPendingFolderAssignment = record
                        } label: {
                            Label("폴더로 이동", systemImage: "folder")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .contentMargins(.horizontal, .recordSpacingXL, for: .scrollContent)
        .navigationTitle("다시 보고 싶은 기록")
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
                folderChipLabel(title: "전체 \(unclassifiedRecords.count)", isSelected: true)

                ForEach(folders) { folder in
                    NavigationLink {
                        FolderDetailView(folder: folder)
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
        revisitRecords.filter { $0.folder === folder }.count
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart")
                .font(.title)
                .foregroundStyle(Color.recordTextSecondary)
            Text("아직 다시 보고 싶은 기록이 없어요")
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
        RevisitRecordsView()
    }
    .modelContainer(.recordPreviewContainer)
}
