//
//  ALKContextTitleViewModel.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 05/12/17.
//

import ApplozicCore

public protocol ALKContextTitleDataType {
    var titleText: String { get }
    var subtitleText: String { get }
    var imageURL: URL? { get }
    var infoLabel1Text: String? { get }
    var infoLabel2Text: String? { get }
}

public protocol ALKContextTitleViewModelType {
    var contextViewData: ALKContextTitleDataType { get set }
    var getTitleImageURL: URL? { get }
    var getTitleText: String? { get }
    var getSubtitleText: String? { get }
    var getFirstKeyValuePairText: String? { get }
    var getSecondKeyValuePairText: String? { get }
}

open class ALKContextTitleViewModel: ALKContextTitleViewModelType {
    public var contextViewData: ALKContextTitleDataType

    public var getTitleImageURL: URL? {
        guard let imageURL = contextViewData.imageURL else {
            return nil
        }
        return imageURL
    }

    public var getTitleText: String? {
        return contextViewData.titleText
    }

    public var getSubtitleText: String? {
        return contextViewData.subtitleText
    }

    public var getFirstKeyValuePairText: String? {
        return contextViewData.infoLabel1Text
    }

    public var getSecondKeyValuePairText: String? {
        return contextViewData.infoLabel2Text
    }

    public init(data: ALKContextTitleDataType) {
        contextViewData = data
    }
}
