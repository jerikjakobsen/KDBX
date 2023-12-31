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

@available(iOS 15.0, *)
@available(macOS 13.0, *)
public final class KeyValXML: NSObject, XMLObjectDeserialization, Serializable, ModifyListener, NSCopying {
    public var key: XMLString
    public var value: XMLString
    public let name: String
    internal var modifyListener: ModifyListener? = nil
    
    public init(key: String, value: String, name: String = "String", protected: Bool = false) {
        self.key = XMLString(value: key, name: "Key")
        self.value = XMLString(value: value, name: "Value", properties: protected ? ["Protected": "True"] : [:])
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
    
    public static func deserialize(_ element: XMLIndexer) throws -> KeyValXML {
        return KeyValXML(
            key: try element["Key"].value(),
            value: try element["Value"].value(),
            name: element.element?.name ?? "String")
    }
    
    private static func isBase64Encoded(key: String) -> Bool {
        return key == "Password" || key.contains("Time")
    }
    
    public static func deserialize(_ element: XMLIndexer, streamCipher: StreamCipher? = nil) throws -> KeyValXML {
        guard let keyElement = element["Key"].element else {
            throw KeyValError.UnableToGetKey
        }
        
        guard let valElement = element["Value"].element else {
            throw KeyValError.UnableToGetValue
        }
        let key: XMLString = try XMLString.deserialize(keyElement)
        
        let val: XMLString = try XMLString.deserialize(valElement, base64Encoded: isBase64Encoded(key: key.value), streamCipher: streamCipher)
        
        return KeyValXML(
            key: key,
            value: val,
            name: element.element?.name ?? "String")
    }
    
    public func serialize(base64Encoded: Bool = false, streamCipher: StreamCipher? = nil) throws -> String {
        let b64encoded = base64Encoded || KeyValXML.isBase64Encoded(key: key.value)
        
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
    
    public func isEqual(_ object: KeyValXML?) -> Bool {
        guard let notNil = object else {
            return false
        }
        return notNil.key.isEqual(key) && notNil.value.isEqual(value) && notNil.name == name
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return KeyValXML(key: self.key.copy() as! XMLString, value: self.value.copy() as! XMLString, name: self.name)
    }
}

@available(iOS 15.0, *)
@available(macOS 13.0, *)
extension KeyValXML: CustomStringConvertible {
    public override var description: String {
        return "\(key): \(value)"
    }
}
