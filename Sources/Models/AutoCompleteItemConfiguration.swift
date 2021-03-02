//
//  AutoCompleteItemConfiguration.swift
//  ApplozicSwift
//
//  Created by Mukesh on 23/09/19.
//

import Foundation

/// AutoComplete configuration for each prefix.
public struct AutoCompleteItemConfiguration {
    /// If true then space will be added after the autocomplete text.
    /// Default value is true.
    public var addSpaceAfterInserting = true

    /// If true then the selected autocomplete item will be
    /// inserted with the prefix. Default value is true.
    public var insertWithPrefix = true

    /// If it is true, then the auto complete text won't be deleted in
    /// a single back tap and the autocompleted text can be edited
    /// by the user. Default value is false.
    ///
    /// NOTE: If this is true then adding text attributes
    /// like font, color etc. won't work properly as the
    /// content for this prefix will be treated as a normal text.
    public var allowEditingAutocompleteText = false

    /// Style for autocomplete text.
    public var textStyle: Style?

    public init() {}
}

public extension AutoCompleteItemConfiguration {
    static var memberMention: AutoCompleteItemConfiguration {
        var config = AutoCompleteItemConfiguration()
        config.textStyle = Style(
            font: UIFont.systemFont(ofSize: 14),
            text: UIColor.blue,
            background: UIColor.blue.withAlphaComponent(0.1)
        )
        return config
    }
}
