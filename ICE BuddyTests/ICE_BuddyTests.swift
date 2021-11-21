//
//  ICE_BuddyTests.swift
//  ICE BuddyTests
//
//  Created by Frederik Riedel on 16.11.21.
//

import XCTest
@testable import ICE_Buddy

class ICE_BuddyTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTriebzugNummern() throws {
        let tz240 = TrainType.trainType(from: "Tz240")
        XCTAssertEqual(tz240, .BR402)
        
        let tz9453 = TrainType.trainType(from: "Tz9453")
        XCTAssertEqual(tz9453, .BR412)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
