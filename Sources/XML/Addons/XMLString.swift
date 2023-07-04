//
//  XMLString.swift
//  
//
//  Created by John Jakobsen on 5/21/23.
//

import Foundation
import SWXMLHash
import StreamCiphers

enum XMLStringError: Error {
    case StringToDataNil
    case UnableToBase64Decode
    case DecryptedStringNil
    case DataToStringNil
    
}

struct XMLString: XMLValueDeserialization, Serializable {
    public let content: String
    public let name: String
    public let properties: [String: XMLAttribute]?
    
    static func deserialize(_ element: SWXMLHash.XMLElement) throws -> XMLString {
        return XMLString(content: element.text, name: element.name, properties: element.allAttributes)
    }
    static func deserialize(_ attribute: SWXMLHash.XMLAttribute) throws -> XMLString {
        return XMLString(content: attribute.text, name: attribute.name, properties: nil)
    }
    static func deserialize(_ element: SWXMLHash.XMLElement, base64Encoded: Bool = false, streamCipher: StreamCipher? = nil) throws -> XMLString {
        
        guard var valData = element.text.data(using: .utf8) else {
            throw XMLStringError.StringToDataNil
        }
        
        if (base64Encoded) {
            guard let base64Decoded = Data(base64Encoded: element.text) else {
                throw XMLStringError.UnableToBase64Decode
            }
            valData = base64Decoded
        }
        let protected: Bool? = element.value(ofAttribute: "Protected")
        if (streamCipher != nil && protected ?? false) {
            guard let decryptedData = try streamCipher?.decrypt(encryptedData: valData) else {
                throw XMLStringError.DecryptedStringNil
            }
            valData = decryptedData
        }
        guard let strVal = String(data: valData, encoding: .utf8) else {
            throw XMLStringError.DataToStringNil
        }
        return XMLString(content: strVal, name: element.name, properties: element.allAttributes)
    }
    
    private func propertiesXMLize() -> String {

        guard let p = properties, !p.isEmpty else {
            return ""
        }
        return " " + String(p.map { (key, value) in
            return "\(key)=\"\(value.text)\""
        }.joined(separator: " "))
    }
    
    public func serialize(base64Encoded: Bool = false, streamCipher: StreamCipher? = nil) throws -> String {
        
        guard var strData = content.data(using: .utf8) else {
            throw XMLStringError.StringToDataNil
        }
        
        if let cipher = streamCipher, (properties?["Protected"]?.text ?? "False") == "True" {
            strData = try cipher.encrypt(data: strData)
        }
        
        if (base64Encoded) {
            strData = strData.base64EncodedData()
        }
        
        guard let valString = String(data: strData, encoding: .utf8) else {
            throw KeyValError.DataToStringNil
        }
        
        return """
            <\(name)\(propertiesXMLize())>\(valString)</\(name)>
            """
    }
}
