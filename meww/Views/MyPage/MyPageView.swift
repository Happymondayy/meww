//
//  MyPageView.swift
//  meww
//
//  Created by yunseo on 8/24/26.
//

import SwiftUI
import SwiftData

/// "👤 마이" — Figma node 166:2. `CalendarView` 헤더의 마이 아이콘에서 들어온다.
///
/// 아바타 없이 텍스트 목록만 있는 Figma 원본과 달리, 로그인 없는 앱이라도 "내 기록"이라는
/// 느낌을 주기 위해 상단에 닉네임 헤더를 하나 얹었다 — 탭하면 바로 수정할 수 있고, "계정 관리"
/// 화면에서도 같은 값을 편집할 수 있다(둘 다 `@AppStorage("userNickname")`을 그대로 공유).
///
/// "기록" 섹션의 문장 스크랩/다시 보고 싶은 기록은 기존 화면을 그대로 재사용한다. "취향 분석"과
/// "설정" 섹션 항목들은 아직 실제 기능이 없어 `ComingSoonView`로 자리만 잡아뒀다.
struct MyPageView: View {
    /// 홈 화면 인사말(`.title` 굵은 글씨)에 그대로 붙기 때문에, 너무 길면 줄바꿈이 여러 번
    /// 일어나 레이아웃이 밀린다 — 입력 단계에서 미리 막는다.
    private let nicknameMaxLength = 5

    @AppStorage("userNickname") private var nickname = ""

    @State private var showNicknameAlert = false
    @State private var editedNickname = ""

    var body: some View {
        List {
            nicknameHeader
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            Section {
                menuCard {
                    NavigationLink {
                        SentenceScrapView()
                    } label: {
                        menuRow(icon: "📑", title: "문장 스크랩")
                    }
                    menuDivider
                    NavigationLink {
                        RevisitRecordsView()
                    } label: {
                        menuRow(icon: "❤️", title: "다시 보고 싶은 기록")
                    }
                    menuDivider
                    NavigationLink {
                        ComingSoonView(title: "취향 분석")
                    } label: {
                        menuRow(icon: "📊", title: "취향 분석")
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } header: {
                sectionHeader("기록")
            }

            Section {
                menuCard {
                    NavigationLink {
                        ComingSoonView(title: "알림 설정")
                    } label: {
                        menuRow(icon: "🔔", title: "알림 설정")
                    }
                    menuDivider
                    NavigationLink {
                        AccountManagementView()
                    } label: {
                        menuRow(icon: "👤", title: "계정 관리")
                    }
                    menuDivider
                    NavigationLink {
                        ComingSoonView(title: "API 연동 관리")
                    } label: {
                        menuRow(icon: "🔗", title: "API 연동 관리")
                    }
                    menuDivider
                    NavigationLink {
                        ComingSoonView(title: "데이터 내보내기")
                    } label: {
                        menuRow(icon: "📤", title: "데이터 내보내기")
                    }
                    menuDivider
                    NavigationLink {
                        ComingSoonView(title: "앱 정보")
                    } label: {
                        menuRow(icon: "ℹ️", title: "앱 정보")
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } header: {
                sectionHeader("설정")
            }
        }
        .listStyle(.plain)
        .contentMargins(.horizontal, .recordSpacingXL, for: .scrollContent)
        .navigationTitle("마이")
        .navigationBarTitleDisplayMode(.inline)
        .alert("닉네임 설정", isPresented: $showNicknameAlert) {
            TextField("닉네임 (최대 \(nicknameMaxLength)자)", text: $editedNickname)
                .onChange(of: editedNickname) {
                    editedNickname = String(editedNickname.prefix(nicknameMaxLength))
                }
            Button("취소", role: .cancel) {}
            Button("저장") {
                nickname = editedNickname.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }

    // MARK: - Nickname header

    private var nicknameHeader: some View {
        Button {
            editedNickname = nickname
            showNicknameAlert = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(nickname.isEmpty ? "닉네임을 설정해주세요" : "\(nickname)님")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.recordTextPrimary)
                    Text(nickname.isEmpty ? "탭해서 닉네임을 등록하세요" : "탭해서 닉네임 수정")
                        .font(.caption)
                        .foregroundStyle(Color.recordTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.recordTextSecondary)
            }
            .padding(.vertical, .recordSpacingM)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Menu rows

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(Color.recordTextSecondary)
    }

    /// 홈 화면 카드(`Color.recordCardBackground` + `.recordRadiusL`)와 같은 톤으로 메뉴 항목들을
    /// 하나의 그룹으로 묶는다 — 시스템 기본 `.insetGrouped`의 회색 배경/흰 박스 대신 앱 전체가
    /// 쓰는 카드 스타일에 맞춘다.
    private func menuCard(@ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.horizontal, .recordSpacingL)
        .background(Color.recordCardBackground, in: RoundedRectangle(cornerRadius: .recordRadiusL))
    }

    private var menuDivider: some View {
        Rectangle()
            .fill(Color.recordSeparator)
            .frame(height: 1)
    }

    private func menuRow(icon: String, title: String) -> some View {
        HStack(spacing: .recordSpacingM) {
            Text(icon)
                .font(.footnote)
                .frame(width: 28, height: 28)
                .background(Color.white, in: RoundedRectangle(cornerRadius: .recordRadiusS))
            Text(title)
                .foregroundStyle(Color.recordTextPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.recordTextSecondary)
        }
        .padding(.vertical, .recordSpacingM)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        MyPageView()
    }
    .modelContainer(.recordPreviewContainer)
}
