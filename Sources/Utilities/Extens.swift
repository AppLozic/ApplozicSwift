//
//  Font.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import UIKit

public enum Font {
    case ultraLight(size: CGFloat)
    case ultraLightItalic(size: CGFloat)

    case thin(size: CGFloat)
    case thinItalic(size: CGFloat)

    case light(size: CGFloat)
    case lightItalic(size: CGFloat)

    case medium(size: CGFloat)
    case mediumItalic(size: CGFloat)

    case normal(size: CGFloat)
    case italic(size: CGFloat)

    case bold(size: CGFloat)
    case boldItalic(size: CGFloat)

    case condensedBlack(size: CGFloat)
    case condensedBold(size: CGFloat)

    public func font() -> UIFont {
        var option: String = ""
        var fontSize: CGFloat = 0

        switch self {
        case let .ultraLight(size): option = "-UltraLight"
            fontSize = size

        case let .ultraLightItalic(size): option = "-UltraLightItalic"
            fontSize = size

        case let .thin(size): option = "-Thin"
            fontSize = size

        case let .thinItalic(size): option = "-ThinItalic"
            fontSize = size

        case let .light(size): option = "-Light"
            fontSize = size

        case let .lightItalic(size): option = "-LightItalic"
            fontSize = size

        case let .medium(size): option = "-Medium"
            fontSize = size

        case let .mediumItalic(size): option = "-MediumItalic"
            fontSize = size

        case let .normal(size): option = ""
            fontSize = size

        case let .italic(size): option = "-Italic"
            fontSize = size

        case let .bold(size): option = "-Bold"
            fontSize = size

        case let .boldItalic(size): option = "-BoldItalic"
            fontSize = size

        case let .condensedBlack(size): option = "-CondensedBlack"
            fontSize = size

        case let .condensedBold(size): option = "-CondensedBold"
            fontSize = size
        }

        return UIFont(name: "HelveticaNeue\(option)", size: CGFloat(fontSize)) ?? UIFont.systemFont(ofSize: fontSize)
    }
}

public enum Color {
    public enum Text: Int64 {
        case white = 0xFFFF_FFFF
        case main = 0xFFE0_0909
        case redC0 = 0xFFF7_C0C0
        case grayCC = 0xFFCC_CCCC
        case gray9B = 0xFF9B_9B9B
        case grayC1 = 0xFFC1_C1C1
        case gray66 = 0xFF66_6666
        case gray99 = 0xFF99_9999
        case blueFF = 0xFF00_7AFF
        case black00 = 0xFF00_0000
        case grayD4 = 0xC3CDD4
        case gray7E = 0xFF67_757E
    }

    public enum Background: Int64 {
        case none = 0x00FF_FFFF
        case white = 0xFFFF_FFFF
        case main = 0xFFE0_0909
        case redC0 = 0xFFF7_C0C0
        case gray9B = 0xFF9B_9B9B
        case grayF2 = 0xFFF2_F2F2
        case grayEF = 0xFFEF_EFEF
        case grayC1 = 0xFFC1_C1C1
        case gray99 = 0xFF99_9999
        case grayEC = 0xFFEC_ECEC
        case grayCC = 0xFFCC_CCCC
        case gray66 = 0xFF66_6666
        case grayF1 = 0xFFF1_F1F1
    }

    public enum Border: Int64 {
        case main = 0xFFE0_0909
        case redC0 = 0xFFF7_C0C0

        case white = 0xFFFF_FFFF
        case black = 0xF_F900_0000

        case gray9B = 0xFF9B_9B9B
        case grayF2 = 0xFFF2_F2F2
        case grayEF = 0xFFEF_EFEF
        case grayC1 = 0xFFC1_C1C1
        case gray99 = 0xFF99_9999
    }
}

public extension UIFont {
    static func font(_ font: Font) -> UIFont {
        return font.font()
    }
}

public extension UIColor {
    static func text(_ color: Color.Text) -> UIColor {
        return .hex8(color.rawValue)
    }

    static func background(_ color: Color.Background) -> UIColor {
        return .hex8(color.rawValue)
    }

    static func border(_ color: Color.Border) -> UIColor {
        return .hex8(color.rawValue)
    }

    static func color(_ color: Color.Text) -> UIColor {
        return .hex8(color.rawValue)
    }

    static func color(_ color: Color.Background) -> UIColor {
        return .hex8(color.rawValue)
    }

    static func color(_ color: Color.Border) -> UIColor {
        return .hex8(color.rawValue)
    }
}
