//
//  CorrectPostureTimer.swift
//  PoseGuard (3.0)
//

import Foundation

/// Measures how long the posture stays correct during one tracking session.
/// Fed only with `isPostureCorrect` changes, so it works with any posture monitor.
struct CorrectPostureTimer {
    let start: Date
    private var correctSeconds: TimeInterval = 0
    private var correctSince: Date?

    init(start: Date, isCorrect: Bool) {
        self.start = start
        correctSince = isCorrect ? start : nil
    }

    mutating func update(isCorrect: Bool, at date: Date) {
        if isCorrect {
            if correctSince == nil { correctSince = date }
        } else if let since = correctSince {
            correctSeconds += date.timeIntervalSince(since)
            correctSince = nil
        }
    }

    /// The finished session, or `nil` when it was too short to be meaningful.
    func session(endingAt end: Date, minimumLength: TimeInterval = 10) -> PostureSession? {
        let total = end.timeIntervalSince(start)
        guard total >= minimumLength else { return nil }
        let correct = correctSeconds + (correctSince.map { end.timeIntervalSince($0) } ?? 0)
        return PostureSession(start: start, end: end, avgQuality: Int((correct / total * 100).rounded()))
    }
}
