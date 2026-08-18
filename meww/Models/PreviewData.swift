//
//  PreviewData.swift
//  meww
//
//  Created by yunseo on 8/15/26.
//

import Foundation
import SwiftData

extension ModelContainer {
    /// In-memory container pre-seeded with sample records, for SwiftUI previews only.
    @MainActor
    static var recordPreviewContainer: ModelContainer = {
        let schema = Schema([Record.self, Folder.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])

        let calendar = Calendar.current
        let samples = [
            Record(category: .book, title: "사피엔스", creator: "유발 하라리", rating: 3,
                   comment: "농업혁명 파트가 인상 깊었다.",
                   isScrapped: true,
                   recordedAt: calendar.date(byAdding: .day, value: -3, to: .now)!),
            Record(category: .music, title: "Lover", creator: "Taylor Swift", rating: 4,
                   wantsToRevisit: true,
                   recordedAt: calendar.date(byAdding: .day, value: -6, to: .now)!),
            Record(category: .music, title: "EARFQUAKE", creator: "Tyler the creator", rating: 5,
                   recordedAt: calendar.date(byAdding: .month, value: -1, to: .now)!),
            Record(category: .book, title: "아몬드", creator: "손원평", rating: 4,
                   recordedAt: calendar.date(byAdding: .month, value: -2, to: .now)!),
            Record(category: .music, title: "1989", creator: "Taylor Swift", rating: 5,
                   recordedAt: calendar.date(byAdding: .day, value: -1, to: .now)!),
        ]
        samples.forEach { container.mainContext.insert($0) }

        return container
    }()
}
