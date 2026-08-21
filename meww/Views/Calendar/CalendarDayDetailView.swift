//
//  CalendarDayDetailView.swift
//  meww
//
//  Created by yunseo on 8/19/26.
//

import SwiftUI

/// 캘린더에서 날짜를 탭했을 때 뜨는 바텀시트 — Figma node 143:2의 하단 시트 부분.
/// 그 날 기록한 항목들을 시간순 타임라인으로 보여준다. 항목을 탭하면 홈 화면의
/// `RecordRowView`와 똑같이 `RecordDetailView`가 뜬다.
struct CalendarDayDetailView: View {
    let date: Date
    let records: [Record]

    @State private var selectedRecord: Record?
    @State private var showAddRecord = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            dragHandle
            dateHeader
            addRecordButton

            if !records.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                            timelineRow(record: record, isLast: index == records.count - 1)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 12)
        // 기록이 있을 땐 ScrollView가 시트 높이를 꽉 채워서 콘텐츠가 항상 위에 붙어 보이지만,
        // 기록이 없어서 짧은 콘텐츠만 있을 땐 SwiftUI가 그 짧은 콘텐츠를 시트 안에서 세로
        // 가운데 정렬해버려 위쪽에 큰 여백이 생긴다 — 항상 위쪽에 고정되도록 강제한다.
        .frame(maxHeight: .infinity, alignment: .top)
        .sheet(item: $selectedRecord) { record in
            RecordDetailView(record: record)
                .presentationDetents([.fraction(0.72), .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showAddRecord) {
            NavigationStack {
                AddRecordSearchView(recordedAt: date)
            }
        }
    }

    /// 기록이 있는 날이든 없는 날이든 항상 보인다 — 없는 날엔 첫 기록을, 있는 날엔
    /// "오늘 하나 더" 추가를 위한 진입점.
    private var addRecordButton: some View {
        Button {
            showAddRecord = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                Text("이 날짜로 기록 추가")
            }
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.recordFilterActiveBackground, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var dragHandle: some View {
        Capsule()
            .fill(Color.recordDragHandle)
            .frame(width: 36, height: 4)
            .frame(maxWidth: .infinity)
    }

    private var dateHeader: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Color.recordTextPrimary)
            VStack(alignment: .leading, spacing: 0) {
                Text(date.koreanWeekdayTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.recordTextPrimary)
                Text(date.koreanMonthTitle)
                    .font(.caption)
                    .foregroundStyle(Color.recordTextSecondary)
            }
            .padding(.top, 8)
        }
    }

    private func timelineRow(record: Record, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(record.category == .music ? Color.recordStatMusic : Color.recordStatBook)
                    .frame(width: 8, height: 8)
                if !isLast {
                    Rectangle()
                        .fill(Color.recordSeparator)
                        .frame(width: 1)
                }
            }
            .frame(width: 16)
            .padding(.top, 6)

            Button {
                selectedRecord = record
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.recordPlaceholderArt)
                        .overlay {
                            if let artworkURL = record.artworkURL {
                                AsyncImage(url: artworkURL) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Image(systemName: record.category.systemImage)
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: record.category.systemImage)
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                        }
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.recordTextPrimary)
                            .lineLimit(1)
                        Text(record.creator)
                            .font(.caption2)
                            .foregroundStyle(Color.recordTextSecondary)
                            .lineLimit(1)
                        Text(record.ratingStars)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.recordRatingGold)
                    }

                    Spacer(minLength: 8)

                    Text(record.recordedAtTimeCompact)
                        .font(.caption2)
                        .foregroundStyle(Color.recordTextSecondary)
                }
                .padding(12)
                .background(Color.recordCardBackground, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, isLast ? 0 : 14)
    }
}

#Preview {
    CalendarDayDetailView(
        date: .now,
        records: [
            Record(category: .music, title: "Fearless (Taylor's Version)", creator: "Taylor Swift", rating: 4),
            Record(category: .book, title: "아몬드", creator: "손원평", rating: 4),
            Record(category: .music, title: "Midnights", creator: "Taylor Swift", rating: 3),
        ]
    )
}
