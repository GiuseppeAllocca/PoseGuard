//
//  PoseGuard__3_0_UITestsLaunchTests.swift
//  PoseGuard (3.0)UITests
//
//  Created by Acri Stefano on 10/03/25.
//

import XCTest

final class PoseGuard__3_0_UITestsLaunchTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchPoseGuardInEnglish(testCase: self)
        app.completeOnboardingIfNeeded()

        XCTAssertTrue(app.buttons["How it works"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Start tracking"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Schermata principale dopo l'avvio"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
