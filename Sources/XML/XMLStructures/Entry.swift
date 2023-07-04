//
//  Entry.swift
//  
//
//  Created by John Jakobsen on 5/16/23.
//

import Foundation
import StreamCiphers
import SWXMLHash

enum EntryError: Error {
    case NoTitleFound
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
public struct Entry: Serializable, XMLObjectDeserialization {
    let KeyVals: [KeyVal]?
    let UUID: XMLString?
    let iconID: XMLString?
    let times: Times?
    let entryName: XMLString?
    
    public static func new(iconID: String? = nil, keyVals: [KeyVal]? = [], expires: Bool = false, expiryTime: Date? = nil, name: String) -> Entry {
        let uuidXMLString = XMLString(content: Foundation.UUID().uuidString, name: "UUID")
        var iconIDXMLString: XMLString? = nil
        if let icID = iconID {
            iconIDXMLString = XMLString(content: icID, name: "String")
        }
        var entryNameXMLString = XMLString(content: name, name: "EntryName")
        
        return Entry(KeyVals: keyVals,
                     UUID: uuidXMLString,
                     iconID: iconIDXMLString,
                     times: Times.now(expires: expires, expiryTime: expiryTime),
                     entryName: entryNameXMLString)
    }
    
    public static func deserialize(_ element: XMLIndexer) throws -> Entry {
        var keyVals: [KeyVal]? = try element["String"].value()
        var entryNameXMLString: XMLString? = try? element["EntryName"].value()
        if entryNameXMLString == nil {
            let titleKeyVal = keyVals?.filter({ kv in
                return kv.key.content == "Title"
            })
            
            if titleKeyVal == nil || titleKeyVal?.count == 0 {
                throw EntryError.NoTitleFound
            }
            guard let name = titleKeyVal?[0].value.content else {
                throw EntryError.NoTitleFound
            }
            keyVals = keyVals?.filter({ kv in
                return kv.key.content != "Title"
            })
            entryNameXMLString = XMLString(content: name, name: "EntryName")
        }
        
        var times: Times = try element["Times"].value()
        times = times.update(modified: false)
        
        return try Entry(KeyVals: keyVals,
                         UUID: element["UUID"].value(),
                         iconID: element["IconID"].value(),
                         times: times,
                         entryName: entryNameXMLString)
    }
    public static func deserialize(_ element: XMLIndexer, streamCipher: StreamCipher? = nil) throws -> Entry {
        var keyVals: [KeyVal] = try element["String"].all.map { keyval in
            return try KeyVal.deserialize(keyval, streamCipher: streamCipher)
        }
        var entryNameXMLString: XMLString? = try? element["EntryName"].value()
        if entryNameXMLString == nil {
            let titleKeyVal = keyVals.filter({ kv in
                return kv.key.content == "Title"
            })
            
            if titleKeyVal.count == 0 {
                throw EntryError.NoTitleFound
            }
            
            let name = titleKeyVal[0].value.content
            keyVals = keyVals.filter({ kv in
                return kv.key.content != "Title"
            })
            
            entryNameXMLString = XMLString(content: name, name: "EntryName")
        }
        
        var times: Times = try element["Times"].value()
        times = times.update(modified: false)
        
        return try Entry(KeyVals: keyVals,
                         UUID: element["UUID"].value(),
                         iconID: element["IconID"].value(),
                         times: times,
                         entryName: entryNameXMLString)
    }
    
    public func serialize(base64Encoded: Bool, streamCipher: StreamCipher?) throws -> String {
        let keyvalsString = try? KeyVals?.map({ kv in
            return try kv.serialize(streamCipher: streamCipher)
        }).joined(separator: "\n")
        return try """
            <Entry>
                \(UUID?.serialize() ?? "")
                \(entryName?.serialize() ?? "")
                \(iconID?.serialize() ?? "")
                \(times?.serialize() ?? "")
                \(keyvalsString ?? "")
            </Entry>
            """
    }
    
    public func addKeyVal(keyVal: KeyVal) -> Entry {
        return Entry(KeyVals: (self.KeyVals ?? []) + [keyVal],
                     UUID: self.UUID,
                     iconID: self.iconID,
                     times: self.times?.update(modified: true),
                     entryName: self.entryName)
    }
    
    public func removeKeyVal(key: String) -> Entry {
        return Entry(KeyVals: (self.KeyVals ?? []).filter({ kv in
            return kv.key.content != key
        }),
                     UUID: self.UUID,
                     iconID: self.iconID,
                     times: self.times?.update(modified: true),
                     entryName: self.entryName)
    }
    
    public func modify(name: String? = nil, iconID: String? = nil) -> Entry {
        if (name == nil && iconID == nil) {
            return self
        }
        return Entry(KeyVals: self.KeyVals,
                     UUID: self.UUID,
                     iconID: self.iconID?.modify(content: iconID),
                     times: self.times?.update(modified: true),
                     entryName: self.entryName?.modify(content: name))
    }
}
