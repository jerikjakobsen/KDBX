//
//  Meta.swift
//  
//
//  Created by John Jakobsen on 5/13/23.
//

import Foundation
import SWXMLHash
import StreamCiphers

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
public struct Meta: XMLObjectDeserialization, Serializable {
    let generator: XMLString?
    let databaseName: XMLString?
    let databaseDescription: XMLString?
    let times: Times?
    let color: Color?
    
    public static func new(generator: String, databaseName: String, databaseDescription: String, color: Color) -> Meta {
        let generatorXMLString = XMLString(content: generator, name: "Generator")
        let databaseNameXMLString = XMLString(content: databaseName, name: "DatabaseName")
        let databaseDescriptionXMLString = XMLString(content: databaseDescription, name: "DatabaseDescription")
        let times = Times.now(expires: false, expiryTime: nil)
        
        return Meta(generator: generatorXMLString, databaseName: databaseNameXMLString, databaseDescription: databaseDescriptionXMLString, times: times, color: color)
    }
    
    public static func deserialize(_ element: XMLIndexer) throws -> Meta {
        
        var times: Times? = try? element["Times"].value()
        times = times?.update(modified: false)
        
        return Meta(
            generator: try? element["Generator"].value(),
            databaseName: try element["DatabaseName"].value(),
            databaseDescription: try? element["DatabaseDescription"].value(),
            times: times,
            color: try? element["Color"].value())
    }
    
    func serialize(base64Encoded: Bool, streamCipher: StreamCipher?) throws -> String {
        return try """
    <Meta>
        \(generator?.serialize() ?? "")
        \(databaseName?.serialize() ?? "")
        \(databaseDescription?.serialize() ?? "")
        \(color?.serialize() ?? "")
        \(times?.serialize() ?? "")
    </Meta>
"""
    }
    
    public func modify(newGenerator: String? = nil, newDatabaseName: String? = nil, newDatabaseDescription: String? = nil, newColor: Color? = nil) -> Meta {
        if (newGenerator == nil && newDatabaseName == nil && newDatabaseDescription == nil && newColor == nil) {
            return self
        }
        return Meta(generator: self.generator?.modify(content: newGenerator),
                    databaseName: self.databaseName?.modify(content: newDatabaseName),
                    databaseDescription: self.databaseDescription?.modify(content: newDatabaseDescription),
                    times: self.times?.update(modified: true),
                    color: newColor ?? self.color)
    }
}
