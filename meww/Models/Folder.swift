//
//  Folder.swift
//  meww
//
//  Created by yunseo on 8/16/26.
//

import Foundation
import SwiftData

/// 사용자가 "다시 보고 싶은 기록"(❤️)을 정리하는 폴더 — Figma node 44:2의 "📁 드라이브" 같은 칩.
@Model
final class Folder {
    var name: String
    var createdAt: Date

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }
}
