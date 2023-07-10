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

@available(iOS 13.0, *)
@available(macOS 13.0, *)
public final class KeyVal: NSObject, XMLObjectDeserialization, Serializable, ModifyListener {
    var key: XMLString
    var value: XMLString
    public let name: String
    internal var modifyListener: ModifyListener? = nil
    
    public init(key: String, value: String, name: String = "String", protected: Bool = false) {
        self.key = XMLString(content: key, name: "Key")
        self.value = XMLString(content: value, name: "Value", properties: protected ? ["Protected": "True"] : [:])
        self.name = name
        super.init()
        self.key.modifyListener = self
        self.value.modifyListener = self
    }
    
    internal init(key: XMLString, value: XMLString, name: String) {
        self.key = key
        self.value = value
        self.name = name
        super.init()
        self.key.modifyListener = self
        self.value.modifyListener = self
    }
    
    public static func deserialize(_ element: XMLIndexer) throws -> KeyVal {
        return KeyVal(
            key: try element["Key"].value(),
            value: try element["Value"].value(),
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
        let key: XMLString = try XMLString.deserialize(keyElement)
        
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
    
    func didModify(date: Date) {
        self.modifyListener?.didModify(date: date)
    }
    
    public func isEqual(_ object: KeyVal?) -> Bool {
        guard let notNil = object else {
            return false
        }
        return notNil.key.isEqual(key) && notNil.value.isEqual(value) && notNil.name == name
    }
}

@available(iOS 13.0, *)
@available(macOS 13.0, *)
extension KeyVal: CustomStringConvertible {
    public override var description: String {
        return "\(key): \(value)"
    }
}
