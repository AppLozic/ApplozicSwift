//
//  ALKRichMessageStyle.swift
//  ApplozicSwift
//
//  Created by Sunil on 26/05/20.
//

import Foundation

// MARK: - ALKRichMessageStyle

public enum ALKRichMessageStyle {
    static let styles: [ColorProtocol.Type] = [
        ALKListTemplateCell.ListStyle.self,
        ALKGenericCardCell.CardStyle.self,
        CurvedImageButton.QuickReplyButtonStyle.self,
    ]

    public static var primaryColor = UIColor.actionButtonColor() {
        didSet {
            let appSettingsUserDefaults = ALKAppSettingsUserDefaults()
            appSettingsUserDefaults.setButtonPrimaryColor(color: primaryColor)
            styles.forEach {
                style in
                style.setPrimaryColor(primaryColor: primaryColor)
            }
        }
    }
}

public extension ALKListTemplateCell {
    /// `ListStyle` struct is used for config the sent and received list template color style
    struct ListStyle: ColorProtocol {
        static var shared = ListStyle()
        static func setPrimaryColor(primaryColor: UIColor) {
            ALKListTemplateCell.ListStyle.shared.setColor(primaryColor)
        }

        mutating func setColor(_ color: UIColor) {
            actionButton.text = color
        }

        /// Header  text style
        struct HeaderText {
            /// Used for text color
            var text = UIColor(red: 32, green: 31, blue: 31)
            /// Used for background color of view
            var background = UIColor.white
        }

        /// Instance of `HeaderText` type that can be used to change the colors used in view.
        var headerText = HeaderText()
        /// Action button  style
        struct ActionButton {
            /// Used for text color
            var text = UIColor(red: 85, green: 83, blue: 183)
            /// Used for background color of view
            var background = UIColor.white
        }

        /// Instance of `ActionButton` type that can be used to change the colors used in view.
        var actionButton = ActionButton()
        /// List template element view color style
        struct ListTemplateElementViewStyle {
            /// Title text color
            var titleTextColor = UIColor(red: 86, green: 84, blue: 84)
            /// Subtitle text color
            var subtitleTextColor = UIColor(red: 121, green: 116, blue: 116)
        }

        /// Instance of `ListTemplateElementViewStyle` type that can be used to change the colors used in view.
        var listTemplateElementViewStyle = ListTemplateElementViewStyle()
    }
}

public extension ALKGenericCardCell {
    /// `CardStyle` struct is used for config the sent and received  card template color style
    struct CardStyle: ColorProtocol {
        static var shared = CardStyle()
        static func setPrimaryColor(primaryColor: UIColor) {
            CardStyle.shared.setColor(primaryColor: primaryColor)
        }

        public mutating func setColor(primaryColor: UIColor) {
            actionButton.textColor = primaryColor
        }

        /// Overlay label style
        struct OverlayLabel {
            /// Used for text color
            var textColor = UIColor(red: 13, green: 13, blue: 14)
            /// Used for background color of view
            var background = UIColor.white
            /// Shadow color of the label
            var shadowColor = UIColor.black.cgColor
        }

        /// Instance of `OverlayLabel` type that can be used to change the colors used in view.
        var overlayLabel = OverlayLabel()
        /// Rating label style
        struct RatingLabel {
            /// Used for text color
            var textColor = UIColor(red: 0, green: 0, blue: 0)
        }

        /// Instance of `RatingLabel` type that can be used to change the colors used in view.
        var ratingLabel = RatingLabel()
        /// Title label style
        struct TitleLabel {
            /// Used for text color
            var textColor = UIColor(red: 20, green: 19, blue: 19)
        }

        /// Instance of `TitleLabel` type that can be used to change the colors used in view.
        var titleLabel = TitleLabel()
        /// Title label style
        struct SubtitleLabel {
            /// Used for text color
            var textColor = UIColor(red: 86, green: 84, blue: 84)
        }

        /// Instance of `SubtitleLabel` type that can be used to change the colors used in view.
        var subtitleLabel = SubtitleLabel()
        /// Description label style
        struct DescriptionLabel {
            /// Used for text color
            var textColor = UIColor(red: 121, green: 116, blue: 116)
        }

        /// Instance of `DescriptionLabel` type that can be used to change the colors used in view.
        var descriptionLabel = DescriptionLabel()
        /// ActionButton style
        struct ActionButton {
            /// Used for text color
            var textColor = UIColor(red: 85, green: 83, blue: 183)
        }

        /// Instance of `ActionButton` type that can be used to change the colors used in view.
        var actionButton = ActionButton()
    }
}
