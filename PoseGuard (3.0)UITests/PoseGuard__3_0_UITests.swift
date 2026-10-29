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
    func testTrackingStatusKeepsItsPosition() throws {
        #if targetEnvironment(simulator)
        for language in ["en", "it"] {
            let app = XCUIApplication()
            defer { app.terminate() }
            app.launchEnvironment["POSEGUARD_UI_TRACKING_SEQUENCE"] = "1"
            app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "en" ? "en_US" : "it_IT"]
            app.launch()
            let continueButton = app.buttons[language == "en" ? "Continue" : "Continua"]
            if continueButton.waitForExistence(timeout: 2) { continueButton.tap() }
            let labels = language == "en"
                ? ["Tap To Track", "Waiting for headphone motion…", "Correct Posture!", "Bad Posture!"]
                : ["Tocca per tracciare", "In attesa dei dati di movimento delle cuffie…", "Postura Corretta!", "Cattiva"]
            var frames: [CGRect] = []
            for (index, label) in labels.enumerated() {
                let status = app.staticTexts.matching(identifier: "trackingStatus").matching(NSPredicate(format: "label == %@", label)).firstMatch
                XCTAssertTrue(status.waitForExistence(timeout: 10), "Stato mancante: \(label)")
                frames.append(status.frame)
                let screenshot = XCTAttachment(screenshot: app.screenshot())
                screenshot.name = "Tracking \(language) \(index)"
                screenshot.lifetime = .keepAlways
                add(screenshot)
                if index == 0 { app.buttons["Airpods Pro"].tap() }
            }
            let measurement = XCTAttachment(string: frames.enumerated().map { "\(labels[$0.offset]): \($0.element)" }.joined(separator: "\n"))
            measurement.name = "Geometria del testo \(language)"
            measurement.lifetime = .keepAlways
            add(measurement)
            for frame in frames.dropFirst() {
                XCTAssertEqual(frame.midY, frames[0].midY, accuracy: 1, "Il cambio di stato sposta il centro del testo")
                XCTAssertGreaterThan(frame.height, 0)
                XCTAssertTrue(app.frame.contains(frame), "Il testo esce dallo schermo")
            }
        }
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

        let titleButton = app.buttons["PoseGuard"]
        XCTAssertTrue(titleButton.waitForExistence(timeout: 5))
        titleButton.tap()

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        for instruction in [
            "Connect your AirPods",
            "The app'll use your AirPods' gyroscope to track your posture.",
            "Tap to start tracking",
            "When the main button goes green the app is tracking your posture.",
            "Read posture tips",
            "Open Tips for everyday posture advice."
        ] {
            XCTAssertTrue(app.staticTexts[instruction].exists, "Istruzione mancante: \(instruction)")
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Onboarding in inglese"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        continueButton.tap()
        app.dismissSimulatorPermissionPromptsIfNeeded()

        XCTAssertTrue(app.staticTexts["Tap To Track"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOnboardingInstructionsAreAvailableInItalian() {
        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = ["-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        app.launch()

        let continueButton = app.buttons["Continua"]
        if !continueButton.waitForExistence(timeout: 3) {
            let titleButton = app.buttons["PoseGuard"]
            XCTAssertTrue(titleButton.waitForExistence(timeout: 5))
            titleButton.tap()
        }
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        for instruction in [
            "Collega i tuoi AirPods",
            "PoseGuard usa i sensori degli AirPods per monitorare la postura.",
            "Tocca per iniziare",
            "Il pulsante verde indica che il monitoraggio è attivo.",
            "Consulta i suggerimenti",
            "Apri Suggerimenti per consigli sulla postura."
        ] {
            XCTAssertTrue(app.staticTexts[instruction].exists, "Istruzione mancante: \(instruction)")
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Onboarding in italiano"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        continueButton.tap()
        XCTAssertTrue(app.staticTexts["Tocca per tracciare"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTipsCanBeOpenedClosedAndReopened() {
        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchPoseGuardInEnglish(testCase: self)
        app.completeOnboardingIfNeeded()

        let tipsButton = app.buttons["Show posture tips"]
        let closeButton = app.buttons["Close tips"]
        let trackingButton = app.buttons["Airpods Pro"]
        XCTAssertTrue(tipsButton.waitForExistence(timeout: 5))
        XCTAssertFalse(closeButton.isHittable)
        XCTAssertFalse(app.staticTexts["Tips"].isHittable)

        for _ in 0..<2 {
            tipsButton.tap()
            XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["Keep your shoulders back!"].waitForExistence(timeout: 5))
            let closeIsReady = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in closeButton.isHittable },
                object: nil
            )
            XCTAssertEqual(XCTWaiter.wait(for: [closeIsReady], timeout: 5), .completed)
            XCTAssertGreaterThanOrEqual(closeButton.frame.width, 44)
            XCTAssertGreaterThanOrEqual(closeButton.frame.height, 44)
            XCTAssertFalse(trackingButton.isHittable)
            XCTAssertFalse(app.buttons["PoseGuard"].isHittable)
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Pannello suggerimenti con chiusura accessibile"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            closeButton.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).tap()

            let returnedToHome = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in
                    !closeButton.isHittable && tipsButton.isHittable && trackingButton.isHittable
                        && !app.staticTexts["Tips"].isHittable
                },
                object: nil
            )
            XCTAssertEqual(XCTWaiter.wait(for: [returnedToHome], timeout: 5), .completed)
        }
    }

    @MainActor
    func testTipsCanBeDismissedByDraggingUp() {
        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchPoseGuardInEnglish(testCase: self)
        app.completeOnboardingIfNeeded()
        let tipsButton = app.buttons["Show posture tips"]
        let closeButton = app.buttons["Close tips"]
        let handle = app.descendants(matching: .any)["tipsDismissHandle"]

        tipsButton.tap()
        XCTAssertTrue(handle.waitForExistence(timeout: 5))
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                closeButton.isHittable && handle.frame.minY >= 0 && handle.frame.maxY < app.frame.maxY
            },
            object: nil
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [ready], timeout: 5), .completed,
            "Pannello non pronto: Chiudi tappabile=\(closeButton.isHittable), maniglia=\(handle.frame)"
        )
        XCTAssertGreaterThanOrEqual(handle.frame.height, 44)
        XCTAssertGreaterThan(handle.frame.midY, app.frame.height * 0.8)
        XCTAssertLessThan(handle.frame.maxY, app.frame.maxY)

        app.scrollViews.containing(.staticText, identifier: "Keep your shoulders back!").firstMatch.swipeDown()
        XCTAssertTrue(closeButton.isHittable)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Suggerimenti con maniglia inferiore"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        let closed = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in tipsButton.isHittable && !closeButton.isHittable },
            object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 5), .completed)

        tipsButton.tap()
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        let header = app.staticTexts["Tips"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        header.press(forDuration: 0.05, thenDragTo: header.withOffset(CGVector(dx: 0, dy: -40)))
        let closedFromHeader = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in tipsButton.isHittable && !closeButton.isHittable },
            object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [closedFromHeader], timeout: 5), .completed)
    }

    @MainActor
    func testTrackingWithoutMotionDataCanReturnToIdle() throws {
        #if targetEnvironment(simulator)
        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchPoseGuardInEnglish(testCase: self)
        app.completeOnboardingIfNeeded()

        let trackingButton = app.buttons["Airpods Pro"]
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
            XCTAssertTrue(waitingStatus.exists)
            XCTAssertEqual(trackingButton.label, "Cancel starting")
            trackingButton.tap()
        }
        let idleState = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                !app.alerts.firstMatch.exists
                    && app.staticTexts["Tap To Track"].exists
                    && trackingButton.label == "Start tracking"
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
        XCTAssertTrue(staticTexts["Tap To Track"].waitForExistence(timeout: 5))
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
