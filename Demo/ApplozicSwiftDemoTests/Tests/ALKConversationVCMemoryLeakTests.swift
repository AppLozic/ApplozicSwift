//
//  ALKConversationVCMemoryLeakTests.swift
//  ApplozicSwiftDemoTests
//
//  Created by Mukesh on 31/12/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import Nimble
import Quick
@testable import ApplozicSwift

class ALKConversationVCMemoryLeakTests: QuickSpec {
    override func spec() {
        var conversationVC: ALKConversationViewControllerMock?
        var isDeinitCalled: Bool = false

        describe("when ALKConversationViewController is dismissed") {
            beforeEach {
                waitUntil(timeout: DispatchTimeInterval.seconds(5)) { done in
                    conversationVC = ALKConversationViewControllerMock(configuration: ALKConfiguration(), individualLaunch: true)
                    conversationVC?.viewModel = ALKConversationViewModel(contactId: "000", channelKey: nil, localizedStringFileName: ALKConfiguration().localizedStringFileName)
                    conversationVC?.contactService = ALContactServiceMock()
                    conversationVC?.onDeinitialized = {
                        done()
                        isDeinitCalled = true
                    }

                    let testUtil = ViewControllerTestUtil<ALKConversationViewController>()
                    testUtil.setupTopLevelUI(withViewController: conversationVC!)
                    testUtil.tearDownTopLevelUI()
                    conversationVC = nil
                }
            }
            it("calls deinit") {
                expect(isDeinitCalled).to(beTrue())
            }
        }
    }
}
