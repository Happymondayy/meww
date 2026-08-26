//
//  Record+Display.swift
//  meww
//
//  Created by yunseo on 8/15/26.
//

import Foundation

extension Record {
    /// e.g. "★★★☆☆" for rating == 3
    var ratingStars: String {
        let filled = max(0, min(5, rating))
        return String(repeating: "★", count: filled) + String(repeating: "☆", count: 5 - filled)
    }

    /// e.g. "2026.05.03"
    var recordedAtCompact: String {
        Self.recordedAtFormatter.string(from: recordedAt)
    }

    /// e.g. "2026.05.03에 기록함" — 상세보기(📱 상세보기) 화면용.
    var recordedAtDisplay: String {
        recordedAtCompact + "에 기록함"
    }

    /// e.g. "21:05" — 캘린더 날짜 상세(📅 캘린더) 타임라인용. 24시간제.
    var recordedAtTimeCompact: String {
        Self.timeFormatter.string(from: recordedAt)
    }

    /// e.g. "2026.05.03"
    var startedAtCompact: String? {
        startedAt.map { Self.recordedAtFormatter.string(from: $0) }
    }

    /// e.g. "2026.04.28 ~ 2026.05.03 · 6일간 읽음" — 독서 기록 상세보기용.
    /// `startedAt`이 없으면(음악, 또는 시작일을 안 남긴 독서 기록) nil.
    var readingPeriodDisplay: String? {
        guard category == .book, let startedAt else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startedAt)
        let end = calendar.startOfDay(for: recordedAt)
        let days = max(1, (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1)
        let startText = Self.recordedAtFormatter.string(from: startedAt)
        return "\(startText) ~ \(recordedAtCompact) · \(days)일간 읽음"
    }

    private static let recordedAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

extension Array where Element == Record {
    /// Groups records by calendar month, most recent month first; records within a month sorted most recent first.
    func groupedByMonth() -> [(month: Date, records: [Record])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: self) { record in
            calendar.dateInterval(of: .month, for: record.recordedAt)?.start ?? record.recordedAt
        }
        return grouped
            .map { (month: $0.key, records: $0.value.sorted { $0.recordedAt > $1.recordedAt }) }
            .sorted { $0.month > $1.month }
    }

    /// 오늘 기준으로 거꾸로 세는 연속 기록 일수. 오늘 아직 기록이 없으면 어제부터 센다 —
    /// 자정 넘기기 전까진 스트릭이 끊긴 것처럼 보이면 안 되기 때문이다.
    func currentStreak(asOf today: Date = .now, calendar: Calendar = .current) -> Int {
        let recordedDays = Set(map { calendar.startOfDay(for: $0.recordedAt) })
        var day = calendar.startOfDay(for: today)
        if !recordedDays.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var streak = 0
        while recordedDays.contains(day) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        return streak
    }

    /// 지금까지 가장 길게 이어졌던 연속 기록 일수.
    func longestStreak(calendar: Calendar = .current) -> Int {
        let recordedDays = Set(map { calendar.startOfDay(for: $0.recordedAt) }).sorted()
        guard !recordedDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        for index in 1..<recordedDays.count {
            let isConsecutive = calendar.date(byAdding: .day, value: 1, to: recordedDays[index - 1]) == recordedDays[index]
            current = isConsecutive ? current + 1 : 1
            longest = Swift.max(longest, current)
        }
        return longest
    }
}

extension Date {
    var koreanMonthTitle: String {
        Self.monthFormatter.string(from: self)
    }

    /// e.g. "화요일" — 캘린더 날짜 상세(📅 캘린더) 헤더용.
    var koreanWeekdayTitle: String {
        Self.weekdayFormatter.string(from: self)
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}
