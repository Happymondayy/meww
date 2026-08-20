//
//  HomeView.swift
//  meww
//
//  Created by yunseo on 8/15/26.
//

import SwiftUI
import SwiftData

/// "🏠 홈" — Figma node 78:2 (전체) / 59:73 (카테고리 탭). `selectedCategory`가
/// 화면 전체를 두 프레임 사이에서 전환한다.
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Record.recordedAt, order: .reverse) private var records: [Record]

    @StateObject private var tasteEngine = TasteRecommendationEngine()

    @State private var selectedCategory: RecordCategory?
    @State private var showTasteRecommendation = false
    @State private var showSentenceScrap = false
    @State private var showRevisitRecords = false
    @State private var showAllRecords = false
    @State private var selectedRecord: Record?

    /// 홈엔 최근 기록만 미리 보여준다 — 전부는 "전체보기"로 들어간 `AllRecordsView`에서 본다.
    /// 데이터가 쌓일수록 홈 화면 스크롤이 한없이 길어지는 걸 막기 위함.
    private let recentRecordsPreviewLimit = 5

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    headerSummary
                    quickAccessRow
                    tasteHighlightsSection
                    categoryFilterRow
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }

            Section {
                recentRecordsHeader
                    .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0))
                    .listRowSeparator(.hidden)

                if previewRecords.isEmpty {
                    Text("아직 기록이 없어요")
                        .font(.caption)
                        .foregroundStyle(Color.recordTextSecondary)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 24, trailing: 0))
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(previewRecords) { record in
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
        .listStyle(.plain)
        .contentMargins(.horizontal, 24, for: .scrollContent)
        .navigationDestination(isPresented: $showTasteRecommendation) {
            TasteRecommendationView()
        }
        .navigationDestination(isPresented: $showSentenceScrap) {
            SentenceScrapView()
        }
        .navigationDestination(isPresented: $showRevisitRecords) {
            RevisitRecordsView()
        }
        .navigationDestination(isPresented: $showAllRecords) {
            AllRecordsView(initialCategory: selectedCategory)
        }
        .sheet(item: $selectedRecord) { record in
            RecordDetailView(record: record)
                .presentationDetents([.fraction(0.72), .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(20)
        }
    }

    // MARK: - Header

    private var thisMonthRecords: [Record] {
        records.filter { Calendar.current.isDate($0.recordedAt, equalTo: .now, toGranularity: .month) }
    }

    private var headerSummaryText: String {
        switch selectedCategory {
        case nil:
            let musicCount = thisMonthRecords.filter { $0.category == .music }.count
            let bookCount = thisMonthRecords.filter { $0.category == .book }.count
            return "이번 달 음악 \(musicCount)개\n독서 \(bookCount)개 기록했어요"
        case .music, .book:
            let category = selectedCategory!
            let count = thisMonthRecords.filter { $0.category == category }.count
            return "이번 달 \(category.rawValue)\n\(count)개 기록했어요"
        }
    }

    private var headerSummary: some View {
        Text(headerSummaryText)
            .font(.title)
            .fontWeight(.bold)
            .foregroundStyle(Color.recordTextPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 12)
    }

    // MARK: - Taste recommendations (Gemini)

    /// 전체 탭이면 음악·독서 다 보여주고, 음악/독서 탭이면 그 카테고리만 남긴다.
    private var filteredTasteCards: [TasteRecommendationCard] {
        guard let selectedCategory else { return tasteEngine.cards }
        return tasteEngine.cards.filter { $0.category == selectedCategory }
    }

    private var tasteHighlightsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("취향 추천")
                    .font(.headline)
                    .foregroundStyle(Color.recordTextPrimary)
                Spacer()
                if !tasteEngine.cards.isEmpty {
                    Button {
                        Task { await tasteEngine.recommend(from: records) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(Color.recordTextSecondary)
                    }
                    .buttonStyle(.borderless)
                    .disabled(tasteEngine.isLoading)
                }
                Button {
                    showTasteRecommendation = true
                } label: {
                    Text("더보기 ›")
                        .font(.caption)
                        .foregroundStyle(Color.recordTextSecondary)
                }
                .buttonStyle(.borderless)
            }

            if tasteEngine.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 96)
            } else if tasteEngine.cards.isEmpty {
                Button {
                    Task { await tasteEngine.recommend(from: records) }
                } label: {
                    Text(tasteEngine.errorMessage ?? "탭해서 취향 추천 받기")
                        .font(.caption)
                        .foregroundStyle(Color.recordTextSecondary)
                        .frame(maxWidth: .infinity, minHeight: 96)
                }
                .buttonStyle(.plain)
            } else if filteredTasteCards.isEmpty {
                Text("이 카테고리엔 추천이 없어요")
                    .font(.caption)
                    .foregroundStyle(Color.recordTextSecondary)
                    .frame(maxWidth: .infinity, minHeight: 96)
            } else {
                // prefix로 딱 잘라내면 화면 폭에 정확히 맞아떨어져 "더 있다"는 느낌이
                // 안 나서, 카드를 다 넣어 다음 카드가 살짝 삐져나오게 둔다.
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filteredTasteCards) { card in
                            TasteRecommendationCardView(card: card)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.recordCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Quick access

    private var revisitCount: Int {
        filteredRecords.filter(\.wantsToRevisit).count
    }

    private var revisitChipTitle: String {
        switch selectedCategory {
        case nil: "다시 보고 싶어요"
        case .music: "다시 듣고 싶어요"
        case .book: "다시 읽고 싶어요"
        }
    }

    /// 사용자가 북마크로 직접 체크한 기록만 센다 — `comment`가 채워졌다고 자동으로 세지 않는다.
    private var scrapCount: Int {
        records.filter(\.isScrapped).count
    }

    private var quickAccessRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    showRevisitRecords = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                        Text("\(revisitChipTitle) \(revisitCount) ›")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.recordRevisitChipText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.recordRevisitChipBackground, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.borderless)

                Button {
                    showSentenceScrap = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bookmark.fill")
                        Text("문장스크랩 \(scrapCount) ›")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.recordNeutralChipText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.recordNeutralChipBackground, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.borderless)
            }
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
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isSelected ? Color.recordFilterActiveBackground : Color.recordFilterInactiveBackground,
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
        .buttonStyle(.borderless)
    }

    // MARK: - Recent records preview

    private var filteredRecords: [Record] {
        records.filter { selectedCategory == nil || $0.category == selectedCategory }
    }

    private var previewRecords: [Record] {
        Array(filteredRecords.prefix(recentRecordsPreviewLimit))
    }

    private var recentRecordsHeader: some View {
        HStack {
            Text("최근 기록")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(Color.recordTextSecondary)
            Spacer()
            Button {
                showAllRecords = true
            } label: {
                Text("전체보기 ›")
                    .font(.caption)
                    .foregroundStyle(Color.recordTextSecondary)
            }
            .buttonStyle(.borderless)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(.recordPreviewContainer)
}
