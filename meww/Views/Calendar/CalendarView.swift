//
//  CalendarView.swift
//  meww
//
//  Created by yunseo on 8/19/26.
//

import SwiftUI
import SwiftData

/// "📅 캘린더" — Figma node 139:2(기본 뷰) / 143:2(날짜 탭 → 하단 시트).
///
/// 월별 리스트(HomeView)만으로는 날짜 경계가 안 보여서 기록이 실제보다 많아 보인다는 피드백이
/// 있었다 — 이 화면은 요일별 그리드로 날짜 경계를 보여주고, 기록이 있는 날엔 카테고리별 점을
/// 찍어 한눈에 훑을 수 있게 한다. Figma엔 없지만 여러 달을 오갈 방법이 필요해서 월 제목 옆에
/// 이전/다음 버튼을 추가했다 — Figma의 "마이" 버튼은 아직 프로필 화면이 없어 뺐다.
struct CalendarView: View {
    @Query private var records: [Record]

    @State private var displayedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var selectedDay: SelectedDay?

    private let calendar = Calendar.current
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            categoryCountRow
            VStack(alignment: .leading, spacing: 4) {
                weekdayHeader
                calendarGrid
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .sheet(item: $selectedDay) { day in
            CalendarDayDetailView(date: day.date, records: recordsForDay(day.date))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(24)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(displayedMonth.koreanMonthTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.recordTextPrimary)
            Spacer()
            HStack(spacing: 4) {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 28, height: 28)
                }
                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 28, height: 28)
                }
            }
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(Color.recordTextPrimary)
            .buttonStyle(.plain)
            .background(Color.recordFilterInactiveBackground, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        displayedMonth = newMonth
    }

    // MARK: - Category count row

    private var recordsInDisplayedMonth: [Record] {
        records.filter { calendar.isDate($0.recordedAt, equalTo: displayedMonth, toGranularity: .month) }
    }

    private var categoryCountRow: some View {
        HStack(spacing: 8) {
            countPill(
                icon: RecordCategory.music.systemImage,
                text: "음악 \(recordsInDisplayedMonth.filter { $0.category == .music }.count)",
                background: .recordCalendarMusicBackground,
                text2: .recordCalendarMusicText
            )
            countPill(
                icon: RecordCategory.book.systemImage,
                text: "독서 \(recordsInDisplayedMonth.filter { $0.category == .book }.count)",
                background: .recordRevisitChipBackground,
                text2: .recordRevisitChipText
            )
        }
    }

    // 이모지(🎵/📖) 대신 SF Symbol을 쓴다 — 시뮬레이터/기기별로 컬러 이모지 폰트가 없으면
    // 빈 네모(tofu)로 보일 수 있어서, 앱 다른 곳(category.systemImage)과 똑같이 SF Symbol로 통일했다.
    private func countPill(icon: String, text: String, background: Color, text2: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(text2)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(background, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Weekday header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .frame(maxWidth: .infinity)
                    .font(.footnote)
                    .foregroundStyle(Color.recordTextSecondary)
            }
        }
    }

    // MARK: - Month grid

    /// 이번 달 1일 전 빈 칸 + 이번 달 날짜 + 마지막 주를 7칸으로 채우는 빈 칸.
    private var monthDates: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30

        var dates: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in 1...daysInMonth {
            dates.append(calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start))
        }
        while dates.count % 7 != 0 {
            dates.append(nil)
        }
        return dates
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
            ForEach(Array(monthDates.enumerated()), id: \.offset) { _, date in
                dayCell(date)
            }
        }
    }

    private func recordsForDay(_ date: Date) -> [Record] {
        records
            .filter { calendar.isDate($0.recordedAt, inSameDayAs: date) }
            .sorted { $0.recordedAt < $1.recordedAt }
    }

    @ViewBuilder
    private func dayCell(_ date: Date?) -> some View {
        if let date {
            let dayRecords = recordsForDay(date)
            let isSelected = selectedDay.map { calendar.isDate($0.date, inSameDayAs: date) } ?? false

            Button {
                selectedDay = SelectedDay(date: date)
            } label: {
                VStack(spacing: 3) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? .white : Color.recordTextPrimary)
                    dotsRow(for: dayRecords, isSelected: isSelected)
                }
                .frame(width: 50, height: 42)
                .background(isSelected ? Color.recordTextPrimary : .clear, in: Circle())
            }
            .buttonStyle(.plain)
        } else {
            Color.clear.frame(width: 50, height: 42)
        }
    }

    /// 그 날 기록된 카테고리마다 작은 점 하나 — 음악은 초록, 독서는 자홍. 선택된 날은 배경이
    /// 어두워서 점도 흰색으로 바꿔 대비를 준다.
    @ViewBuilder
    private func dotsRow(for dayRecords: [Record], isSelected: Bool) -> some View {
        let hasMusic = dayRecords.contains { $0.category == .music }
        let hasBook = dayRecords.contains { $0.category == .book }

        if hasMusic || hasBook {
            HStack(spacing: 3) {
                if hasMusic {
                    Circle().fill(isSelected ? Color.white : Color.recordStatMusic).frame(width: 5, height: 5)
                }
                if hasBook {
                    Circle().fill(isSelected ? Color.white : Color.recordStatBook).frame(width: 5, height: 5)
                }
            }
        } else {
            Color.clear.frame(width: 5, height: 5)
        }
    }
}

private struct SelectedDay: Identifiable {
    let date: Date
    var id: Date { date }
}

#Preview {
    CalendarView()
        .modelContainer(.recordPreviewContainer)
}
