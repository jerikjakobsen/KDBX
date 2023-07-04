//
//  Group.swift
//  
//
//  Created by John Jakobsen on 7/2/23.
//

import Foundation
import StreamCiphers
import SWXMLHash

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
public struct Group: XMLObjectDeserialization, Serializable {
    let UUID: XMLString?
    let name: XMLString?
    let iconID: XMLString?
    let times: Times?
    let entries: [Entry]?
    
    public static func new(name: String, iconID: String, entries: [Entry]? = []) -> Group {
        let UUIDXMLString = XMLString(content: Foundation.UUID().uuidString, name: "UUID")
        let nameXMLString = XMLString(content: name, name: "Name")
        let iconIDXMLString = XMLString(content: iconID, name: "IconID")
        return Group(UUID: UUIDXMLString, name: nameXMLString, iconID: iconIDXMLString, times: Times.now(expires: false), entries: entries)
    }
    
    public static func deserialize(_ element: XMLIndexer, streamCipher: StreamCipher) throws -> Group {
        let entries = try element["Entry"].all.map { entry in
            return try Entry.deserialize(entry, streamCipher: streamCipher)
        }
        
        var times: Times = try element["Times"].value()
        times = times.update(modified: false)
        
        return try Group(UUID: element["UUID"].value(),
                         name: element["Name"].value(),
                         iconID: element["IconID"].value(),
                         times: times,
                         entries: entries)
    }
    
    public func serialize(base64Encoded: Bool, streamCipher: StreamCipher?) throws -> String {
        let entriesString = try? entries?.map({ entry in
            return try entry.serialize(base64Encoded: base64Encoded, streamCipher: streamCipher)
        }).joined(separator: "\n")
        return try """
<Group>
    \(UUID?.serialize() ?? "")
    \(name?.serialize() ?? "")
    \(iconID?.serialize() ?? "")
    \(times?.serialize() ?? "")
    \(entriesString ?? "")
</Group>
"""
    }
    
    public func addEntry(entry: Entry) throws -> Group {
        return Group(UUID: self.UUID,
                     name: self.name,
                     iconID: self.iconID,
                     times: self.times?.update(modified: true),
                     entries: (self.entries ?? []) + [entry])
    }
    
    public func removeEntry(UUID: String) -> Group {
        return Group(UUID: self.UUID,
                     name: self.name,
                     iconID: self.iconID,
                     times: self.times?.update(modified: true),
                     entries: self.entries?.filter({ entry in
            return entry.UUID?.content != UUID
        }))
    }
    
    public func modify(newName: String? = nil, newIconID: String? = nil) -> Group {
        if (newName == nil && newIconID == nil) {
            return self
        }
        
        return Group(UUID: self.UUID,
                     name: self.name?.modify(content: newName),
                     iconID: self.iconID?.modify(content: newIconID),
                     times: self.times?.update(modified: true),
                     entries: self.entries)
    }
}
