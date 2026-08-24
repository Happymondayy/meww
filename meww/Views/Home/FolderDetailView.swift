//
//  FolderDetailView.swift
//  meww
//
//  Created by yunseo on 8/18/26.
//

import SwiftUI
import SwiftData

/// 폴더 칩을 탭하면 들어오는 폴더 전용 화면. 여기서 다른 폴더로(또는 미분류로) 옮기면
/// 이 목록에서 바로 사라진다 — 기록은 항상 폴더 한 곳(또는 미분류)에만 속한다.
struct FolderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Record.recordedAt, order: .reverse) private var records: [Record]
    @Query(sort: \Folder.createdAt) private var folders: [Folder]

    let folder: Folder

    @State private var selectedRecord: Record?
    @State private var recordPendingFolderAssignment: Record?

    private var folderRecords: [Record] {
        records.filter { $0.wantsToRevisit && $0.folder === folder }
    }

    var body: some View {
        List {
            if folderRecords.isEmpty {
                emptyState
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            } else {
                ForEach(folderRecords) { record in
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

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder")
                .font(.title)
                .foregroundStyle(Color.recordTextSecondary)
            Text("이 폴더엔 기록이 없어요")
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
        FolderDetailView(folder: Folder(name: "다시 볼 앨범"))
    }
    .modelContainer(.recordPreviewContainer)
}
