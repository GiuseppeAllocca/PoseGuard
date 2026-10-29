//
//  PostureCategory.swift
//  PoseGuard (3.0)
//

import SwiftUI

enum PostureCategory: String, CaseIterable, Identifiable {
    case buona = "Good"
    case media = "Medium"
    case cattiva = "Bad"

    var id: String { rawValue }

    /// Maps a 0–100 quality score to its category.
    init(quality: Double) {
        switch quality {
        case 80...: self = .buona
        case 60..<80: self = .media
        default: self = .cattiva
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .buona: "Good"
        case .media: "Medium"
        case .cattiva: "Bad"
        }
    }

    var color: Color {
        switch self {
        case .buona: Theme.brandGreen
        case .media: Theme.gold
        case .cattiva: Theme.alertRed
        }
    }

    /// Paired with `color` everywhere, so the category never relies on color alone.
    var icon: String {
        switch self {
        case .buona: "checkmark.circle.fill"
        case .media: "exclamationmark.circle.fill"
        case .cattiva: "xmark.circle.fill"
        }
    }
}
