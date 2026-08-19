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
/// 상단 통계·필터는 `TasteProfile`이 이미 계산해둔 값을 그대로 쓰고, 아래 섹션들은
/// `TasteProfile.favoriteCreators`(평점 4점 이상을 준 아티스트/저자)를 하나씩 순회하며
/// Gemini에게 "이 아티스트/저자와 비슷한 새로운 추천"을 요청해 만든다 — 사용자가 이미
/// 기록한 항목이 아니라 아직 안 접해본 새로운 카드들이다.
struct TasteRecommendationView: View {
    @Query(sort: \Record.recordedAt, order: .reverse) private var records: [Record]
    @StateObject private var creatorEngine = CreatorTasteRecommendationEngine()

    @State private var selectedCategory: RecordCategory?

    private var profile: TasteProfile { records.tasteProfile() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statCard
                filterRow
                content
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("취향 추천")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await creatorEngine.loadSections(from: profile)
        }
    }

    // MARK: - Stat card (TasteProfile 값 그대로)

    private var statCard: some View {
        HStack(spacing: 0) {
            statColumn(value: "\(profile.totalCount)", label: "총 기록", color: .recordTextPrimary)
            statColumn(value: "\(profile.musicCount)", label: "음악", color: .recordStatMusic)
            statColumn(value: "\(profile.bookCount)", label: "독서", color: .recordStatBook)
            statColumn(value: String(format: "%.1f", profile.averageRating), label: "평균 별점", color: .recordRatingGold)
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

    // MARK: - 아티스트/저자별 섹션

    /// 전체 탭이면 다 보여주고, 음악/독서 탭이면 그 카테고리 섹션만 남긴다.
    private var filteredSections: [CreatorRecommendationSection] {
        guard let selectedCategory else { return creatorEngine.sections }
        return creatorEngine.sections.filter { $0.category == selectedCategory }
    }

    @ViewBuilder
    private var content: some View {
        if profile.favoriteCreators.isEmpty {
            ContentUnavailableView(
                "아직 취향 데이터가 부족해요",
                systemImage: "sparkles",
                description: Text("별점 4점 이상인 기록이 쌓이면 아티스트/저자별 추천이 만들어져요.")
            )
            .padding(.top, 40)
        } else if creatorEngine.isLoading && creatorEngine.sections.isEmpty {
            loadingSkeleton
        } else if filteredSections.isEmpty {
            Text(creatorEngine.errorMessage ?? "이 카테고리엔 아직 추천이 없어요")
                .font(.footnote)
                .foregroundStyle(Color.recordTextSecondary)
                .frame(maxWidth: .infinity, minHeight: 96)
        } else {
            ForEach(filteredSections) { section in
                sectionView(section)
            }

            if creatorEngine.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
        }
    }

    private func sectionView(_ section: CreatorRecommendationSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.recordTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(section.cards) { card in
                        TasteRecommendationCardView(card: card, showsReason: true)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.recordCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Loading skeleton

    private var loadingSkeleton: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(0..<2, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.recordPlaceholderArt.opacity(0.4))
                        .frame(width: 140, height: 16)

                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            VStack(alignment: .leading, spacing: 4) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.recordPlaceholderArt.opacity(0.4))
                                    .frame(width: 96, height: 96)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.recordPlaceholderArt.opacity(0.3))
                                    .frame(width: 70, height: 10)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.recordCardBackground, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .redacted(reason: .placeholder)
    }
}

#Preview {
    NavigationStack {
        TasteRecommendationView()
    }
    .modelContainer(.recordPreviewContainer)
}
