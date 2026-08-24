//
//  RecordDetailView.swift
//  meww
//
//  Created by yunseo on 8/16/26.
//

import SwiftUI
import SwiftData

/// "📱 상세보기" — 보기모드(Figma node 43:2 독서 / 43:80 음악)와 편집모드(43:39 독서 / 43:110 음악)를
/// 한 화면에서 `isEditing`으로 전환한다. `HomeView`의 기록 행을 탭하면 바텀시트로 뜬다.
struct RecordDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var record: Record

    @State private var isEditing = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                dragHandle
                artwork

                VStack(spacing: 4) {
                    Text(record.title)
                        .font(.headline)
                        .foregroundStyle(Color.recordTextPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(record.creator)
                        .font(.subheadline)
                        .foregroundStyle(Color.recordTextSecondary)
                }

                ratingRow

                if isEditing {
                    revisitPicker
                } else {
                    revisitChip
                }

                Rectangle()
                    .fill(Color.recordSeparator)
                    .frame(height: 1)

                fieldsSection
            }
            .padding(.horizontal, .recordSpacingXL)
            .padding(.top, .recordSpacingM)
            .padding(.bottom, .recordSpacingM)
        }
        .safeAreaInset(edge: .bottom) { bottomControls }
        .confirmationDialog("이 기록을 삭제할까요?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                modelContext.delete(record)
                dismiss()
            }
            Button("취소", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var dragHandle: some View {
        ZStack(alignment: .trailing) {
            Capsule()
                .fill(Color.recordDragHandle)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)

            if record.isScrapped {
                Text("🔖 스크랩됨")
                    .font(.caption2)
                    .foregroundStyle(Color.recordScrapBadgeText)
                    .padding(.horizontal, .recordSpacingS)
                    .padding(.vertical, .recordSpacingXS)
                    .background(Color.recordScrapBadgeBackground, in: RoundedRectangle(cornerRadius: .recordRadiusXS))
            }
        }
    }

    /// 음악·독서 표지 크기를 똑같이 맞춘다 — 책 표지(세로가 긴 원본 비율)를 그대로 두면
    /// 앨범 아트보다 훨씬 커 보여서 화면 균형이 깨진다.
    private var artwork: some View {
        RoundedRectangle(cornerRadius: .recordRadiusS)
            .fill(Color.recordPlaceholderArt)
            .overlay {
                if let artworkURL = record.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image.resizable().scaledToFill()
                            .frame(width: 96, height: 96)
                    } placeholder: {
                        Image(systemName: record.category.systemImage)
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 96, height: 96)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: .recordRadiusS))
                } else {
                    Image(systemName: record.category.systemImage)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(width: 96, height: 96)
    }

    // MARK: - Rating

    @ViewBuilder
    private var ratingRow: some View {
        HStack(spacing: 8) {
            if isEditing {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= record.rating ? "star.fill" : "star")
                            .foregroundStyle(star <= record.rating ? Color.recordRatingGold : Color(.systemGray4))
                            .onTapGesture { record.rating = star }
                    }
                }
                .font(.title3)
            } else {
                Text(record.ratingStars)
                    .font(.headline)
                    .foregroundStyle(Color.recordRatingGold)
            }

            Text(isEditing ? "(탭해서 별점 수정)" : record.recordedAtDisplay)
                .font(.caption2)
                .foregroundStyle(isEditing ? Color.recordHintText : Color.recordTextSecondary)
        }
    }

    // MARK: - Revisit

    private var revisitChip: some View {
        Text(record.wantsToRevisit
            ? (record.category == .music ? "다시 듣고 싶어요" : "다시 읽고 싶어요")
            : "한 번이면 충분해요"
        )
        .font(.caption)
        .foregroundStyle(record.wantsToRevisit ? Color.recordRevisitChipText : Color.recordTextSecondary)
        .padding(.horizontal, .recordSpacingM)
        .padding(.vertical, .recordSpacingS)
        .background(
            record.wantsToRevisit ? Color.recordRevisitChipBackground : Color.recordFilterInactiveBackground,
            in: RoundedRectangle(cornerRadius: .recordRadiusM)
        )
    }

    private var revisitPicker: some View {
        HStack(spacing: 8) {
            revisitOption(title: record.category == .music ? "다시 듣고 싶어요" : "다시 읽고 싶어요", value: true)
            revisitOption(title: "한 번이면 충분해요", value: false)
        }
    }

    private func revisitOption(title: String, value: Bool) -> some View {
        let isSelected = record.wantsToRevisit == value
        // "다시 듣고 싶어요"는 홈 화면·기록작성 화면과 같은 핑크 배경/글자색을 맞춘다.
        let selectedBackground = value ? Color.recordRevisitChipBackground : Color.recordFilterActiveBackground
        let selectedText = value ? Color.recordRevisitChipText : Color.white

        return Button {
            record.wantsToRevisit = value
        } label: {
            Text(title)
                .font(.caption)
                .foregroundStyle(isSelected ? selectedText : Color.recordTextSecondary)
                .padding(.horizontal, .recordSpacingM)
                .padding(.vertical, .recordSpacingS)
                .background(
                    isSelected ? selectedBackground : Color.recordFilterInactiveBackground,
                    in: RoundedRectangle(cornerRadius: .recordRadiusM)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Fields

    @ViewBuilder
    private var fieldsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            fieldSection(
                label: record.category == .music ? "가장 인상 깊은 가사나 순간" : "인상 깊었던 문장",
                text: $record.comment,
                showsScrapToggle: true
            )
            if record.category == .book {
                fieldSection(label: "한 문장 요약", text: $record.summary)
                fieldSection(label: "추천 대상", text: $record.recommendedFor)
            }
        }
    }

    private func fieldSection(label: String, text: Binding<String>, showsScrapToggle: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.recordTextSecondary)
                if showsScrapToggle {
                    // 체크하면 "문장 스크랩" 화면에 모인다 — comment가 채워졌다고
                    // 자동으로 스크랩되지 않는다.
                    Button {
                        record.isScrapped.toggle()
                        try? modelContext.save()
                    } label: {
                        Image(systemName: record.isScrapped ? "bookmark.fill" : "bookmark")
                            .font(.body)
                            .foregroundStyle(record.isScrapped ? Color.recordScrapBadgeText : Color.recordTextSecondary)
                            .padding(.recordSpacingS)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            if isEditing {
                TextField("", text: text, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(Color.recordTextPrimary)
                    .lineLimit(2...6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.recordSpacingM)
                    .background(Color.recordFieldBackground, in: RoundedRectangle(cornerRadius: .recordRadiusS))
            } else {
                Text(text.wrappedValue.isEmpty ? "—" : text.wrappedValue)
                    .font(.subheadline)
                    .foregroundStyle(text.wrappedValue.isEmpty ? Color.recordTextSecondary : Color.recordFieldText)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.recordSpacingM)
                    .background(Color.recordFieldBackground, in: RoundedRectangle(cornerRadius: .recordRadiusS))
            }
        }
    }

    // MARK: - Bottom controls

    private var bottomControls: some View {
        VStack(spacing: 10) {
            Button {
                if isEditing {
                    try? modelContext.save()
                }
                isEditing.toggle()
            } label: {
                Text(isEditing ? "완료" : "편집하기")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .recordSpacingM)
                    .background(Color.recordFilterActiveBackground, in: RoundedRectangle(cornerRadius: .recordRadiusS))
            }
            .buttonStyle(.plain)

            if isEditing {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Text("기록 삭제")
                        .font(.footnote)
                        .foregroundStyle(Color.recordDestructiveText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .recordSpacingXL)
        .padding(.top, .recordSpacingM)
        .padding(.bottom, .recordSpacingM)
        .background(.bar)
    }
}

#Preview {
    RecordDetailView(record: Record(
        category: .book,
        title: "절창",
        creator: "구병모",
        rating: 4,
        comment: "우리는 모두 누군가의 이방인이다",
        isScrapped: true,
        summary: "공감이란 무엇인지 다시 생각하게 됨",
        recommendedFor: "감정 표현이 서툰 사람에게",
        wantsToRevisit: true
    ))
    .modelContainer(.recordPreviewContainer)
}
