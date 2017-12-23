//
//  Answer.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation
import CoreLocation

protocol HTTPEncodedValue {
    func httpEncodedValue() throws -> String
}

protocol AnyAnswer : Encodable, HTTPEncodedValue {
    var key: String { get }
}

struct Answer<T> : AnyAnswer where T : Encodable, T : HTTPEncodedValue {
    var key: String
    var value: T
    func httpEncodedValue() throws -> String {
        return try value.httpEncodedValue()
    }
}

struct AnswerCodingKey : CodingKey {
    let stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    let intValue: Int? = nil
    init?(intValue: Int) {
        return nil
    }
}

extension Answer {
    func encode(to encoder: Encoder) throws {
        guard let key = AnswerCodingKey(stringValue: key) else {
            preconditionFailure()
        }
        var container = encoder.container(keyedBy: AnswerCodingKey.self)
        try container.encode(try httpEncodedValue(), forKey: key)
    }
}

extension String : HTTPEncodedValue {
    enum StringAnswerError : Error {
        case percentEncodingFailure
    }
    func httpEncodedValue() throws -> String {
        guard let encoded = self.addingPercentEncoding(withAllowedCharacters: CharacterSet()) else {
            throw StringAnswerError.percentEncodingFailure
        }
        return encoded
    }
}

extension Data : HTTPEncodedValue {
    func httpEncodedValue() throws -> String {
        return self.base64EncodedString(options: .lineLength64Characters)
    }
}

extension URL : HTTPEncodedValue {
    enum URLAnswerError : Error {
        case unsupportedURLScheme
    }
    func httpEncodedValue() throws -> String {
        guard self.isFileURL else {
            throw URLAnswerError.unsupportedURLScheme
        }
        let data = try Data(contentsOf: self)
        return data.base64EncodedString(options: .lineLength64Characters)
    }
}

extension CLLocationCoordinate2D : HTTPEncodedValue {
    func httpEncodedValue() throws -> String {
        preconditionFailure()
    }
}

extension CLLocationCoordinate2D : Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self)
    }
}
