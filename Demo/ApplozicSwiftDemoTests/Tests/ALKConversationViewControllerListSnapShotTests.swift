//
//  ALKConversationViewControllerUITests.swift
//  ApplozicSwiftDemoTests
//
//  Created by Mukesh Thawani on 17/06/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import ApplozicCore
import Nimble
import Nimble_Snapshots
import Quick
@testable import ApplozicSwift

class ALKConversationViewControllerListSnapShotTests: QuickSpec {
    override func spec() {
        describe("Conversation list") {
            var conversationVC: ALKConversationListViewController!
            var navigationController: UINavigationController!

            beforeEach {
                conversationVC = ALKConversationListViewController(configuration: ALKConfiguration())
                ALMessageDBServiceMock.lastMessage.createdAtTime = NSNumber(value: Date().timeIntervalSince1970 * 1000)
                conversationVC.dbService = ALMessageDBServiceMock()
                let firstMessage = MockMessage().message
                firstMessage.message = "first message"
                let secondmessage = MockMessage().message
                secondmessage.message = "second message"
                ALKConversationViewModelMock.testMessages = [firstMessage.messageModel, secondmessage.messageModel]
                conversationVC.conversationViewModelType = ALKConversationViewModelMock.self
                navigationController = ALKBaseNavigationViewController(rootViewController: conversationVC)
                conversationVC.beginAppearanceTransition(true, animated: false)
                conversationVC.endAppearanceTransition()
            }

            it("Show list") {
                XCTAssertNotNil(navigationController.view)
                XCTAssertNotNil(conversationVC.view)
                expect(navigationController).to(haveValidSnapshot())
            }

            it("Open chat thread") {
                XCTAssertNotNil(conversationVC.tableView)
                let tableView = conversationVC.tableView
                tableView.delegate?.tableView?(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
                XCTAssertNotNil(conversationVC.navigationController?.view)
                expect(conversationVC.navigationController).toEventually(haveValidSnapshot())
            }
        }

        context("Conversation list screen") {
            var conversationVC: ALKConversationListViewController!
            var navigationController: UINavigationController!

            beforeEach {
                conversationVC = ALKConversationListViewController(configuration: ALKConfiguration())
                let mockMessage = ALMessageDBServiceMock.lastMessage!
                mockMessage.message = "Re: Subject"
                mockMessage.contentType = Int16(ALMESSAGE_CONTENT_TEXT_HTML)
                mockMessage.source = 7
                mockMessage.createdAtTime = NSNumber(value: Date().timeIntervalSince1970 * 1000)
                conversationVC.dbService = ALMessageDBServiceMock()
                navigationController = ALKBaseNavigationViewController(rootViewController: conversationVC)
            }

            it("show email thread") {
                expect(navigationController).to(haveValidSnapshot())
            }
        }

        describe("configure right nav bar icon") {
            var configuration: ALKConfiguration!
            var conversationVC: ALKConversationListViewController!
            var navigationController: UINavigationController!

            beforeEach {
                configuration = ALKConfiguration()
                configuration.hideStartChatButton = true
                configuration.navigationItemsForConversationList = [
                    ALKNavigationItem(
                        identifier: 123_456,
                        icon: UIImage(named: "close", in: Bundle.applozic, compatibleWith: nil)!
                    ),
                ]
                conversationVC = ALKConversationListViewController(configuration: configuration)
                conversationVC.dbService = ALMessageDBServiceMock()
                conversationVC.conversationViewModelType = ALKConversationViewModelMock.self
                conversationVC.beginAppearanceTransition(true, animated: false)
                conversationVC.endAppearanceTransition()

                navigationController = ALKBaseNavigationViewController(rootViewController: conversationVC)
                navigationController.navigationBar.isTranslucent = false
                navigationController.navigationBar.tintColor = UIColor(red: 0.10, green: 0.65, blue: 0.89, alpha: 1.0)
                if #available(iOS 13.0, *) {
                    let appearance = UINavigationBarAppearance()
                    appearance.backgroundColor = UIColor(red: 0.93, green: 0.94, blue: 0.95, alpha: 1.0)
                    navigationController.navigationBar.standardAppearance = appearance
                } else {
                    navigationController.navigationBar.barTintColor = UIColor(red: 0.93, green: 0.94, blue: 0.95, alpha: 1.0)
                }
            }

            it("change icon image") {
                navigationController.navigationBar.snapshotView(afterScreenUpdates: true)
                expect(navigationController.navigationBar).to(haveValidSnapshot())
            }
        }
    }

    func getApplicationKey() -> NSString {
        let appKey = ALUserDefaultsHandler.getApplicationKey() as NSString?
        let applicationKey = appKey
        return applicationKey!
    }
}
