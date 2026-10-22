import XCTest
import OnboardConnect
@testable import Train_Buddy

final class Train_BuddyTests: XCTestCase {
    @MainActor
    func testScheduledStopsWithoutForecastRemainVisible() {
        let loaded = expectation(description: "ČD scheduled journey")
        CDDataController.shared.loadTrip(demoMode: true) { trip, error in
            XCTAssertNil(error)
            guard let trip = trip else { XCTFail("Missing journey"); loaded.fulfill(); return }
            let controller = JourneyStopCustomViewController(stopIndex: 0, journey: trip)
            _ = controller.view
            XCTAssertEqual(controller.stopNameLabel.stringValue, "Graz Hbf")
            XCTAssertNotEqual(controller.arriveTimeLabel.stringValue, "–")
            XCTAssertTrue(controller.delayLabel.isHidden, "Missing forecasts must not invent a delay")
            loaded.fulfill()
        }
        wait(for: [loaded], timeout: 3)
    }

    func testExitAlarmLocalization() throws {
        let englishPath = try XCTUnwrap(Bundle.main.path(forResource: "en", ofType: "lproj"))
        let germanPath = try XCTUnwrap(Bundle.main.path(forResource: "de", ofType: "lproj"))
        let english = try XCTUnwrap(Bundle(path: englishPath))
        let german = try XCTUnwrap(Bundle(path: germanPath))
        XCTAssertEqual(english.localizedString(forKey: "Exit alarm", value: nil, table: nil), "Exit alarm")
        XCTAssertEqual(german.localizedString(forKey: "Exit alarm", value: nil, table: nil), "Ausstiegsalarm")
    }
}
