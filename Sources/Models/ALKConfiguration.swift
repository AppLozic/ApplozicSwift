//
//  ALKConfiguration.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 12/09/18.
//

import Foundation

public struct ALKConfiguration {
    
    /// If enabled then tapping on navigation bar in
    /// conversation view will open the group detail screen.
    /// - NOTE: Only works in case of groups.
    public var isTapOnNavigationBarEnabled = true
    
    /// If enabled then tapping on the user's profile
    /// icon in group chat will open a thread with that user.
    /// - NOTE: You will see the previous messages(if there are any).
    public var isProfileTapActionEnabled = true
    
    /// The background color of the ALKConversationViewController.
    public var backgroundColor = UIColor(netHex: 0xf9f9f9)
    
    /// Hides the bottom line in the navigation bar.
    /// It will be hidden in all the ViewControllers where
    /// navigation bar is visible. Default value is true.
    public var hideNavigationBarBottomLine = true
    
    /// Navigation bar's background color. It will be used in all the
    /// ViewControllers where navigation bar is visible.
    public var navigationBarBackgroundColor = UIColor.navigationOceanBlue()
    
    /// Navigation bar's tint color. It will be used in all the
    /// ViewControllers where navigation bar is visible.
    public var navigationBarItemColor = UIColor.navigationTextOceanBlue()
    
    /// ChatBar's bottom view color. This is the view which contains
    /// all the attachment and other options.
    public var chatBarAttachmentViewBackgroundColor = UIColor.background(.grayEF)
    
    /// If true then all the media options in Chat bar will be hidden.
    public var hideAllOptionsInChatBar = false
    
    //If true then audio option in chat bar will be hidden
    public var hideAudioOptionInChatBar = false
    
    //Payment related colors
    public var paymentRequested = UIColor(netHex: 0xFBB040)
    public var paymentSent = UIColor(netHex: 0xff0000)
    public var paymentReceived = UIColor(netHex: 0x1EEA00)
    public var paymentReceivedText = UIColor(netHex: 0x004B40)
    public var customPrimary = UIColor(netHex: 0x1EEA00)
    public var customPrimaryDark = UIColor(netHex: 0x004B40)
    
    public init() { }
    
}
