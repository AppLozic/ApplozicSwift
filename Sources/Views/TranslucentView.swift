//
//  TranslucentView.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit

@IBDesignable
open class TranslucentView: UIView {
    fileprivate var _translucent = true
    @IBInspectable open var translucent: Bool {
        set {
            _translucent = newValue
            if toolbarBG == nil {
                return
            }

            toolbarBG!.isTranslucent = newValue

            if newValue {
                toolbarBG!.isHidden = false
                toolbarBG!.barTintColor = ilColorBG
                backgroundColor = UIColor.clear
            } else {
                toolbarBG!.isHidden = true
                backgroundColor = ilColorBG
            }
        }
        get {
            return _translucent
        }
    }

    fileprivate var _translucentAlpha: CGFloat = 1.0
    @IBInspectable open var translucentAlpha: CGFloat {
        set {
            if newValue > 1 {
                _translucentAlpha = 1
            } else if newValue < 0 {
                _translucentAlpha = 0
            } else {
                _translucentAlpha = newValue
            }

            if toolbarBG != nil {
                toolbarBG!.alpha = _translucentAlpha
            }
        }
        get {
            return _translucentAlpha
        }
    }

    open var translucentStyle: UIBarStyle {
        set {
            if toolbarBG != nil {
                toolbarBG!.barStyle = newValue
            }
        }
        get {
            if toolbarBG != nil {
                return toolbarBG!.barStyle
            } else {
                return UIBarStyle.default
            }
        }
    }

    fileprivate var _translucentTintColor = UIColor.clear
    @IBInspectable open var translucentTintColor: UIColor {
        set {
            _translucentTintColor = newValue
            if isItClearColor(newValue) {
                toolbarBG!.barTintColor = ilDefaultColorBG
            } else {
                toolbarBG!.barTintColor = self.translucentTintColor
            }
        }
        get {
            return _translucentTintColor
        }
    }

    fileprivate var ilColorBG: UIColor?
    fileprivate var ilDefaultColorBG: UIColor?

    fileprivate var toolbarBG: UIToolbar?
    fileprivate var nonExistentSubview: UIView?
    fileprivate var toolbarContainerClipView: UIView?
    fileprivate var overlayBackgroundView: UIView?
    fileprivate var initComplete = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        createUI()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createUI()
    }
}

extension TranslucentView {
    // swiftlint:disable identifier_name
    private func createUI() {
        ilColorBG = backgroundColor

        translucent = true
        translucentAlpha = 1

        let _nonExistentSubview = UIView(frame: bounds)
        _nonExistentSubview.backgroundColor = UIColor.clear
        _nonExistentSubview.clipsToBounds = true
        _nonExistentSubview.autoresizingMask = [
            UIView.AutoresizingMask.flexibleBottomMargin,
            UIView.AutoresizingMask.flexibleLeftMargin,
            UIView.AutoresizingMask.flexibleRightMargin,
            UIView.AutoresizingMask.flexibleTopMargin,
        ]
        nonExistentSubview = _nonExistentSubview
        insertSubview(nonExistentSubview!, at: 0)

        let _toolbarContainerClipView = UIView(frame: bounds)
        _toolbarContainerClipView.backgroundColor = UIColor.clear
        _toolbarContainerClipView.clipsToBounds = true
        _toolbarContainerClipView.autoresizingMask = [
            UIView.AutoresizingMask.flexibleBottomMargin,
            UIView.AutoresizingMask.flexibleLeftMargin,
            UIView.AutoresizingMask.flexibleRightMargin,
            UIView.AutoresizingMask.flexibleTopMargin,
        ]
        toolbarContainerClipView = _toolbarContainerClipView
        nonExistentSubview!.addSubview(toolbarContainerClipView!)

        var rect = bounds
        rect.origin.y -= 1
        rect.size.height += 1

        let _toolbarBG = UIToolbar(frame: rect)
        _toolbarBG.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        toolbarBG = _toolbarBG

        toolbarContainerClipView!.addSubview(toolbarBG!)
        ilDefaultColorBG = toolbarBG!.barTintColor

        let _overlayBackgroundView = UIView(frame: bounds)
        _overlayBackgroundView.backgroundColor = backgroundColor
        _overlayBackgroundView.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        overlayBackgroundView = _overlayBackgroundView
        toolbarContainerClipView!.addSubview(overlayBackgroundView!)

        backgroundColor = UIColor.clear
        initComplete = true
    }

    // swiftlint:enable identifier_name

    private func isItClearColor(_ color: UIColor) -> Bool {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return red == 0.0 && green == 0.0 && blue == 0.0 && alpha == 0.0
    }

    override open var frame: CGRect {
        set {
            if self.toolbarContainerClipView == nil {
                super.frame = newValue
                return
            }

            var rect = newValue
            rect.origin = CGPoint.zero

            let width = self.toolbarContainerClipView!.frame.width
            if width > rect.width {
                rect.size.width = width
            }

            let height = self.toolbarContainerClipView!.frame.height
            if height > rect.height {
                rect.size.height = height
            }

            self.toolbarContainerClipView!.frame = rect

            super.frame = newValue
            self.nonExistentSubview!.frame = self.bounds
        }
        get {
            return super.frame
        }
    }

    override open var bounds: CGRect {
        set {
            var rect = newValue
            rect.origin = CGPoint.zero

            let width = self.toolbarContainerClipView!.bounds.width
            if width > rect.width {
                rect.size.width = width
            }

            let height = self.toolbarContainerClipView!.bounds.height
            if height > rect.height {
                rect.size.height = height
            }

            self.toolbarContainerClipView!.bounds = rect
            super.bounds = newValue
            self.nonExistentSubview!.frame = self.bounds
        }
        get {
            return super.bounds
        }
    }

    override open var backgroundColor: UIColor! {
        set {
            if self.initComplete {
                self.ilColorBG = newValue
                if self.translucent {
                    self.overlayBackgroundView!.backgroundColor = newValue
                    super.backgroundColor = UIColor.clear
                }
            } else {
                super.backgroundColor = self.ilColorBG
            }
        }
        get {
            return super.backgroundColor
        }
    }

    override open var subviews: [UIView] {
        if self.initComplete {
            var array = super.subviews as [UIView]

            var index = 0
            for view in array {
                if view == self.nonExistentSubview {
                    break
                }
                index += 1
            }

            if index < array.count {
                array.remove(at: index)
            }

            return array
        } else {
            return super.subviews
        }
    }

    override open func sendSubviewToBack(_ view: UIView) {
        if initComplete {
            insertSubview(view, aboveSubview: toolbarContainerClipView!)
        } else {
            super.sendSubviewToBack(view)
        }
    }

    override open func insertSubview(_ view: UIView, at index: Int) {
        if initComplete {
            super.insertSubview(view, at: index + 1)
        } else {
            super.insertSubview(view, at: index)
        }
    }

    override open func exchangeSubview(at index1: Int, withSubviewAt index2: Int) {
        if initComplete {
            super.exchangeSubview(at: index1 + 1, withSubviewAt: index2 + 1)
        } else {
            super.exchangeSubview(at: index1, withSubviewAt: index2)
        }
    }
}
