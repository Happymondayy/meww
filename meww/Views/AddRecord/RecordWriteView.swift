//
//  RecordWriteView.swift
//  meww
//
//  Created by yunseo on 8/15/26.
//

import SwiftUI
import SwiftData

/// "📝 기록 작성" — Figma node 26:30. Reached after picking a real Apple Music search
/// result (or entering a book title) on `AddRecordSearchView`. Saves a real `Record`.
struct RecordWriteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let category: RecordCategory
    let artworkURL: URL?
    /// 기본은 오늘이지만, 캘린더에서 특정 날짜로 들어왔다면 그 날짜로 기록을 남긴다.
    let recordedAt: Date

    @State private var title: String
    @State private var creator: String
    @State private var isEditingItem: Bool
    @State private var rating = 0
    @State private var wantsToRevisit: Bool?
    @State private var comment = ""
    @State private var isScrapped = false
    @State private var summary = ""
    @State private var recommendedFor = ""
    @State private var didSave = false

    init(category: RecordCategory, title: String, creator: String, artworkURL: URL?, recordedAt: Date = .now) {
        self.category = category
        self.artworkURL = artworkURL
        self.recordedAt = recordedAt
        _title = State(initialValue: title)
        _creator = State(initialValue: creator)
        _isEditingItem = State(initialValue: title.isEmpty)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !creator.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                itemHeader
                ratingSection
                revisitSection
                commentSection
                if category == .book {
                    summarySection
                    recommendedForSection
                }
            }
            .padding(.horizontal, .recordSpacingXL)
            .padding(.top, .recordSpacingM)
            .padding(.bottom, .recordSpacingM)
        }
        .safeAreaInset(edge: .bottom) { saveButton }
        .navigationTitle("기록 작성")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Item header

    private var itemHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: .recordRadiusXS)
                .fill(Color.recordPlaceholderArt)
                .frame(width: 48, height: 48)
                .overlay {
                    if let artworkURL {
                        AsyncImage(url: artworkURL) { image in
                            image.resizable().scaledToFill()
                                .frame(width: 48, height: 48)
                        } placeholder: {
                            Color.clear
                                .frame(width: 48, height: 48)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: .recordRadiusXS))
                    } else {
                        Image(systemName: category.systemImage)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }

            if isEditingItem {
                VStack(alignment: .leading, spacing: 6) {
                    TextField(category == .music ? "곡명" : "책 제목", text: $title)
                        .font(.headline)
                    TextField(category.creatorLabel, text: $creator)
                        .font(.subheadline)
                        .foregroundStyle(Color.recordTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.recordTextPrimary)
                        .lineLimit(2)
                    Text(creator)
                        .font(.subheadline)
                        .foregroundStyle(Color.recordTextSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                // 저장은 하단 "저장하기"로 한 번에 이뤄지므로, 편집 상태로 되돌아갈 필요가
                // 없다 — 탭하면 바로 편집 모드로 들어가고 그대로 유지된다.
                Text("편집")
                    .font(.caption)
                    .foregroundStyle(Color.recordAccentPink)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isEditingItem = true
        }
    }

    // MARK: - Rating

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("별점")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.recordTextPrimary)

            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundStyle(star <= rating ? Color.recordRatingGold : Color(.systemGray4))
                        .onTapGesture { rating = star }
                }
            }
            .font(.title2)
        }
    }

    // MARK: - Revisit

    private var revisitSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category == .music ? "다시 듣고 싶나요?" : "다시 읽고 싶나요?")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.recordTextPrimary)

            HStack(spacing: 8) {
                revisitOption(title: category == .music ? "다시 듣고 싶어요" : "다시 읽고 싶어요", value: true)
                revisitOption(title: "한 번이면 충분해요", value: false)
            }
        }
    }

    private func revisitOption(title: String, value: Bool) -> some View {
        let isSelected = wantsToRevisit == value
        // "다시 듣고 싶어요"(value == true)는 홈 화면의 같은 이름 칩과 배경/글자색을 맞춘다.
        let selectedBackground = value ? Color.recordRevisitChipBackground : Color.recordFilterActiveBackground
        let selectedText = value ? Color.recordRevisitChipText : .white

        return Button {
            wantsToRevisit = value
        } label: {
            Text(title)
                .font(.footnote)
                .foregroundStyle(isSelected ? selectedText : Color.recordFilterInactiveText)
                .padding(.horizontal, .recordSpacingM)
                .padding(.vertical, .recordSpacingS)
                .background(
                    isSelected ? selectedBackground : Color.recordFilterInactiveBackground,
                    in: RoundedRectangle(cornerRadius: .recordRadiusL)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Comment / book-only fields

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(category == .music ? "가장 인상 깊은 가사나 순간은?" : "가장 인상 깊었던 문장은?")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.recordTextPrimary)

                Spacer()

                // 체크하면 이 문장이 "문장 스크랩" 화면에 모인다 — comment가 채워졌다고
                // 자동으로 스크랩되지 않는다.
                Button {
                    isScrapped.toggle()
                } label: {
                    Image(systemName: isScrapped ? "bookmark.fill" : "bookmark")
                        .font(.body)
                        .foregroundStyle(isScrapped ? Color.recordScrapBadgeText : Color.recordTextSecondary)
                        .padding(.recordSpacingS)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            TextField(
                category == .music ? "예: 십대 시절 감성이 그대로 되살아남" : "예: 우리는 모두 누군가의 이방인이다",
                text: $comment,
                axis: .vertical
            )
            .font(.subheadline)
            .lineLimit(3...6)
            .padding(.recordSpacingM)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: .recordRadiusS))
        }
    }

    private var summarySection: some View {
        labeledField(
            label: "한 문장으로 요약한다면?",
            placeholder: "예: 공감이란 무엇인지 다시 생각하게 하는 이야기",
            text: $summary
        )
    }

    private var recommendedForSection: some View {
        labeledField(
            label: "누구에게 추천하고 싶나요?",
            placeholder: "예: 감정 표현이 서툰 사람에게",
            text: $recommendedFor
        )
    }

    private func labeledField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.recordTextPrimary)

            TextField(placeholder, text: text, axis: .vertical)
                .font(.subheadline)
                .lineLimit(3...6)
                .padding(.recordSpacingM)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: .recordRadiusS))
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text(didSave ? "저장했어요" : "저장하기")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .recordSpacingM)
                .background(Color.recordFilterActiveBackground, in: RoundedRectangle(cornerRadius: .recordRadiusS))
        }
        .buttonStyle(.plain)
        .disabled(!isValid)
        .padding(.horizontal, .recordSpacingXL)
        .padding(.top, .recordSpacingM)
        .padding(.bottom, .recordSpacingXL)
        .background(.bar)
    }

    private func save() {
        let record = Record(
            category: category,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            creator: creator.trimmingCharacters(in: .whitespacesAndNewlines),
            rating: rating,
            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines),
            isScrapped: isScrapped,
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            recommendedFor: recommendedFor.trimmingCharacters(in: .whitespacesAndNewlines),
            wantsToRevisit: wantsToRevisit ?? false,
            recordedAt: recordedAt,
            artworkURL: artworkURL
        )
        modelContext.insert(record)
        didSave = true
        dismiss()
    }
}

#Preview {
    NavigationStack {
        RecordWriteView(
            category: .music,
            title: "Fearless (Taylor's Version)",
            creator: "Taylor Swift",
            artworkURL: nil
        )
    }
    .modelContainer(.recordPreviewContainer)
}
