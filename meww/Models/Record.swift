//
//  Record.swift
//  meww
//
//  Created by yunseo on 8/15/26.
//

import Foundation
import SwiftData

enum RecordCategory: String, Codable, CaseIterable, Identifiable {
    case music = "음악"
    case book = "독서"

    var id: String { rawValue }

    /// "아티스트" for music, "저자" for books — used as the field label in forms/lists.
    var creatorLabel: String {
        switch self {
        case .music: "아티스트"
        case .book: "저자"
        }
    }

    var systemImage: String {
        switch self {
        case .music: "music.note"
        case .book: "book.closed"
        }
    }
}

@Model
final class Record {
    private var categoryRawValue: String
    var title: String
    /// Artist for music, author for books.
    var creator: String
    /// 1...5
    var rating: Int
    var comment: String
    /// 사용자가 북마크로 직접 체크한 문장만 "문장 스크랩" 화면에 모인다 — `comment`가
    /// 채워져 있다고 자동으로 스크랩되지 않는다.
    var isScrapped: Bool = false
    /// "한 문장으로 요약한다면?" — 독서 기록에서만 입력받는다.
    var summary: String = ""
    /// "누구에게 추천하고 싶나요?" — 독서 기록에서만 입력받는다.
    var recommendedFor: String = ""
    /// "다시 듣고/읽고 싶어요"
    var wantsToRevisit: Bool
    /// 기록시각
    var recordedAt: Date
    /// Apple Music 앨범/트랙 아트워크 URL (문자열로 저장, SwiftData가 `URL`을 직접 지원하지 않음).
    var artworkURLString: String?
    /// "다시 보고 싶은 기록"을 정리하는 폴더 — 폴더가 삭제되면 nil로 돌아간다("전체").
    var folder: Folder?

//    var category: RecordCategory {
//        get { RecordCategory(rawValue: categoryRawValue) ?? .music }
//        set { categoryRawValue = newValue.rawValue }
//    }
    var category: RecordCategory {
        get {
            guard let category = RecordCategory(rawValue: categoryRawValue) else {
                return .music
            }
            return category
        }
        set {
            categoryRawValue = newValue.rawValue
        }
    }
    

//    var artworkURL: URL? {
//        get { artworkURLString.flatMap(URL.init(string:)) }
//        set { artworkURLString = newValue?.absoluteString }
//    }
    var artworkURL: URL? {
        get {
            guard let urlString = artworkURLString else {
                return nil
            }
            return URL(string: urlString)
        }
        set {
            if let url = newValue {
                artworkURLString = url.absoluteString
            } else {
                artworkURLString = nil
            }
        }
    }

    init(
        category: RecordCategory,
        title: String,
        creator: String,
        rating: Int = 0,
        comment: String = "",
        isScrapped: Bool = false,
        summary: String = "",
        recommendedFor: String = "",
        wantsToRevisit: Bool = false,
        recordedAt: Date = .now,
        artworkURL: URL? = nil
    ) {
        self.categoryRawValue = category.rawValue
        self.title = title
        self.creator = creator
        self.rating = rating
        self.comment = comment
        self.isScrapped = isScrapped
        self.summary = summary
        self.recommendedFor = recommendedFor
        self.wantsToRevisit = wantsToRevisit
        self.recordedAt = recordedAt
        self.artworkURLString = artworkURL?.absoluteString
    }
}
