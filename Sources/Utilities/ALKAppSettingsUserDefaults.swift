//
//  ALKAppSettingsUserDefaults.swift
//  ApplozicSwift
//
//  Created by Sunil on 29/04/20.
//

import Foundation
/// `ALKAppSettingsUserDefaults` is used for handling the app settings and storing the data
public struct ALKAppSettingsUserDefaults {
    // MARK: - Internal properties

    let navigationBarProxy = UINavigationBar.appearance(whenContainedInInstancesOf: [ALKBaseNavigationViewController.self])

    let appSettingsKey = "ALK_APP_SETTINGS"

    // MARK: - Public Initialization

    public init() {}

    // MARK: - Public methods

    /// Primary color of the app
    public func getAppPrimaryColor() -> UIColor {
        if let appSettings = getAppSettings() {
            return UIColor(hexString: appSettings.primaryColor)
        }
        return UIColor.navigationOceanBlue()
    }

    /// This method is used for set the primary color of app
    public func setAppPrimaryColorColor(color: UIColor) {
        var appSettings = getAppSettings()

        if appSettings == nil {
            appSettings = ALKAppSettings(primaryColor: color.toHexString())
        }

        guard let settings = appSettings else {
            return
        }

        settings.primaryColor = color.toHexString()
        setAppSettings(appSettings: settings)
    }

    /// App navigation bar tint color
    public func getAppBarTintColor() -> UIColor {
        if let barTintColor = navigationBarProxy.barTintColor {
            return barTintColor
        }
        return getAppPrimaryColor()
    }

    /// This method is used for set the sent message background color
    public func setSentMessageBackgroundColor(color: UIColor) {
        let appSettings = getDefaultAppSettings()
        appSettings.sentMessageBackgroundColor = color.toHexString()
        setAppSettings(appSettings: appSettings)
    }

    /// Sent message background color
    public func getSentMessageBackgroundColor() -> UIColor {
        if let appSettings = getAppSettings(), let sentMessageBackgroundColor = appSettings.sentMessageBackgroundColor {
            return UIColor(hexString: sentMessageBackgroundColor)
        }
        return ALKMessageStyle.sentBubble.color
    }

    /// Attachment icons tint color
    public func getAttachmentIconsTintColor() -> UIColor {
        if let existingAppSettings = getAppSettings(), let attachmentIconsTintColor = existingAppSettings.attachmentIconsTintColor {
            return UIColor(hexString: attachmentIconsTintColor)
        }
        return UIColor.gray
    }

    /// This method is used for to set a attachmentIcons tint color
    public func setAttachmentIconsTintColor(color: UIColor) {
        let appSettings = getDefaultAppSettings()
        appSettings.attachmentIconsTintColor = color.toHexString()
        setAppSettings(appSettings: appSettings)
    }

    /// This method is used for to set received message background color
    public func setReceivedMessageBackgroundColor(color: UIColor) {
        let appSettings = getDefaultAppSettings()
        appSettings.receivedMessageBackgroundColor = color.toHexString()
        setAppSettings(appSettings: appSettings)
    }

    /// Received message background color
    public func getReceivedMessageBackgroundColor() -> UIColor {
        if let appSettings = getAppSettings(), let receivedMessageBackgroundColor = appSettings.receivedMessageBackgroundColor {
            return UIColor(hexString: receivedMessageBackgroundColor)
        }
        return ALKMessageStyle.receivedBubble.color
    }

    /// This method is used to set the button primary color in rich messages
    public func setButtonPrimaryColor(color: UIColor) {
        let appSettings = getDefaultAppSettings()
        appSettings.buttonPrimaryColor = color.toHexString()
        setAppSettings(appSettings: appSettings)
    }

    /// Button primary color
    public func getButtonPrimaryColor() -> UIColor {
        if let appSettings = getAppSettings(),
           let buttonPrimaryColor = appSettings.buttonPrimaryColor
        {
            return UIColor(hexString: buttonPrimaryColor)
        }
        return UIColor.actionButtonColor()
    }

    /// If you want to override all the app settings then you can use this method.
    public func setAppSettings(appSettings: ALKAppSettings) {
        let data = NSKeyedArchiver.archivedData(withRootObject: appSettings)
        UserDefaults.standard.set(data, forKey: appSettingsKey)
    }

    /// This method will be used to set app settings from outside for set primary color, sent message, received message etc.
    public func updateOrSetAppSettings(appSettings: ALKAppSettings) {
        let existingAppSettings = getAppSettings()

        if existingAppSettings == nil {
            setAppSettings(appSettings: appSettings)
        } else {
            /// Keep the sent message or received message background color . If some one set from MessageStyle
            if let settings = existingAppSettings,
               let existingSentMessageBackgroundColor = settings.sentMessageBackgroundColor
            {
                appSettings.sentMessageBackgroundColor = existingSentMessageBackgroundColor
            }

            if let settings = existingAppSettings,
               let existingReceivedMessageBackgroundColor = settings.receivedMessageBackgroundColor
            {
                appSettings.receivedMessageBackgroundColor = existingReceivedMessageBackgroundColor
            }

            if let settings = existingAppSettings,
               let existingButtonPrimaryColor = settings.buttonPrimaryColor
            {
                appSettings.buttonPrimaryColor = existingButtonPrimaryColor
            }
            setAppSettings(appSettings: appSettings)
        }
    }

    /// This method will be used for getting the app settings data
    public func getAppSettings() -> ALKAppSettings? {
        guard let data = UserDefaults.standard.object(forKey: appSettingsKey) as? Data, let appSettings = NSKeyedUnarchiver.unarchiveObject(with: data) as? ALKAppSettings else {
            return nil
        }
        return appSettings
    }

    /// This method is used for clearing the user defaults data.
    public func clear() {
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        let keyArray = dictionary.keys
        for key in keyArray {
            if key.hasPrefix("ALK") {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    // MARK: - Private methods

    /// This method is for app settings with default primary color values init if the appSettings is nil.
    private func getDefaultAppSettings() -> ALKAppSettings {
        guard let appSettings = getAppSettings() else {
            return ALKAppSettings(primaryColor: UIColor.navigationOceanBlue().toHexString())
        }
        return appSettings
    }
}

/// `ALKAppSettings`class is used for creating a app settings details
public class ALKAppSettings: NSObject, NSCoding {
    enum CoderKey {
        static let primaryColor = "primaryColor"
        static let showPoweredBy = "showPoweredBy"
        static let secondaryColor = "secondaryColor"
        static let sentMessageBackgroundColor = "sentMessageBackgroundColor"
        static let receivedMessageBackgroundColor = "receivedMessageBackgroundColor"
        static let attachmentIconsTintColor = "attachmentIconsTintColor"
        static let buttonPrimaryColor = "buttonPrimaryColor"
    }

    var primaryColor: String

    // MARK: - Public properties

    public var showPoweredBy: Bool = false
    public var secondaryColor: String?
    public var sentMessageBackgroundColor: String?
    public var receivedMessageBackgroundColor: String?
    public var attachmentIconsTintColor: String?
    public var buttonPrimaryColor: String?

    // MARK: - Public Initialization

    public init(primaryColor: String) {
        self.primaryColor = primaryColor
    }

    public required init?(coder: NSCoder) {
        primaryColor = coder.decodeObject(forKey: CoderKey.primaryColor) as! String
        showPoweredBy = coder.decodeBool(forKey: CoderKey.showPoweredBy)
        secondaryColor = coder.decodeObject(forKey: CoderKey.secondaryColor) as? String
        sentMessageBackgroundColor = coder.decodeObject(forKey: CoderKey.sentMessageBackgroundColor) as? String
        receivedMessageBackgroundColor = coder.decodeObject(forKey: CoderKey.receivedMessageBackgroundColor) as? String
        attachmentIconsTintColor = coder.decodeObject(forKey: CoderKey.attachmentIconsTintColor) as? String
        buttonPrimaryColor = coder.decodeObject(forKey: CoderKey.buttonPrimaryColor) as? String
    }

    // MARK: - Public methods

    public func encode(with coder: NSCoder) {
        coder.encode(primaryColor, forKey: CoderKey.primaryColor)
        coder.encode(showPoweredBy, forKey: CoderKey.showPoweredBy)
        coder.encode(secondaryColor, forKey: CoderKey.secondaryColor)
        coder.encode(sentMessageBackgroundColor, forKey: CoderKey.sentMessageBackgroundColor)
        coder.encode(receivedMessageBackgroundColor, forKey: CoderKey.receivedMessageBackgroundColor)
        coder.encode(attachmentIconsTintColor, forKey: CoderKey.attachmentIconsTintColor)
        coder.encode(buttonPrimaryColor, forKey: CoderKey.buttonPrimaryColor)
    }
}
