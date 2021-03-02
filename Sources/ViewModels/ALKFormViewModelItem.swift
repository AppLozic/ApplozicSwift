//
//  ALKFormViewModelItem.swift
//  ApplozicSwift
//
//  Created by Mukesh on 08/07/20.
//

import Foundation

enum FormViewModelItemType {
    case text
    case password
    case singleselect
    case multiselect
    case date
    case time
    case dateTimeLocal
}

protocol FormViewModelItem {
    var type: FormViewModelItemType { get }
    var sectionTitle: String { get }
    var rowCount: Int { get }
}

extension FormViewModelItem {
    var rowCount: Int {
        return 1
    }

    var sectionTitle: String {
        return ""
    }
}

class FormViewModelSingleselectItem: FormViewModelItem {
    typealias Option = FormTemplate.Option
    var type: FormViewModelItemType {
        return .singleselect
    }

    var title: String
    var name: String
    var options: [Option]
    var sectionTitle: String {
        return title
    }

    var selectedValue: String?
    var rowCount: Int {
        return options.count
    }

    init(name: String, title: String, options: [Option]) {
        self.name = name
        self.title = title
        self.options = options
    }
}

class FormViewModelMultiselectItem: FormViewModelItem {
    typealias Option = FormTemplate.Option
    var type: FormViewModelItemType {
        return .multiselect
    }

    var title: String
    var name: String
    var options: [Option]
    var sectionTitle: String {
        return title
    }

    var rowCount: Int {
        return options.count
    }

    init(name: String, title: String, options: [Option]) {
        self.name = name
        self.title = title
        self.options = options
    }
}

class FormViewModelTextItem: FormViewModelItem {
    typealias Validation = FormTemplate.Validation
    var type: FormViewModelItemType {
        return .text
    }

    let label: String
    let placeholder: String?
    let validation: Validation?

    init(label: String,
         placeholder: String?,
         validation: Validation?)
    {
        self.label = label
        self.placeholder = placeholder
        self.validation = validation
    }
}

class FormViewModelPasswordItem: FormViewModelItem {
    var type: FormViewModelItemType {
        return .password
    }

    let label: String
    let placeholder: String?

    init(label: String, placeholder: String?) {
        self.label = label
        self.placeholder = placeholder
    }
}

class FormViewModelDateItem: FormViewModelItem {
    var type: FormViewModelItemType {
        return .date
    }

    let label: String
    init(label: String) {
        self.label = label
    }
}

class FormViewModelDateTimeLocalItem: FormViewModelItem {
    var type: FormViewModelItemType {
        return .dateTimeLocal
    }

    let label: String
    init(label: String) {
        self.label = label
    }
}

class FormViewModelTimeItem: FormViewModelItem {
    var type: FormViewModelItemType {
        return .time
    }

    let label: String
    init(label: String) {
        self.label = label
    }
}

extension FormTemplate {
    var viewModeItems: [FormViewModelItem] {
        var items: [FormViewModelItem] = []
        elements.forEach { element in
            switch element.contentType {
            case .text:
                guard let elementData = element.data,
                      let label = elementData.label,
                      let placeHolder = elementData.placeholder else { return }
                items.append(FormViewModelTextItem(
                    label: label,
                    placeholder: placeHolder,
                    validation: elementData.validation
                ))
            case .password:
                guard let elementData = element.data,
                      let label = elementData.label,
                      let placeHolder = elementData.placeholder else { return }
                items.append(FormViewModelPasswordItem(
                    label: label,
                    placeholder: placeHolder
                ))
            case .singleSelect:
                guard let elementData = element.data,
                      let title = elementData.title,
                      let options = elementData.options,
                      let name = elementData.name else { return }
                items.append(FormViewModelSingleselectItem(name: name,
                                                           title: title,
                                                           options: options))
            case .multiselect:
                guard let elementData = element.data,
                      let title = elementData.title,
                      let options = elementData.options,
                      let name = elementData.name else { return }
                items.append(FormViewModelMultiselectItem(name: name,
                                                          title: title,
                                                          options: options))
            case .time:
                guard let elementData = element.data,
                      let label = elementData.label else { return }
                items.append(FormViewModelTimeItem(label: label))
            case .date:
                guard let elementData = element.data,
                      let label = elementData.label else { return }
                items.append(FormViewModelDateItem(label: label))
            case .dateTimeLocal:
                guard let elementData = element.data,
                      let label = elementData.label else { return }
                items.append(FormViewModelDateTimeLocalItem(label: label))
            default:
                print("\(element.contentType) form template type is not part of the form list view")
            }
        }
        return items
    }

    var submitButtonTitle: String? {
        guard let submitButton = elements
            .filter({ $0.contentType == .submit })
            .first, let submitButtonData = submitButton.data,
            let buttonName = submitButtonData.name else { return nil }
        return buttonName
    }
}
