//
//  BookSearchService.swift
//  meww
//
//  Created by yunseo on 8/16/26.
//

import Foundation
import Combine

struct BookSearchResult: Identifiable {
    let id: String
    let title: String
    let authorName: String
    let coverURL: URL?
    /// Google Books 상세 페이지 링크 — 탭하면 여기로 연결한다.
    let linkURL: URL?
}

/// Google Books API(`volumes` 검색)로 실제 책을 검색한다 — `MusicSearchService`와 같은 자리.
/// API 키는 코드에 직접 두지 않고 `Secrets.googleBooksAPIKey`(`Secrets.swift`, git에는
/// 올라가지 않음)에서 읽는다.
@MainActor
final class BookSearchService: ObservableObject {
    @Published private(set) var results: [BookSearchResult] = []
    @Published private(set) var isSearching = false
    @Published private(set) var errorMessage: String?

    private let session = URLSession.shared

    func search(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            errorMessage = nil
            return
        }

        guard !Secrets.googleBooksAPIKey.isEmpty else {
            results = []
            errorMessage = "Google Books API 키가 아직 설정되지 않았어요."
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            results = try await fetchResults(for: trimmed)
        } catch {
            errorMessage = "검색 중 문제가 발생했어요. 다시 시도해주세요."
            results = []
        }

        isSearching = false
    }

    private func fetchResults(for query: String) async throws -> [BookSearchResult] {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "key", value: Secrets.googleBooksAPIKey),
            URLQueryItem(name: "maxResults", value: "20"),
        ]

        let (data, _) = try await session.data(from: components.url!)
        let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)

        return (response.items ?? []).map { item in
            let info = item.volumeInfo
            // Google Books는 표지·상세 페이지 URL을 http로 내려줄 때가 있어 ATS 차단을 피하려 https로 바꾼다.
            let thumbnail = (info.imageLinks?.thumbnail ?? info.imageLinks?.smallThumbnail)?
                .replacingOccurrences(of: "http://", with: "https://")
            let infoLink = info.infoLink?.replacingOccurrences(of: "http://", with: "https://")

            return BookSearchResult(
                id: item.id,
                title: info.title,
                authorName: (info.authors ?? []).joined(separator: ", "),
                coverURL: thumbnail.flatMap(URL.init(string:)),
                linkURL: infoLink.flatMap(URL.init(string:))
            )
        }
    }
}

private struct GoogleBooksResponse: Decodable {
    let items: [GoogleBookItem]?
}

private struct GoogleBookItem: Decodable {
    let id: String
    let volumeInfo: VolumeInfo
}

private struct VolumeInfo: Decodable {
    let title: String
    let authors: [String]?
    let imageLinks: ImageLinks?
    let infoLink: String?
}

private struct ImageLinks: Decodable {
    let smallThumbnail: String?
    let thumbnail: String?
}
