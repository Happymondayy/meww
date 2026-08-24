//
//  ComingSoonView.swift
//  meww
//
//  Created by yunseo on 8/24/26.
//

import SwiftUI

/// "마이" 화면의 하위 메뉴 중 아직 구현되지 않은 항목들의 자리표시자.
struct ComingSoonView: View {
    let title: String

    var body: some View {
        ContentUnavailableView(
            "\(title) 준비 중이에요",
            systemImage: "hammer",
            description: Text("조금만 기다려주세요!")
        )
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ComingSoonView(title: "알림 설정")
    }
}
