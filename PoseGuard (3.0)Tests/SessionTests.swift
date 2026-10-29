//
//  SessionTests.swift
//  PoseGuard (3.0)Tests
//

import Foundation
import Testing
@testable import PoseGuard

struct SessionTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func timerCountsOnlyCorrectStretches() throws {
        // 0–30s correct, 30–70s bad, 70–100s correct: 60 of 100 seconds correct.
        var timer = CorrectPostureTimer(start: start, isCorrect: true)
        timer.update(isCorrect: false, at: start.addingTimeInterval(30))
        timer.update(isCorrect: true, at: start.addingTimeInterval(70))
        let session = try #require(timer.session(endingAt: start.addingTimeInterval(100)))
        #expect(session.avgQuality == 60)
        #expect(session.category == .media)
    }

    @Test func timerDropsSessionsShorterThanTenSeconds() {
        let timer = CorrectPostureTimer(start: start, isCorrect: true)
        #expect(timer.session(endingAt: start.addingTimeInterval(5)) == nil)
    }

    @Test @MainActor func storeGroupsSessionsByDayAndPersists() throws {
        let defaults = try #require(UserDefaults(suiteName: #function))
        defaults.removePersistentDomain(forName: #function)
        let calendar = Calendar(identifier: .gregorian)
        let now = start
        let yesterday = now.addingTimeInterval(-86_400)

        let store = SessionStore(defaults: defaults)
        store.add(PostureSession(start: yesterday, end: yesterday.addingTimeInterval(600), avgQuality: 90))
        store.add(PostureSession(start: now, end: now.addingTimeInterval(1_800), avgQuality: 40))
        store.add(PostureSession(start: now, end: now.addingTimeInterval(600), avgQuality: 80))

        let week = SessionStore(defaults: defaults).lastWeek(calendar: calendar, now: now)
        #expect(week.count == 7)
        #expect(week.sessionCount == 3)
        #expect(week[5].sessions.count == 1)
        // Today: 40% for 30 min and 80% for 10 min, weighted by length = 50%.
        #expect(week[6].averageQuality == 50)
    }
}
