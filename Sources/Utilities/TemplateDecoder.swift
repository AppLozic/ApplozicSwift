//
//  TemplateDecoder.swift
//  ApplozicSwift
//
//  Created by Mukesh on 28/04/19.
//

import Foundation

/// An error that occurs when decoding a template.
enum TemplateDecodingError: Error {
    case payloadMissing
}

/// A type that decodes a template(payload) from ALMessage's metadata.
enum TemplateDecoder {
    /// Decodes a Template from the metadata.
    /// - parameter metadata: Metadata present in the `ALMessage` which contains the `payload`.
    /// - throws: `TemplateDecodingError.payloadMissing` if the payload key is not present or if it doesn't contain a `String`.
    /// - throws: An error if any value throws an error during decoding.
    static func decode<T>(_ to: T.Type, from metadata: [String: Any]) throws -> T where T: Decodable {
        guard let payload = metadata["payload"] as? String
        else {
            throw TemplateDecodingError.payloadMissing
        }
        do {
            let template = try JSONDecoder().decode(to, from: payload.data)
            return template
        } catch {
            throw error
        }
    }
}
