//
//  AccountManagementView.swift
//  meww
//
//  Created by yunseo on 8/24/26.
//

import SwiftUI

/// "👤 계정 관리" — Figma node 166:43. 로그인/계정 시스템이 아직 없어서, 로컬에만 저장되는
/// 닉네임 하나만 관리한다. `MyPageView` 상단 헤더에서도 같은 값을 탭해서 바로 고칠 수 있다 —
/// 여기는 정식으로 들어가서 고치는 경로.
struct AccountManagementView: View {
    /// `MyPageView`의 닉네임 헤더와 같은 제한을 쓴다 — 홈 화면 인사말에 그대로 붙기 때문에
    /// 여기서도 똑같이 막아야 한다.
    private let nicknameMaxLength = 5

    @AppStorage("userNickname") private var nickname = ""

    var body: some View {
        Form {
            Section("닉네임") {
                TextField("닉네임을 입력하세요 (최대 \(nicknameMaxLength)자)", text: $nickname)
                    .onChange(of: nickname) {
                        nickname = String(nickname.prefix(nicknameMaxLength))
                    }
            }
        }
        .navigationTitle("계정 관리")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AccountManagementView()
    }
}
