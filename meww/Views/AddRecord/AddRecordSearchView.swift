//
//  AddRecordSearchView.swift
//  meww
//
//  Created by yunseo on 8/15/26.
//

import SwiftUI
import SwiftData
import MusicKit
import UIKit

/// "🔎 기록 추가 (검색)" — Figma node 33:10. 음악은 실제 Apple Music 카탈로그를
/// `MusicSearchService`로 검색한다 — entitlement 없이 코드 레벨에서 `MusicAuthorization`으로
/// 권한을 요청하는 방식만 사용한다.
/// 독서는 Google Books API(`BookSearchService`)로 검색한다 — `Secrets.googleBooksAPIKey`가
/// 비어있는 동안은 "제목 직접 입력" 경로로 빠진다.
struct AddRecordSearchView: View {
    /// 기본은 오늘이지만, 캘린더 날짜 상세에서 "이 날짜로 기록 추가"로 들어왔다면 그 날짜를 받는다.
    var recordedAt: Date = .now

    @State private var category: RecordCategory = .music
    @State private var query = ""
    @StateObject private var musicSearch = MusicSearchService()
    @StateObject private var bookSearch = BookSearchService()
    @State private var selection: SelectedItem?

    struct SelectedItem: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let creator: String
        let artworkURL: URL?
    }

    var body: some View {
        VStack(spacing: 0) {
            categoryToggle
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 12)

            searchField
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

            resultsCaption
                .padding(.horizontal, 24)
                .padding(.bottom, 4)

            if category == .music {
                musicResultsList
            } else {
                bookResultsList
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { hideKeyboard() }
        .navigationTitle("기록 추가")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selection) { item in
            RecordWriteView(
                category: category,
                title: item.title,
                creator: item.creator,
                artworkURL: item.artworkURL,
                recordedAt: recordedAt
            )
        }
        .task(id: query) {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            if category == .music {
                await musicSearch.search(query)
            } else {
                await bookSearch.search(query)
            }
        }
        .onChange(of: category) {
            query = ""
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Category toggle

    private var categoryToggle: some View {
        HStack(spacing: 2) {
            ForEach(RecordCategory.allCases) { option in
                Button {
                    category = option
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: option.systemImage)
                        Text(option.rawValue)
                    }
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(category == option ? .white : Color.recordTabInactive)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        category == option ? Color.recordFilterActiveBackground : Color.clear,
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.recordFilterInactiveBackground, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.recordTabInactive)
            TextField(
                category == .music ? "곡명, 아티스트로 검색" : "책 제목, 저자로 검색",
                text: $query
            )
            .font(.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.recordFilterInactiveBackground, in: RoundedRectangle(cornerRadius: 10))
    }

    private var resultsCaption: some View {
        Text(category == .music ? "Apple Music 검색 결과" : "Google Books 검색 결과")
            .font(.caption2)
            .foregroundStyle(Color.recordTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Music results (real MusicKit search)

    @ViewBuilder
    private var musicResultsList: some View {
        if musicSearch.isSearching {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if musicSearch.authorizationDenied {
            ContentUnavailableView(
                "Apple Music 접근이 필요해요",
                systemImage: "music.note",
                description: Text("설정 앱에서 meww의 Apple Music 접근을 허용해주세요.")
            )
        } else if let error = musicSearch.errorMessage {
            ContentUnavailableView(error, systemImage: "exclamationmark.triangle")
        } else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emptyState(title: "곡명이나 아티스트를 검색해보세요", systemImage: "magnifyingglass")
        } else if musicSearch.results.isEmpty {
            emptyState(title: "'\(query)'에 대한 검색 결과가 없어요", systemImage: "magnifyingglass")
        } else {
            List(musicSearch.results) { result in
                searchResultRow(
                    title: result.title,
                    creator: result.artistName,
                    artworkURL: result.artworkURL,
                    systemImage: "music.note"
                ) {
                    selection = SelectedItem(title: result.title, creator: result.artistName, artworkURL: result.artworkURL)
                }
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.immediately)
        }
    }

    /// 음악·독서 검색 결과 행에 공통으로 쓰는 레이아웃(표지 + 제목/저자).
    private func searchResultRow(
        title: String,
        creator: String,
        artworkURL: URL?,
        systemImage: String,
        onSelect: @escaping () -> Void
    ) -> some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.recordPlaceholderArt)
                    .frame(width: 48, height: 48)
                    .overlay {
                        AsyncImage(url: artworkURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: systemImage).foregroundStyle(.white.opacity(0.85))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.recordTextPrimary)
                        .lineLimit(1)
                    Text(creator)
                        .font(.caption)
                        .foregroundStyle(Color.recordTextSecondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowSeparatorTint(Color.recordSectionDivider)
    }

    /// Compact empty-state used for the "nothing here yet" screens — the stock
    /// `ContentUnavailableView` title renders at `.title2`/bold, which is too loud for
    /// these in-between states, so this keeps the same iconography at a smaller scale.
    private func emptyState(title: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title)
                .foregroundStyle(Color.recordTextSecondary)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.recordTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    // MARK: - Book results (Google Books API)

    @ViewBuilder
    private var bookResultsList: some View {
        if bookSearch.isSearching {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = bookSearch.errorMessage {
            manualEntryFallback(message: error)
        } else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emptyState(title: "책 제목이나 저자를 검색해보세요", systemImage: "magnifyingglass")
        } else if bookSearch.results.isEmpty {
            manualEntryFallback(message: "'\(query)'에 대한 검색 결과가 없어요")
        } else {
            List(bookSearch.results) { result in
                searchResultRow(
                    title: result.title,
                    creator: result.authorName,
                    artworkURL: result.coverURL,
                    systemImage: "book.closed"
                ) {
                    selection = SelectedItem(title: result.title, creator: result.authorName, artworkURL: result.coverURL)
                }
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.immediately)
        }
    }

    /// Google Books 검색이 안 되는 동안(API 키 미설정)이나 결과가 없을 때 — 입력한 제목으로
    /// 바로 기록을 작성할 수 있게 해주는 탈출구.
    private func manualEntryFallback(message: String) -> some View {
        VStack(spacing: 16) {
            emptyState(title: message, systemImage: "books.vertical")

            Button {
                selection = SelectedItem(title: query.trimmingCharacters(in: .whitespacesAndNewlines), creator: "", artworkURL: nil)
            } label: {
                Text("이 제목으로 기록 작성하기")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.recordFilterActiveBackground)
            .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

#Preview {
    NavigationStack {
        AddRecordSearchView()
    }
    .modelContainer(.recordPreviewContainer)
}
