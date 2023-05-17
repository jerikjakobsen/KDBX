//
//  KeyVal.swift
//  
//
//  Created by John Jakobsen on 5/15/23.
//

import Foundation
import SWXMLHash
import StreamCiphers

enum KeyValError: Error {
    case UnableToGetKey
    case UnableToGetValue
    case UnableToBase64Decode
    case StringToDataNil
    case DecryptedStringNil
}

public struct KeyVal: XMLObjectDeserialization {
    let key: String?
    let value: String?
    let protected: Bool?
    
    public static func deserialize(_ element: XMLIndexer) throws -> KeyVal {
        
        return try KeyVal(
            key: element["Key"].value(),
            value: element["Value"].value(),
            protected: element["Value"].element?.value(ofAttribute: "Protected"))
    }
    
    private static func isBase64Encoded(key: String) -> Bool {
        return key == "Password" || key.contains("Time")
    }
    
    public static func deserialize(_ element: XMLIndexer, streamCipher: StreamCipher? = nil) throws -> KeyVal {
        guard let key: String = try element["Key"].value() else {
            throw KeyValError.UnableToGetKey
        }
        
        guard let val: String = try element["Value"].value() else {
            throw KeyValError.UnableToGetValue
        }
        
        let protected = element["Value"].element?.value(ofAttribute: "Protected") ?? false
        
        guard var valData = val.data(using: .utf8) else {
            throw KeyValError.StringToDataNil
        }
        
        if (isBase64Encoded(key: key)) {
            guard let base64Decoded = Data(base64Encoded: val) else {
                throw KeyValError.UnableToBase64Decode
            }
            valData = base64Decoded
        }
        
        if (streamCipher != nil && protected) {
            guard let decryptedData = try streamCipher?.decrypt(encryptedData: valData) else {
                throw KeyValError.DecryptedStringNil
            }
            valData = decryptedData
        }
        let strVal = String(data: valData, encoding: .utf8)
        return KeyVal(
            key: key,
            value: strVal,
            protected: protected)
    }
}
