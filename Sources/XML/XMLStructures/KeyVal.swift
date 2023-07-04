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
    case DataToStringNil
}

public struct KeyVal: XMLObjectDeserialization, Serializable {
    let key: XMLString
    let value: XMLString
    public let name: String
    
    public static func new(key: String, value: String, protected: Bool) -> KeyVal {
        let keyXMLString = XMLString(content: key, name: "Key", properties: nil)
        let valueXMLString = XMLString(content: value, name: "Value", properties: protected ? ["Protected": "True"] : nil)
        return KeyVal(key: keyXMLString, value: valueXMLString, name: "String")
    }
    
    public static func deserialize(_ element: XMLIndexer) throws -> KeyVal {
        return try KeyVal(
            key: element["Key"].value(),
            value: element["Value"].value(),
            name: element.element?.name ?? "String")
    }
    
    private static func isBase64Encoded(key: String) -> Bool {
        return key == "Password" || key.contains("Time")
    }
    
    public static func deserialize(_ element: XMLIndexer, streamCipher: StreamCipher? = nil) throws -> KeyVal {
        guard let keyElement = element["Key"].element else {
            throw KeyValError.UnableToGetKey
        }
        
        guard let valElement = element["Value"].element else {
            throw KeyValError.UnableToGetValue
        }
        let key: XMLString = try XMLString.deserialize(keyElement, streamCipher: streamCipher)
        
        let val: XMLString = try XMLString.deserialize(valElement, base64Encoded: isBase64Encoded(key: key.content), streamCipher: streamCipher)
        
        return KeyVal(
            key: key,
            value: val,
            name: element.element?.name ?? "String")
    }
    
    public func serialize(base64Encoded: Bool = false, streamCipher: StreamCipher? = nil) throws -> String {
        let b64encoded = base64Encoded || KeyVal.isBase64Encoded(key: key.content)
        
        return try """
            <\(name)>
                    \(key.serialize())
                    \(value.serialize(base64Encoded: b64encoded, streamCipher: streamCipher))
            </\(name)>
            """
    }
    
    public func modify(newKey: String? = nil, newValue: String? = nil ) -> KeyVal {
        if (newKey == nil && newValue == nil) {
            return self
        }
        return KeyVal(key: self.key.modify(content: newKey), value: self.value.modify(content: newValue), name: self.name)
    }
}
