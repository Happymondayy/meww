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
/// 찍어 한눈에 훑을 수 있게 한다. Figma엔 없지만 여러 달을 오갈 방법이 필요해서 월 제목을
/// 탭하면 연/월 피커가 뜨고, 옆에 이전/다음 버튼도 뒀다. Figma의 "마이" 버튼(node 166:2)은
/// 이전/다음 버튼 옆에 그대로 뒀다 — 탭 바에는 넣지 않기로 했다.
struct CalendarView: View {
    @Query private var records: [Record]

    @State private var displayedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    /// 그리드에서 검게 강조되는 날짜 — 처음엔 오늘이 기본으로 강조돼 있다. 날짜를 탭하면
    /// 그 날로 옮겨가면서 동시에 상세 시트(`presentedDay`)도 뜬다.
    @State private var highlightedDate = Calendar.current.startOfDay(for: .now)
    @State private var presentedDay: SelectedDay?
    @State private var showMonthPicker = false
    @State private var showMyPage = false

    private let calendar = Calendar.current
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(alignment: .leading, spacing: .recordSpacingXL) {
            header
            weeklyStreakSection
            categoryCountRow
            VStack(alignment: .leading, spacing: 4) {
                weekdayHeader
                calendarGrid
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, .recordSpacingXL)
        .padding(.top, .recordSpacingS)
        .sheet(item: $presentedDay) { day in
            CalendarDayDetailView(date: day.date, records: recordsForDay(day.date))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showMonthPicker) {
            MonthYearPickerView(selection: $displayedMonth)
                .presentationDetents([.height(280)])
        }
        .navigationDestination(isPresented: $showMyPage) {
            MyPageView()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                showMonthPicker = true
            } label: {
                HStack(spacing: 4) {
                    Text(displayedMonth.koreanMonthTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.recordTextPrimary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.recordTextSecondary)
                }
            }
            .buttonStyle(.plain)

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
            .background(Color.recordFilterInactiveBackground, in: RoundedRectangle(cornerRadius: .recordRadiusM))

            Button {
                showMyPage = true
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.title2)
                    .foregroundStyle(Color.recordTextPrimary)
            }
            .buttonStyle(.plain)
            .padding(.leading, .recordSpacingXS)
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
        .padding(.horizontal, .recordSpacingS)
        .padding(.vertical, .recordSpacingS)
        .background(background, in: RoundedRectangle(cornerRadius: .recordRadiusM))
    }

    // MARK: - Weekly streak (듀오링고 스타일 — 실제 오늘 기준 이번 주, `displayedMonth`와 무관하다)

    private var currentWeekDates: [Date] {
        let today = calendar.startOfDay(for: .now)
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
    }

    private func hasRecord(on date: Date) -> Bool {
        records.contains { calendar.isDate($0.recordedAt, inSameDayAs: date) }
    }

    private var weeklyStreakSection: some View {
        VStack(alignment: .leading, spacing: .recordSpacingL) {
            HStack(spacing: 8) {
                ForEach(currentWeekDates, id: \.self) { date in
                    weeklyStreakDay(date)
                }
            }

            streakCard
        }
    }

    private func weeklyStreakDay(_ date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let done = hasRecord(on: date)
        let weekdayIndex = calendar.component(.weekday, from: date) - 1

        return VStack(spacing: 4) {
            Text(weekdaySymbols[weekdayIndex])
                .font(.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? Color.recordTextPrimary : Color.recordTextSecondary)

            ZStack {
                Circle()
                    .fill(done ? Color.recordAccentPink : Color.recordFilterInactiveBackground)
                    .frame(width: 28, height: 28)

                // 오늘인데 아직 기록이 없으면 불꽃 아이콘으로 "지금 하면 스트릭 이어짐"을 알려준다.
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                } else if isToday {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.recordAccentPink)
                }
            }
            .overlay {
                if isToday {
                    Circle().stroke(done ? .white : Color.recordAccentPink, lineWidth: 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// 연속 기록 일수 카드 — 오늘 기록이 없으면 "지금 시작해보세요" 쪽으로 문구가 바뀐다.
    private var streakCard: some View {
        let current = records.currentStreak()
        let longest = records.longestStreak()

        return HStack(spacing: .recordSpacingM) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(current > 0 ? Color.recordAccentPink : Color.recordTextSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(current > 0 ? "\(current)일 연속 기록 중이에요" : "오늘부터 기록을 시작해보세요")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.recordTextPrimary)
                Text("최고 기록 \(longest)일")
                    .font(.caption)
                    .foregroundStyle(Color.recordTextSecondary)
            }

            Spacer()
        }
        .padding(.recordSpacingL)
        .background(Color.recordCardBackground, in: RoundedRectangle(cornerRadius: .recordRadiusL))
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
            let isSelected = calendar.isDate(highlightedDate, inSameDayAs: date)

            Button {
                highlightedDate = date
                presentedDay = SelectedDay(date: date)
            } label: {
                VStack(spacing: 3) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? .white : Color.recordTextPrimary)
                    dotsRow(for: dayRecords, isSelected: isSelected)
                }
                .frame(width: 50, height: 42)
                // 원형 선택 표시 전용, 카드 반경 스케일과 무관
                .background(isSelected ? Color.recordTextPrimary : .clear, in: RoundedRectangle(cornerRadius: 21))
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

/// 월 제목을 탭하면 뜨는 연/월 피커 — 이전/다음 버튼으로 한 달씩만 옮기는 대신 멀리 있는
/// 달로 바로 이동할 방법이 필요해서 추가했다.
private struct MonthYearPickerView: View {
    @Binding var selection: Date
    @Environment(\.dismiss) private var dismiss

    @State private var year: Int
    @State private var month: Int

    private let years: [Int]

    init(selection: Binding<Date>) {
        _selection = selection
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selection.wrappedValue)
        _year = State(initialValue: components.year ?? calendar.component(.year, from: .now))
        _month = State(initialValue: components.month ?? calendar.component(.month, from: .now))

        let currentYear = calendar.component(.year, from: .now)
        years = Array((currentYear - 5)...(currentYear + 5))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("월 선택")
                    .font(.headline)
                    .foregroundStyle(Color.recordTextPrimary)
                Spacer()
                Button("완료") {
                    apply()
                    dismiss()
                }
                .fontWeight(.semibold)
            }
            .padding(.horizontal, .recordSpacingXL)
            .padding(.top, .recordSpacingL)
            .padding(.bottom, .recordSpacingXS)

            HStack(spacing: 0) {
                Picker("연도", selection: $year) {
                    ForEach(years, id: \.self) { year in
                        Text(String(year) + "년").tag(year)
                    }
                }
                .pickerStyle(.wheel)

                Picker("월", selection: $month) {
                    ForEach(1...12, id: \.self) { month in
                        Text("\(month)월").tag(month)
                    }
                }
                .pickerStyle(.wheel)
            }
        }
    }

    private func apply() {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        if let newDate = Calendar.current.date(from: components) {
            selection = newDate
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(.recordPreviewContainer)
}
