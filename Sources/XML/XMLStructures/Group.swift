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
    
    public static func deserialize(_ element: XMLIndexer, streamCipher: StreamCipher) throws -> Group {
    let entries = try element["Entry"].all.map { entry in
            let keyvals: [KeyVal] = try entry["String"].all.map { keyval in
                return try KeyVal.deserialize(keyval, streamCipher: streamCipher)
            }
            let times: Times? = try? entry["Times"].value()
            let uuid: XMLString? = try? entry["UUID"].value()
            let iconID: XMLString? = try? entry["IconID"].value()
            return Entry(KeyVals: keyvals, UUID: uuid, iconID: iconID, times: times)
        }
        return try Group(UUID: element["UUID"].value(),
                         name: element["Name"].value(),
                         iconID: element["IconID"].value(),
                         times: element["Times"].value(),
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
                     times: self.times?.modify(newLastModificationTime: Date.now, newLastAccessTime: Date.now),
                     entries: (self.entries ?? []) + [entry])
    }
    
    public func removeEntry(UUID: String) -> Group {
        return Group(UUID: self.UUID,
                     name: self.name,
                     iconID: self.iconID,
                     times: self.times?.modify(newLastModificationTime: Date.now, newLastAccessTime: Date.now),
                     entries: self.entries?.filter({ entry in
            return entry.UUID?.content != UUID
        }))
    }
}
