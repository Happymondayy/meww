//
//  AllRecordsView.swift
//  meww
//
//  Created by yunseo on 8/20/26.
//

import SwiftUI
import SwiftData

/// "전체 기록" — `HomeView`는 최근 기록 몇 개만 미리보기로 보여주고, 월별로 전부 훑어보는
/// 목록은 여기로 분리했다. 기록이 쌓일수록 홈 화면 스크롤이 한없이 길어지는 걸 막기 위함.
///
/// `CalendarView`도 과거 기록 전체를 훑어보는 진입점이지만 "언제 기록했는지"(날짜 그리드) 위주라,
/// 여기는 제목·아티스트로 찾는 "찾아보기" 역할을 맡는다 — 그래서 검색이 이 화면에만 있다.
struct AllRecordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Record.recordedAt, order: .reverse) private var records: [Record]

    @State private var selectedCategory: RecordCategory?
    @State private var selectedRecord: Record?
    @State private var searchText = ""

    /// 홈 화면에서 이미 카테고리를 골라둔 상태로 "전체보기"를 눌렀다면 그 선택을 이어받는다.
    init(initialCategory: RecordCategory? = nil) {
        _selectedCategory = State(initialValue: initialCategory)
    }

    var body: some View {
        List {
            Section {
                categoryFilterRow
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }

            if monthGroups.isEmpty {
                emptyState
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            } else {
                ForEach(monthGroups, id: \.month) { group in
                    Section {
                        Text(group.month.koreanMonthTitle)
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.recordTextSecondary)
                            .listRowInsets(EdgeInsets(top: .recordSpacingL, leading: 0, bottom: .recordSpacingS, trailing: 0))
                            .listRowSeparator(.hidden)

                        ForEach(group.records) { record in
                            Button {
                                selectedRecord = record
                            } label: {
                                RecordRowView(record: record)
                            }
                            .buttonStyle(.borderless)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparatorTint(Color.recordSeparator)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(record)
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .contentMargins(.horizontal, .recordSpacingXL, for: .scrollContent)
        .navigationTitle("전체 기록")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "제목·아티스트 검색")
        .sheet(item: $selectedRecord) { record in
            RecordDetailView(record: record)
                .presentationDetents([.fraction(0.72), .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(20)
        }
    }

    // MARK: - Category filter

    private var categoryFilterRow: some View {
        HStack(spacing: 8) {
            filterChip(title: "전체", count: records.count, isSelected: selectedCategory == nil) {
                selectedCategory = nil
            }
            ForEach(RecordCategory.allCases) { category in
                filterChip(
                    title: category.rawValue,
                    count: records.filter { $0.category == category }.count,
                    isSelected: selectedCategory == category
                ) {
                    selectedCategory = category
                }
            }
        }
    }

    private func filterChip(title: String, count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : Color.recordFilterInactiveText)

                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : Color.recordFilterBadgeText)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(
                        isSelected ? Color.white.opacity(0.2) : Color.recordFilterBadgeBackground,
                        in: Circle()
                    )
            }
            .padding(.horizontal, .recordSpacingM)
            .padding(.vertical, .recordSpacingS)
            .background(
                isSelected ? Color.recordFilterActiveBackground : Color.recordFilterInactiveBackground,
                in: RoundedRectangle(cornerRadius: .recordRadiusL)
            )
        }
        .buttonStyle(.borderless)
    }

    // MARK: - Monthly grouping

    private var filteredRecords: [Record] {
        records.filter { record in
            (selectedCategory == nil || record.category == selectedCategory) && matchesSearch(record)
        }
    }

    private func matchesSearch(_ record: Record) -> Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return record.title.localizedCaseInsensitiveContains(trimmed)
            || record.creator.localizedCaseInsensitiveContains(trimmed)
    }

    private var monthGroups: [(month: Date, records: [Record])] {
        filteredRecords.groupedByMonth()
    }

    // MARK: - Empty state

    /// 검색 중엔 "검색 결과가 없어요", 검색어가 없으면(카테고리 필터만 걸렸거나 기록 자체가
    /// 없으면) "기록이 없어요" — 검색 안 했는데 "결과 없음"이라고 하면 오해를 살 수 있어서 나눴다.
    private var emptyState: some View {
        VStack(spacing: 8) {
            let isSearching = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            Image(systemName: isSearching ? "magnifyingglass" : "tray")
                .font(.title)
                .foregroundStyle(Color.recordTextSecondary)
            Text(isSearching ? "검색 결과가 없어요" : "기록이 없어요")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.recordTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, .recordSpacingXXL)
    }
}

#Preview {
    NavigationStack {
        AllRecordsView()
    }
    .modelContainer(.recordPreviewContainer)
}
