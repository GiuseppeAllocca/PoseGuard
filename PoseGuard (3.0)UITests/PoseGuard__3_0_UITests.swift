//
//  PoseGuard__3_0_UITests.swift
//  PoseGuard (3.0)UITests
//
//  Created by Acri Stefano on 10/03/25.
//

import XCTest

final class PoseGuard__3_0_UITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTrackingSequenceStartsAndStops() throws {
        #if targetEnvironment(simulator)
        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchEnvironment["POSEGUARD_UI_TRACKING_SEQUENCE"] = "1"
        app.launchPoseGuardInEnglish(testCase: self)
        app.completeOnboardingIfNeeded()

        app.buttons["Start tracking"].tap()
        for label in ["Waiting for headphone motion…", "Correct Posture!", "Bad Posture!"] {
            XCTAssertTrue(app.staticTexts[label].waitForExistence(timeout: 10), "Stato mancante: \(label)")
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Tracking con postura scorretta"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        app.buttons["Stop tracking"].tap()
        XCTAssertTrue(app.buttons["Start tracking"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Bad Posture!"].exists)
        #else
        throw XCTSkip("La sequenza controllata è disponibile soltanto sul Simulator.")
        #endif
    }

    @MainActor
    func testOnboardingCanBeReopenedAndCompleted() {
        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchPoseGuardInEnglish(testCase: self)
        app.completeOnboardingIfNeeded()

        app.buttons["How it works"].tap()
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        for instruction in ["Connect your AirPods", "Tap to start tracking", "Check your report"] {
            XCTAssertTrue(app.staticTexts[instruction].exists, "Istruzione mancante: \(instruction)")
        }
        continueButton.tap()
        XCTAssertTrue(app.buttons["Start tracking"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTipsCanBeOpenedClosedAndReopened() {
        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchPoseGuardInEnglish(testCase: self)
        app.completeOnboardingIfNeeded()

        for _ in 0..<2 {
            app.buttons["Tips"].tap()
            XCTAssertTrue(app.staticTexts["Keep your shoulders back!"].waitForExistence(timeout: 5))
            app.buttons["Close"].tap()
            XCTAssertTrue(app.buttons["Start tracking"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.staticTexts["Keep your shoulders back!"].exists)
        }
    }

    @MainActor
    func testTrackingWithoutMotionDataCanReturnToIdle() throws {
        #if targetEnvironment(simulator)
        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchPoseGuardInEnglish(testCase: self)
        app.completeOnboardingIfNeeded()

        let trackingButton = app.buttons["Start tracking"]
        XCTAssertTrue(trackingButton.waitForExistence(timeout: 5))
        trackingButton.tap()
        app.dismissSimulatorPermissionPromptsIfNeeded()

        let alert = app.alerts.matching(NSPredicate(format: "label IN %@", [
            "Headphone motion unavailable", "Motion access denied", "Motion access restricted"
        ])).firstMatch
        let waitingStatus = app.staticTexts["Waiting for headphone motion…"]
        let outcome = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in alert.exists || waitingStatus.exists },
            object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [outcome], timeout: 5), .completed)

        if alert.exists {
            if alert.label == "Motion access denied" || alert.label == "Motion access restricted" {
                XCTAssertTrue(alert.buttons["Open Settings"].exists)
            } else {
                XCTAssertTrue(alert.staticTexts["Headphone motion is unavailable. Connect compatible headphones, then try again."].exists)
            }
            alert.buttons["OK"].tap()
        } else {
            app.buttons["Stop tracking"].tap()
        }
        let idleState = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                !app.alerts.firstMatch.exists && trackingButton.exists
            },
            object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [idleState], timeout: 5), .completed)
        #else
        throw XCTSkip("Il test richiede il Simulator: sul dispositivo fisico la disponibilità delle cuffie non è controllata.")
        #endif
    }
}

extension XCUIApplication {
    @MainActor
    func launchPoseGuardInEnglish(testCase: XCTestCase) {
        #if targetEnvironment(simulator)
        testCase.addUIInterruptionMonitor(withDescription: "Permessi di PoseGuard nel Simulator") { alert in
            guard alert.label.contains("PoseGuard") else { return false }
            let denyButton = alert.buttons.matching(
                NSPredicate(format: "label IN %@", ["Don't Allow", "Don’t Allow"])
            ).firstMatch
            guard denyButton.exists else { return false }
            denyButton.tap()
            return true
        }
        #endif
        launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        launch()
    }

    @MainActor
    func completeOnboardingIfNeeded() {
        let continueButton = buttons["Continue"]
        if continueButton.waitForExistence(timeout: 3) {
            continueButton.tap()
        }
        dismissSimulatorPermissionPromptsIfNeeded()
        XCTAssertTrue(buttons["Start tracking"].waitForExistence(timeout: 5))
    }

    @MainActor
    func dismissSimulatorPermissionPromptsIfNeeded() {
        #if targetEnvironment(simulator)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let permissionAlert = springboard.alerts.matching(
            NSPredicate(
                format: "label CONTAINS %@ AND (label CONTAINS[c] %@ OR label CONTAINS[c] %@)",
                "PoseGuard", "Notifications", "motion and fitness"
            )
        ).firstMatch
        // Motion e Notifications possono comparire in successione al primo avvio.
        for _ in 0..<2 {
            guard permissionAlert.waitForExistence(timeout: 3) else { return }
            let denyButton = permissionAlert.buttons.matching(
                NSPredicate(format: "label IN %@", ["Don't Allow", "Don’t Allow"])
            ).firstMatch
            XCTAssertTrue(denyButton.waitForExistence(timeout: 5))
            denyButton.tap()
        }
        #endif
    }
}
