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
    /// 예스24에서 책 제목으로 검색한 결과 페이지 — 탭하면 여기로 연결한다. 공식 상품 링크 API가
    /// 없어서 정확한 상품 페이지 대신 검색 결과로 보낸다.
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

    /// `search(_:)`와 달리 `results`/`isSearching` 같은 published 상태를 건드리지 않고
    /// 첫 번째 결과만 돌려준다 — 추천 엔진들이 카드 여러 개의 표지를 동시에 찾을 때, 같은
    /// 인스턴스를 여러 태스크에서 병렬로 호출해도 서로의 결과를 덮어쓰지 않기 때문이다.
    func firstResult(for query: String) async -> BookSearchResult? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !Secrets.googleBooksAPIKey.isEmpty else { return nil }
        return try? await fetchResults(for: trimmed).first
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
            // Google Books는 표지 URL을 http로 내려줄 때가 있어 ATS 차단을 피하려 https로 바꾼다.
            let thumbnail = (info.imageLinks?.thumbnail ?? info.imageLinks?.smallThumbnail)?
                .replacingOccurrences(of: "http://", with: "https://")

            return BookSearchResult(
                id: item.id,
                title: info.title,
                authorName: (info.authors ?? []).joined(separator: ", "),
                coverURL: thumbnail.flatMap(URL.init(string:)),
                linkURL: Self.yes24SearchURL(for: info.title)
            )
        }
    }

    private static func yes24SearchURL(for title: String) -> URL? {
        var components = URLComponents(string: "https://www.yes24.com/Product/Search")!
        components.queryItems = [
            URLQueryItem(name: "domain", value: "BOOK"),
            URLQueryItem(name: "query", value: title),
        ]
        return components.url
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
}

private struct ImageLinks: Decodable {
    let smallThumbnail: String?
    let thumbnail: String?
}
