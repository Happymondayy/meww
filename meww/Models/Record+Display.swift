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

    /// e.g. "9:15 AM" — 캘린더 날짜 상세(📅 캘린더) 타임라인용.
    var recordedAtTimeCompact: String {
        Self.timeFormatter.string(from: recordedAt)
    }

    private static let recordedAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    // 나머지 UI는 전부 한글(ko_KR)인데, 캘린더 타임라인 시간만 Figma 목업처럼 "9:15 AM" 영문
    // 표기를 쓴다 — DateFormatter의 "a" 심볼이 ko_KR에서는 "오전/오후"를 내놓기 때문에
    // en_US_POSIX로 고정한다.
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
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
