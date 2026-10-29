//
//  ReportType.swift
//  PoseGuard (3.0)
//
//  Created by Acri Stefano on 10/03/25.
//

import Foundation

enum ReportType: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        }
    }
}
