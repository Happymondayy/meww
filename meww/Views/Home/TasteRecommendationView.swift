//
//  TasteRecommendationView.swift
//  meww
//
//  Created by yunseo on 8/15/26.
//

import SwiftUI
import SwiftData

/// "✨ 취향 추천 (전체보기)" — Figma node 165:2. Pushed from HomeView's "더보기".
///
/// The Figma mockup groups cards by genre/similarity ("에세이 장르 즐겨 읽음", "Fearless와 비슷"),
/// which needs data `Record` doesn't have (no genre field, no recommendation engine). Instead,
/// groups are built from real repetition in the data: creators the user has rated ≥4 more than
/// once become a "◯◯ 선호" section; everything else lands in a catch-all highlight section.
struct TasteRecommendationView: View {
    @Query(sort: \Record.recordedAt, order: .reverse) private var records: [Record]
    @ObservedObject var engine: TasteRecommendationEngine

    @State private var selectedCategory: RecordCategory?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !filteredAICards.isEmpty {
                    aiRecommendationSection
                }

                Text("취향 분석 데이터를 바탕으로 \(highlightRecords.count)개를 골랐어요")
                    .font(.footnote)
                    .foregroundStyle(Color.recordTextSecondary)

                statCard

                filterRow

                if creatorGroups.isEmpty && otherHighlights.isEmpty {
                    ContentUnavailableView(
                        "아직 취향 데이터가 부족해요",
                        systemImage: "sparkles",
                        description: Text("별점 4점 이상인 기록이 쌓이면 취향 추천이 만들어져요.")
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(creatorGroups, id: \.creator) { group in
                        highlightGroup(title: "\(group.creator) 선호", records: group.records)
                    }

                    if !otherHighlights.isEmpty {
                        highlightGroup(title: "그 외 취향 하이라이트", records: otherHighlights)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("취향 추천")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - AI 추천 (Gemini)

    /// 전체 탭이면 음악·독서 다 보여주고, 음악/독서 탭이면 그 카테고리만 남긴다 —
    /// `filterRow`가 아래 취향 하이라이트뿐 아니라 이 섹션에도 함께 적용된다.
    private var filteredAICards: [TasteRecommendationCard] {
        guard let selectedCategory else { return engine.cards }
        return engine.cards.filter { $0.category == selectedCategory }
    }

    private var aiRecommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("취향 추천")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.recordTextPrimary)
                Spacer()
                Button {
                    Task { await engine.recommend(from: records) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(Color.recordTextSecondary)
                }
                .buttonStyle(.borderless)
                .disabled(engine.isLoading)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(filteredAICards) { card in
                        TasteRecommendationCardView(card: card, showsReason: true)
                            .frame(width: 120)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.recordCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stat card

    private var averageRating: Double {
        guard !records.isEmpty else { return 0 }
        let total = records.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(records.count)
    }

    private var statCard: some View {
        HStack(spacing: 0) {
            statColumn(value: "\(records.count)", label: "총 기록", color: .recordTextPrimary)
            statColumn(value: "\(records.filter { $0.category == .music }.count)", label: "음악", color: .recordStatMusic)
            statColumn(value: "\(records.filter { $0.category == .book }.count)", label: "독서", color: .recordStatBook)
            statColumn(value: String(format: "%.1f", averageRating), label: "평균 별점", color: .recordRatingGold)
        }
        .padding(.vertical, 18)
        .background(Color.recordCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statColumn(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.recordTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Category filter

    private var filterRow: some View {
        HStack(spacing: 8) {
            filterChip(title: "전체", isSelected: selectedCategory == nil) {
                selectedCategory = nil
            }
            ForEach(RecordCategory.allCases) { category in
                filterChip(title: category.rawValue, isSelected: selectedCategory == category) {
                    selectedCategory = category
                }
            }
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(isSelected ? .white : Color.recordFilterInactiveText)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected ? Color.recordFilterActiveBackground : Color.recordFilterInactiveBackground,
                    in: RoundedRectangle(cornerRadius: 16)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Highlight groups

    private var highlightRecords: [Record] {
        records
            .filter { $0.rating >= 4 }
            .filter { selectedCategory == nil || $0.category == selectedCategory }
    }

    private var creatorGroups: [(creator: String, records: [Record])] {
        Dictionary(grouping: highlightRecords, by: \.creator)
            .filter { $0.value.count >= 2 }
            .map { creator, records in
                (creator: creator, records: records.sorted {
                    $0.rating != $1.rating ? $0.rating > $1.rating : $0.recordedAt > $1.recordedAt
                })
            }
            .sorted {
                $0.records.count != $1.records.count
                    ? $0.records.count > $1.records.count
                    : $0.creator < $1.creator
            }
    }

    private var otherHighlights: [Record] {
        let groupedCreators = Set(creatorGroups.map(\.creator))
        return highlightRecords
            .filter { !groupedCreators.contains($0.creator) }
            .sorted { $0.rating != $1.rating ? $0.rating > $1.rating : $0.recordedAt > $1.recordedAt }
    }

    private func highlightGroup(title: String, records: [Record]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.recordTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(records) { record in
                        TasteHighlightCardView(record: record)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.recordCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        TasteRecommendationView(engine: TasteRecommendationEngine())
    }
    .modelContainer(.recordPreviewContainer)
}
