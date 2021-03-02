//
//  RichMessageStyle.swift
//  ApplozicSwift
//
//  Created by Sunil on 28/05/20.
//

import Foundation

protocol ColorProtocol {
    static func setPrimaryColor(primaryColor: UIColor)
}

public extension CurvedImageButton {
    struct QuickReplyButtonStyle: ColorProtocol {
        static var shared = QuickReplyButtonStyle()

        static func setPrimaryColor(primaryColor: UIColor) {
            QuickReplyButtonStyle.shared.setColor(primaryColor)
        }

        mutating func setColor(_ color: UIColor) {
            buttonColor.border = color.cgColor
            buttonColor.text = color
            buttonColor.tint = color
        }

        struct Color {
            /// Used for text color
            var text = UIColor(red: 85, green: 83, blue: 183)

            /// Used for border color of view
            var border = UIColor(red: 85, green: 83, blue: 183).cgColor

            /// Used for background color of view
            var background = UIColor.clear

            /// Used for tint color of image
            var tint = UIColor(red: 85, green: 83, blue: 183)
        }

        /// Font for text inside view.
        public var font = UIFont.systemFont(ofSize: 14)

        /// Corner radius of view.
        public var cornerRadius: CGFloat = 15

        /// Border width of view.
        public var borderWidth: CGFloat = 2

        /// Instance of `Color` type that can be used to change the colors used in view.
        var buttonColor = Color()
    }
}
