//
//  SentMessageView.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 21/01/19.
//

import UIKit

/// Message view for sender side.
///
/// It contains `MessageView`, time and message status(pending/sent/delivered).
/// It also contains `Config` which is used to configure views properties. It can be changed from outside.
/// - NOTE: Padding for message will be passed from outside. Time and status will be shown to the left of view with default padding.
public class SentMessageView: UIView {
    // MARK: Public properties

    /// Configuration to change width height and padding of views inside SentMessageView.
    public enum Config {
        public enum MessageView {
            /// Left padding of `MessageView` from `TimeLabel`
            public static var leftPadding: CGFloat = 2.0
            /// Bottom padding of `MessageView` from `TimeLabel`
            public static var bottomPadding: CGFloat = 2.0
        }
    }

    // MARK: Fileprivate Properties

    fileprivate lazy var messageView = MessageView(
        bubbleStyle: MessageTheme.sentMessage.bubble,
        messageStyle: MessageTheme.sentMessage.message,
        maxWidth: maxWidth
    )

    fileprivate var padding: Padding
    fileprivate var maxWidth: CGFloat

    // MARK: Initializers

    /// Initializer for message view.
    ///
    /// - Parameters:
    ///   - frame: It's used to set message frame.
    ///   - padding: Padding for view.
    ///   - maxWidth: Maximum width to constrain view. USe same in rowHeight method.
    public init(frame: CGRect, padding: Padding, maxWidth: CGFloat) {
        self.padding = padding
        self.maxWidth = maxWidth
        super.init(frame: frame)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public methods

    /// It updates the message view using `MessageModel`. Sets message text, time, status.
    ///
    /// - Parameters:
    ///   - model: Model containing information to update view.
    public func update(model: Message) {
        /// Set frame
        let height = SentMessageView.rowHeight(model: model, maxWidth: maxWidth, padding: padding)
        frame.size = CGSize(width: maxWidth, height: height)

        // Set message
        messageView.update(model: model)
    }

    /// It's used to get exact height of messageView.
    ///
    /// - NOTE: Font parameter is not used.
    /// - Parameters:
    ///   - model: Model used to update view.
    ///   - maxWidth: maxmimum allowable width for view.
    ///   - padding: padding for view. Use the same passsed while initializing.
    /// - Returns: Exact height of view.
    public static func rowHeight(model: Message, maxWidth: CGFloat, font _: UIFont = UIFont(), padding: Padding?) -> CGFloat {
        guard let padding = padding else {
            print("❌❌❌ Padding is not passed from outside. Use same passed in initialization. ❌❌❌")
            return 0
        }
        return SentMessageViewSizeCalculator().rowHeight(messageModel: model, maxWidth: maxWidth, padding: padding)
    }

    // MARK: Private methods

    private func setupConstraints() {
        addViewsForAutolayout(views: [messageView])
        NSLayoutConstraint.activate([
            messageView.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
            messageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1 * padding.right),
            messageView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: Config.MessageView.leftPadding),
            messageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1 * Config.MessageView.bottomPadding),
        ])
    }

    func updateHeightOfView(hideView: Bool, model: Message) {
        messageView.updateHeighOfView(hideView: hideView, model: model)
    }
}
