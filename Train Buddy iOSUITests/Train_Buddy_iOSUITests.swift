import XCTest

final class Train_Buddy_iOSUITests: XCTestCase {
    @MainActor
    func testLockScreenRefreshDoesNotOpenApp() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--demo"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ICE 542"].waitForExistence(timeout: 20))
        let start = app.buttons["startLiveActivity"]
        reveal(start, in: app)
        start.tap()
        XCTAssertTrue(app.buttons["End Live Activity"].waitForExistence(timeout: 10))
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01))
            .press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)))
        let refresh = springboard.buttons["Refresh live information"]
        XCTAssertTrue(refresh.waitForExistence(timeout: 10), springboard.debugDescription)
        if springboard.staticTexts["Allow Live Activities from Train Buddy?"].exists {
            springboard.buttons["Allow"].tap()
        }
        let attachment = XCTAttachment(screenshot: springboard.screenshot())
        attachment.name = "Live Activity with manual refresh"
        attachment.lifetime = .keepAlways
        add(attachment)
        refresh.tap()
        XCTAssertNotEqual(app.state, .runningForeground)
        app.activate()
        let end = app.buttons["End Live Activity"]
        reveal(end, in: app)
        end.tap()
    }

    @MainActor
    func testControlCenterStartsActivityWithoutOpeningApp() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--demo"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ICE 542"].waitForExistence(timeout: 20))
        let start = app.buttons["startLiveActivity"]
        reveal(start, in: app)
        let oldActivity = app.buttons["End Live Activity"]
        if oldActivity.exists {
            reveal(oldActivity, in: app)
            oldActivity.tap()
        }
        app.terminate()
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let topRight = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.01))
        topRight.press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.7)))
        let root = springboard.otherElements["cc-root-folder-view"]
        if springboard.buttons["Add a Control"].exists {
            root.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        let control = springboard.buttons.matching(NSPredicate(format:
            "identifier == %@ OR label CONTAINS %@", "TrainBuddyStartLiveActivity", "Start Train Live Activity")).firstMatch
        if !control.exists {
            let edit = springboard.buttons["Add Controls"]
            XCTAssertTrue(edit.waitForExistence(timeout: 5), springboard.debugDescription)
            edit.tap()
            let addControl = springboard.buttons["Add a Control"]
            XCTAssertTrue(addControl.waitForExistence(timeout: 5), springboard.debugDescription)
            addControl.tap()
            let search = springboard.searchFields.firstMatch
            XCTAssertTrue(search.waitForExistence(timeout: 5), springboard.debugDescription)
            search.tap()
            search.typeText("Train Buddy")
            let galleryControl = springboard.buttons["Start Train Live Activity"]
            XCTAssertTrue(galleryControl.waitForExistence(timeout: 5), springboard.debugDescription)
            galleryControl.tap()
            root.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        XCTAssertTrue(control.waitForExistence(timeout: 5), springboard.debugDescription)
        control.tap()
        let finished = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isSelected == false"), object: control)
        XCTAssertEqual(XCTWaiter.wait(for: [finished], timeout: 15), .completed)
        XCTAssertNotEqual(app.state, .runningForeground)
        app.activate()
        let end = app.buttons["End Live Activity"]
        reveal(end, in: app)
        XCTAssertTrue(end.exists)
        end.tap()
    }

    @MainActor
    func testJourneyRefreshDiagnosticsAndLiveActivityLifecycle() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--demo"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ICE 542"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["Demo data · not live"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "iPhone journey with small delays and train artwork"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let refresh = app.buttons["refreshJourney"]
        reveal(refresh, in: app)
        XCTAssertTrue(refresh.isEnabled)
        refresh.tap()
        XCTAssertTrue(refresh.waitForExistence(timeout: 10))

        let start = app.buttons["startLiveActivity"]
        reveal(start, in: app)
        start.tap()
        let end = app.buttons["End Live Activity"]
        XCTAssertTrue(end.waitForExistence(timeout: 15), app.debugDescription)
        // The update action remains usable before a background/foreground transition.
        app.buttons["startLiveActivity"].tap()
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(end.waitForExistence(timeout: 10))
        reveal(end, in: app)
        end.tap()
        XCTAssertFalse(end.waitForExistence(timeout: 2))

        let report = app.buttons["Report API problem…"]
        reveal(report, in: app)
        report.tap()
        XCTAssertTrue(app.navigationBars["API diagnostics"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "schemaVersion")).firstMatch.exists)
        let diagnostics = XCTAttachment(screenshot: app.screenshot())
        diagnostics.name = "Diagnostic preview before sharing"
        diagnostics.lifetime = .keepAlways
        add(diagnostics)
        app.buttons["Done"].tap()
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<16 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTFail("Element not reachable: \(element)")
    }
}
