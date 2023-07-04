//
//  Meta.swift
//  
//
//  Created by John Jakobsen on 5/13/23.
//

import Foundation
import SWXMLHash
import StreamCiphers

public struct Meta: XMLObjectDeserialization, Serializable {
    let generator: XMLString?
    let databaseName: XMLString?
    let databaseDescription: XMLString?
    let memoryProtection: FieldProtection?
    let customData: CustomData?
    let color: Color?
    let Name: String = "String"
    
    public static func deserialize(_ element: XMLIndexer) throws -> Meta {
        return Meta(
            generator: try? element["Generator"].value(),
            databaseName: try element["DatabaseName"].value(),
            databaseDescription: try? element["DatabaseDescription"].value(),
            memoryProtection: try? element["MemoryProtection"].value(),
            customData: try? element["CustomData"].value(),
            color: try? element["Color"].value())
    }
    
    private func XMLizeString(s: String?, title: String) -> String {
        guard let sNotNil = s else {
            return "".XMLize(title: title)
        }
        return sNotNil.XMLize(title: title)
    }
    
    private func XMLizeObject(title: String, obj: Serializable?) -> String {
        guard let objNotNil = obj else {
            return "".XMLize(title: title)
        }
        return objNotNil.serialize(base64Encoded: false, streamCipher: nil)
    }
    
    func serialize(base64Encoded: Bool, streamCipher: StreamCipher?) throws -> String {
        return try """
    <Meta>
        \(generator?.serialize() ?? "")
        \(databaseName?.serialize() ?? "")
        \(databaseDescription?.serialize() ?? "")
        \(color?.serialize() ?? "")
        \(memoryProtection?.serialize() ?? "")
        \(customData?.serialize() ?? "")
    </Meta>
"""
    }
}
