//
//  File.swift
//  
//
//  Created by John Jakobsen on 5/18/23.
//

import Foundation
import StreamCiphers

protocol Serializable {
    func serialize(base64Encoded: Bool, streamCipher: StreamCipher?) -> String
}

extension Serializable {
    public func serialize(base64Encoded: Bool = false, streamCipher: StreamCipher? = nil) -> String {
        return serialize(base64Encoded: base64Encoded, streamCipher: streamCipher)
    }
}

extension Serializable? {
    public func serialize(base64Encoded: Bool = false, streamCipher: StreamCipher? = nil) -> String {
        if let notNil = self {
            return notNil.serialize(base64Encoded: base64Encoded, streamCipher: streamCipher)
        }
        return ""
    }
}
