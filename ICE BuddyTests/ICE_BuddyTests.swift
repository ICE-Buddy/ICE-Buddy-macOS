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
        
        let tz_9453 = TrainType.trainType(from: "Tz 9453")
        XCTAssertEqual(tz_9453, .BR412)
        
        let ICE0334 = TrainType.trainType(from: "ICE0334")
        XCTAssertEqual(ICE0334, .BR403)
        
        let ICE1159 = TrainType.trainType(from: "ICE1159")
        XCTAssertEqual(ICE1159, .BR411)
    }

}
