//
//  ImageMessageStyle.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 05/02/19.
//

import Foundation

public struct ImageBubbleStyle {
    /// Style for caption text
    public var captionStyle = Style(
        font: UIFont.systemFont(ofSize: 12),
        text: UIColor.darkText
    )

    /// Style for image bubble
    public var bubble = MessageBubbleStyle(color: UIColor.lightGray,
                                           cornerRadius: 5,
                                           padding: Padding(left: 8, right: 8, top: 8, bottom: 8))

    /// This is used to calculate image width.
    ///
    /// imageWidth = widthRatio * maxWidth(passed while initialization)
    /// - Warning: Use value between 0 and 1.
    public var widthRatio: CGFloat = 0.48

    /// This is used to calculate image height.
    ///
    /// imageHeight = heightRatio * maxWidth(passed while initialization)
    /// - Warning: Use value between 0 and 1.
    public var heightRatio: CGFloat = 0.50

    public init() {}
}

public enum ImageBubbleTheme {
    /// `ImageBubbleStyle` for sent message
    public static var sentMessage = ImageBubbleStyle()

    /// `ImageBubbleStyle` for received message
    public static var receivedMessage = ImageBubbleStyle()
}
