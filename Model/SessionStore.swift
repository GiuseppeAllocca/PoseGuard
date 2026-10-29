//
//  SessionStore.swift
//  PoseGuard (3.0)
//

import Foundation
import Observation

/// Recorded tracking sessions, kept on device in UserDefaults.
@MainActor
@Observable
final class SessionStore {
    private(set) var sessions: [PostureSession]

    @ObservationIgnored private let defaults: UserDefaults
    private static let key = "recordedSessions"

    // ponytail: keeps every session in one UserDefaults blob; move to a file or SwiftData if history grows large.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        sessions = defaults.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode([PostureSession].self, from: $0) } ?? []
    }

    func add(_ session: PostureSession) {
        sessions.append(session)
        defaults.set(try? JSONEncoder().encode(sessions), forKey: Self.key)
    }

    /// The last seven calendar days, oldest first, including days without sessions.
    func lastWeek(calendar: Calendar = .current, now: Date = .now) -> [DayData] {
        let today = calendar.startOfDay(for: now)
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayData(date: date, sessions: sessions.filter { calendar.isDate($0.start, inSameDayAs: date) })
        }
    }

    /// Today's sessions, or `nil` when nothing was recorded today.
    func today(calendar: Calendar = .current, now: Date = .now) -> DayData? {
        guard let today = lastWeek(calendar: calendar, now: now).last, !today.sessions.isEmpty else { return nil }
        return today
    }
}
