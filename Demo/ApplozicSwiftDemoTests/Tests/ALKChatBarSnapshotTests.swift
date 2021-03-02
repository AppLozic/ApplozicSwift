//
//  ALKChatBarSnapshotTests.swift
//  ApplozicSwiftDemoTests
//
//  Created by Shivam Pokhriyal on 24/10/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import ApplozicCore
import Nimble
import Nimble_Snapshots
import Quick
@testable import ApplozicSwift

class ALKChatBarSnapshotTests: QuickSpec {
    override func spec() {
        describe("ChatBar") {
            var configuration: ALKConfiguration!
            var chatBar: ALKChatBar!
            var demoView: UIView!

            func prepareChatBar() {
                demoView.addViewsForAutolayout(views: [chatBar])
                chatBar.leadingAnchor.constraint(equalTo: demoView.leadingAnchor).isActive = true
                chatBar.trailingAnchor.constraint(equalTo: demoView.trailingAnchor).isActive = true
            }

            beforeEach {
                demoView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300))
                configuration = ALKConfiguration()
            }

            context("configure line between send icon and text view") {
                it("hides line image") {
                    configuration.hideLineImageFromChatBar = true
                    chatBar = ALKChatBar(frame: .zero, configuration: configuration)
                    prepareChatBar()
                    expect(chatBar).to(haveValidSnapshot())
                }

                it("shows line image") {
                    configuration.hideLineImageFromChatBar = false
                    chatBar = ALKChatBar(frame: .zero, configuration: configuration)
                    prepareChatBar()
                    expect(chatBar).to(haveValidSnapshot())
                }
            }

            context("configure send icon") {
                it("show send icon") {
                    configuration.hideAudioOptionInChatBar = true
                    chatBar = ALKChatBar(frame: .zero, configuration: configuration)
                    prepareChatBar()
                    expect(chatBar).to(haveValidSnapshot())
                }

                it("change send icon image") {
                    configuration.hideAudioOptionInChatBar = true
                    configuration.sendMessageIcon = UIImage(named: "close", in: Bundle.applozic, compatibleWith: nil)
                    chatBar = ALKChatBar(frame: .zero, configuration: configuration)
                    prepareChatBar()
                    expect(chatBar).to(haveValidSnapshot())
                }
            }

            context("configure attachment options") {
                it("shows all options by default") {
                    chatBar = ALKChatBar(frame: .zero, configuration: configuration)
                    prepareChatBar()
                    expect(chatBar).to(haveValidSnapshot())
                }

                it("shows all options if it's set to all") {
                    configuration.chatBar.optionsToShow = .all
                    chatBar = ALKChatBar(frame: .zero, configuration: configuration)
                    prepareChatBar()
                    expect(chatBar).to(haveValidSnapshot())
                }

                it("shows some options if it's set to some") {
                    configuration.chatBar.optionsToShow = .some([.camera, .gallery])
                    chatBar = ALKChatBar(frame: .zero, configuration: configuration)
                    prepareChatBar()
                    expect(chatBar).to(haveValidSnapshot())
                }

                it("shows blank view if zero values are passed") {
                    configuration.chatBar.optionsToShow = .some([])
                    chatBar = ALKChatBar(frame: .zero, configuration: configuration)
                    prepareChatBar()
                    expect(chatBar).to(haveValidSnapshot())
                }

                it("hides attachment view if it's set to none") {
                    configuration.chatBar.optionsToShow = .none
                    chatBar = ALKChatBar(frame: .zero, configuration: configuration)
                    prepareChatBar()
                    expect(chatBar).to(haveValidSnapshot())
                }
            }
            context("configure attachment icons") {
                let testIcon = UIImage(named: "play_icon_test", in: .test, compatibleWith: nil)

                it("updates all icons if all are set") {
                    configuration.chatBar.set(attachmentIcon: testIcon, for: .contact)
                    configuration.chatBar.set(attachmentIcon: testIcon, for: .camera)
                    configuration.chatBar.set(attachmentIcon: testIcon, for: .gallery)
                    configuration.chatBar.set(attachmentIcon: testIcon, for: .video)
                    configuration.chatBar.set(attachmentIcon: testIcon, for: .location)
                    chatBar = ALKChatBar(frame: .zero, configuration: configuration)
                    prepareChatBar()
                    expect(chatBar).to(haveValidSnapshot())
                }

                it("updates only camera icon if only camera icon is set") {
                    configuration.chatBar.set(attachmentIcon: testIcon, for: .camera)
                    chatBar = ALKChatBar(frame: .zero, configuration: configuration)
                    prepareChatBar()
                    expect(chatBar).to(haveValidSnapshot())
                }

                it("shows default icon if camera icon is set to nil") {
                    configuration.chatBar.set(attachmentIcon: nil, for: .camera)
                    chatBar = ALKChatBar(frame: .zero, configuration: configuration)
                    prepareChatBar()
                    expect(chatBar).to(haveValidSnapshot())
                }
            }
        }
    }
}

extension Bundle {
    static var test: Bundle {
        return Bundle(for: ALKChatBarSnapshotTests.self)
    }
}
