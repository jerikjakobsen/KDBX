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

@available(iOS 15.0, *)
@available(macOS 13.0, *)
public final class XMLString: NSObject, XMLValueDeserialization, Serializable, NSCopying {
    
    public var value: String {
        didSet {
            self.modifyListener?.didModify(date: Date.now)
        }
    }
    public var name: String {
        didSet {
            self.modifyListener?.didModify(date: Date.now)
        }
    }
    public var properties: [String: String] = [:]
    internal var modifyListener: ModifyListener?
    
    public init(value: String, name: String, properties: [String : String] = [:]) {
        self.value = value
        self.name = name
        self.properties = properties
    }
    
    public static func deserialize(_ element: SWXMLHash.XMLElement) throws -> XMLString {
        let attributes = element.allAttributes.mapValues { attr in
            return attr.text
        }
        return XMLString(value: element.text, name: element.name, properties: attributes)
    }
    public static func deserialize(_ attribute: SWXMLHash.XMLAttribute) throws -> XMLString {
        return XMLString(value: attribute.text, name: attribute.name, properties: [:])
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
        let attributes = element.allAttributes.mapValues { attr in
            return attr.text
        }
        return XMLString(value: strVal, name: element.name, properties: attributes)
    }
    
    private func propertiesXMLize() -> String {

        guard !properties.isEmpty else {
            return ""
        }
        return " " + String(properties.map { (key, value) in
            return "\(key)=\"\(value)\""
        }.joined(separator: " "))
    }
    
    public func serialize(base64Encoded: Bool = false, streamCipher: StreamCipher? = nil) throws -> String {
        
        guard var strData = value.data(using: .utf8) else {
            throw XMLStringError.StringToDataNil
        }
        
        if let cipher = streamCipher, (properties["Protected"] ?? "False") == "True" {
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
    public func isEqual(_ object: XMLString?) -> Bool {
        guard let notNil = object else {
            return false
        }
        return notNil.value == value && notNil.name == name && notNil.properties == properties
    }
    public override var description: String {
        return "<\(name)\(propertiesXMLize())>\(value)</\(name)>"
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let propertiesCopy = self.properties
        return XMLString(value: self.value, name: self.name, properties: propertiesCopy)
    }
}
