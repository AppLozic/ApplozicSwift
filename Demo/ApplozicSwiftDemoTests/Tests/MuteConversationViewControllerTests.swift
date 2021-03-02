//
//  MuteConversationViewControllerTests.swift
//  ApplozicSwiftDemoTests
//
//  Created by Shivam Pokhriyal on 23/10/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import ApplozicCore
import Foundation
import XCTest
@testable import ApplozicSwift

class MuteConversationViewControllerTests: XCTestCase {
    let time_8_Hour: Int64 = 8 * 60 * 60 * 1000
    let time_1_Week: Int64 = 7 * 24 * 60 * 60 * 1000
    let time_1_Year: Int64 = 365 * 24 * 60 * 60 * 1000

    var delegate: MuteableMock!
    var muteConversationVC: MuteConversationViewController!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        delegate = MuteableMock()
        muteConversationVC = MuteConversationViewController(delegate: delegate, conversation: MockMessage().message, atIndexPath: IndexPath(row: 0, section: 0), configuration: ALKConfiguration())
        muteConversationVC.setUpPickerView()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSendingMuteRequest_For_8_Hours() {
        muteConversationVC.selectPickerRow(0)
        muteConversationVC.tappedConfirm()
        XCTAssertTrue(delegate.isDelegateCalled)
        XCTAssertNotNil(delegate.time)
        XCTAssertEqual(delegate.time, time_8_Hour)
    }

    func testSendingMuteRequest_For_1_Week() {
        muteConversationVC.selectPickerRow(1)
        muteConversationVC.tappedConfirm()
        XCTAssertTrue(delegate.isDelegateCalled)
        XCTAssertNotNil(delegate.time)

        XCTAssertEqual(delegate.time, time_1_Week)
    }

    func testSendingMuteRequest_For_1_Year() {
        muteConversationVC.selectPickerRow(2)
        muteConversationVC.tappedConfirm()
        XCTAssertTrue(delegate.isDelegateCalled)
        XCTAssertNotNil(delegate.time)

        XCTAssertEqual(delegate.time, time_1_Year)
    }
}
