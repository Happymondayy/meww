//
//  ContentView.swift
//  meww
//
//  Created by yunseo on 8/15/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("홈", systemImage: "house.fill") {
                NavigationStack {
                    HomeView()
                }
            }

            Tab("기록 추가", systemImage: "plus.circle.fill") {
                NavigationStack {
                    AddRecordSearchView()
                }
            }

            Tab("캘린더", systemImage: "calendar") {
                CalendarView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(.recordPreviewContainer)
}
