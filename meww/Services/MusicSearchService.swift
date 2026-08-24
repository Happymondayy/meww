//
//  MusicSearchService.swift
//  meww
//
//  Created by yunseo on 8/15/26.
//

import Foundation
import Combine
import MusicKit

struct MusicSearchResult: Identifiable {
    let id: String
    let title: String
    let artistName: String
    let artworkURL: URL?
    /// Apple Music 웹/앱 상세 페이지 링크 — 탭하면 여기로 연결한다.
    let linkURL: URL?
}

/// Wraps a real Apple Music catalog search via MusicKit. Handled entirely at the
/// code level — no `com.apple.developer.musickit` entitlement is requested, so this
/// relies on `MusicAuthorization.request()` prompting the user for access at runtime.
@MainActor
final class MusicSearchService: ObservableObject {
    @Published private(set) var results: [MusicSearchResult] = []
    @Published private(set) var isSearching = false
    @Published private(set) var authorizationDenied = false
    @Published private(set) var errorMessage: String?

    func search(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            return
        }

        if MusicAuthorization.currentStatus != .authorized {
            let status = await MusicAuthorization.request()
            guard status == .authorized else {
                authorizationDenied = true
                return
            }
            authorizationDenied = false
        }

        isSearching = true
        errorMessage = nil

        do {
            var request = MusicCatalogSearchRequest(term: trimmed, types: [Song.self])
            request.limit = 15
            let response = try await request.response()
            results = response.songs.map { song in
                MusicSearchResult(
                    id: song.id.rawValue,
                    title: song.title,
                    artistName: song.artistName,
                    artworkURL: song.artwork?.url(width: 200, height: 200),
                    linkURL: song.url
                )
            }
        } catch {
            errorMessage = "검색 중 문제가 발생했어요. 다시 시도해주세요."
            results = []
        }

        isSearching = false
    }

    /// `search(_:)`와 달리 `results`/`isSearching` 같은 published 상태를 건드리지 않고
    /// 첫 번째 결과만 돌려준다 — 추천 엔진들이 카드 여러 개의 표지를 동시에 찾을 때, 같은
    /// 인스턴스를 여러 태스크에서 병렬로 호출해도 서로의 결과를 덮어쓰지 않기 때문이다.
    func firstResult(for query: String) async -> MusicSearchResult? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if MusicAuthorization.currentStatus != .authorized {
            guard await MusicAuthorization.request() == .authorized else { return nil }
        }

        var request = MusicCatalogSearchRequest(term: trimmed, types: [Song.self])
        request.limit = 15
        guard let song = try? await request.response().songs.first else { return nil }

        return MusicSearchResult(
            id: song.id.rawValue,
            title: song.title,
            artistName: song.artistName,
            artworkURL: song.artwork?.url(width: 200, height: 200),
            linkURL: song.url
        )
    }
}
