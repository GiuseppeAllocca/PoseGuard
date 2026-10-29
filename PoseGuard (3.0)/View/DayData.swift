//
//  DayData.swift
//  PoseGuard (3.0)
//
//  Created by Acri Stefano on 10/03/25.
//

import Foundation

/// The sessions recorded on one calendar day.
struct DayData: Identifiable, Equatable {
    /// Start of the day.
    let date: Date
    let sessions: [PostureSession]

    var id: Date { date }
    var title: String { date.formatted(.dateTime.weekday(.wide)) }

    func seconds(for category: PostureCategory) -> TimeInterval {
        sessions.filter { $0.category == category }.reduce(0) { $0 + $1.seconds }
    }

    var totalSeconds: TimeInterval {
        sessions.reduce(0) { $0 + $1.seconds }
    }

    /// Quality averaged over the day, weighted by session length.
    var averageQuality: Double {
        guard totalSeconds > 0 else { return 0 }
        return sessions.reduce(0) { $0 + Double($1.avgQuality) * $1.seconds } / totalSeconds
    }

    /// Category segments in hours, stacked bottom-up (good, medium, bad), skipping empty ones.
    var stack: [(category: PostureCategory, start: Double, end: Double)] {
        var top = 0.0
        return PostureCategory.allCases.compactMap { category in
            let hours = seconds(for: category) / 3600
            guard hours > 0 else { return nil }
            defer { top += hours }
            return (category, top, top + hours)
        }
    }
}

extension [DayData] {
    var sessionCount: Int { reduce(0) { $0 + $1.sessions.count } }
    var totalSeconds: TimeInterval { reduce(0) { $0 + $1.totalSeconds } }

    var averageQuality: Double {
        guard totalSeconds > 0 else { return 0 }
        return reduce(0) { $0 + $1.averageQuality * $1.totalSeconds } / totalSeconds
    }

    func sessionCount(for category: PostureCategory) -> Int {
        reduce(0) { $0 + $1.sessions.filter { $0.category == category }.count }
    }
}
