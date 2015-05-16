//
//  MPCGamePlayerUUID_iOSTest.swift
//  MPCTests
//
//  Created by PartyMan on 5/16/15.
//  Copyright (c) 2015 PartyLand. All rights reserved.
//

import XCTest
import SnakeCommon

class MPCGamePlayerUUID_iOSTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testReuseUniqueIDInInitialization() {
        var playerOneUUID = MPCGamePlayerUUID_iOS()
        var playerTwoUUID = MPCGamePlayerUUID_iOS()

        XCTAssertEqual(playerOneUUID.uniqueID.UUIDString, playerTwoUUID.uniqueID.UUIDString, "Ids should be the same")
    }

}