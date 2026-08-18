//
//  Color+Record.swift
//  meww
//
//  Created by yunseo on 8/15/26.
//

import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    static let recordTextPrimary = Color(hex: 0x1A1A1A)
    static let recordTextSecondary = Color(hex: 0x8C8C8F)

    static let recordCardBackground = Color(hex: 0xF7F7F9)
    static let recordAccentPink = Color(hex: 0xD90078)

    static let recordRevisitChipBackground = Color(hex: 0xFCDEED)
    static let recordRevisitChipText = Color(hex: 0xA6005C)

    static let recordNeutralChipBackground = Color(hex: 0xF5F5F7)
    static let recordNeutralChipText = Color(hex: 0x59595C)

    static let recordSectionDivider = Color(hex: 0xF0F0F2)

    static let recordStatMusic = Color(hex: 0x7BBA91)
    static let recordStatBook = Color(hex: 0xE4007F)

    static let recordFilterActiveBackground = Color(hex: 0x1A1A1A)
    static let recordFilterInactiveBackground = Color(hex: 0xF2F2F5)
    static let recordFilterInactiveText = Color(hex: 0x4D4D4D)
    static let recordFilterBadgeBackground = Color(hex: 0xE0E0E3)
    static let recordFilterBadgeText = Color(hex: 0x666666)

    static let recordSeparator = Color(hex: 0xEDEDF0)
    static let recordRatingGold = Color(hex: 0xFFB833)

    static let recordRevisitTagBackground = Color(hex: 0xF5F0F2)
    static let recordRevisitTagText = Color(hex: 0xB8666B)
    static let recordOnceTagBackground = Color(hex: 0xF0F0F2)

    static let recordTabInactive = Color(hex: 0x99999C)

    static let recordPlaceholderArt = Color(hex: 0xE0DBD4)

    // MARK: - Detail view (📱 상세보기)

    static let recordScrapBadgeBackground = Color(hex: 0xF5F0D9)
    static let recordScrapBadgeText = Color(hex: 0x8C7026)

    static let recordFieldBackground = Color(hex: 0xF7F7F7)
    static let recordFieldText = Color(hex: 0x333333)

    static let recordDragHandle = Color(hex: 0xD9D9DB)

    /// "(탭해서 별점 수정)" 안내 문구 — 상세보기 편집모드.
    static let recordHintText = Color(hex: 0xB2B2B5)
    /// "기록 삭제" — 상세보기 편집모드.
    static let recordDestructiveText = Color(hex: 0x91010F)

    // MARK: - 문장 스크랩 (📑 문장 스크랩)

    static let recordScrapCardBackground = Color(hex: 0xFAFAFA)
    static let recordScrapCardText = Color(hex: 0x26241F)
    static let recordScrapCardMetaTitle = Color(hex: 0x807566)
    static let recordScrapCardMetaSecondary = Color(hex: 0xA6A199)
}
