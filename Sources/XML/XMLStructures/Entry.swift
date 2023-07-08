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
public final class Entry: NSObject, Serializable, XMLObjectDeserialization, ModifyListener {
    private var KeyVals: [KeyVal]
    public let UUID: XMLString?
    var iconID: XMLString?
    private var times: Times?
    public var name: XMLString?
    internal var modifyListener: ModifyListener?
    
    public init(KeyVals: [KeyVal], UUID: XMLString?, iconID: XMLString?, times: Times?, entryName: XMLString?) {
        self.KeyVals = KeyVals
        self.UUID = UUID
        self.iconID = iconID
        self.times = times
        self.name = entryName
        super.init()
        self.name?.modifyListener = self
        self.iconID?.modifyListener = self
        for kv in self.KeyVals {
            kv.modifyListener = self
        }
    }
    
    public init(iconID: String? = nil, keyVals: [KeyVal] = [], expires: Bool = false, expiryTime: Date? = nil, name: String) {
        let uuidXMLString = XMLString(content: Foundation.UUID().uuidString, name: "UUID")
        var iconIDXMLString: XMLString? = nil
        if let icID = iconID {
            iconIDXMLString = XMLString(content: icID, name: "String")
        }
        let entryNameXMLString = XMLString(content: name, name: "EntryName")
        
        self.KeyVals = keyVals
        self.UUID = uuidXMLString
        self.iconID = iconIDXMLString
        self.times = Times.now(expires: expires, expiryTime: expiryTime)
        self.name = entryNameXMLString
        super.init()
        self.name?.modifyListener = self
        self.iconID?.modifyListener = self
        for kv in self.KeyVals {
            kv.modifyListener = self
        }
    }
    
    public static func deserialize(_ element: XMLIndexer) throws -> Entry {
        var keyVals: [KeyVal] = try element["String"].value()
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
        times.update(modified: false)
        
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
        times.update(modified: false)
        
        return try Entry(KeyVals: keyVals,
                         UUID: element["UUID"].value(),
                         iconID: element["IconID"].value(),
                         times: times,
                         entryName: entryNameXMLString)
    }
    
    public func serialize(base64Encoded: Bool, streamCipher: StreamCipher?) throws -> String {
        let keyvalsString = try? KeyVals.map({ kv in
            return try kv.serialize(streamCipher: streamCipher)
        }).joined(separator: "\n")
        return try """
            <Entry>
                \(UUID?.serialize() ?? "")
                \(name?.serialize() ?? "")
                \(iconID?.serialize() ?? "")
                \(times?.serialize() ?? "")
                \(keyvalsString ?? "")
            </Entry>
            """
    }
    
    public func addKeyVal(keyVal: KeyVal) {
        keyVal.modifyListener = self
        self.KeyVals.append(keyVal)
        let updateDate: Date = Date.now
        self.times?.update(modified: true, date: updateDate)
        self.modifyListener?.didModify(date: updateDate)
    }
    
    public func removeKeyVal(key: String) {
        self.KeyVals.removeAll { kv in
            return kv.key.content != key
        }
        let updateDate: Date = Date.now
        self.times?.update(modified: true, date: updateDate)
        self.modifyListener?.didModify(date: updateDate)
    }
    
    func didModify(date: Date) {
        self.modifyListener?.didModify(date: date)
    }
    
    func setName(name: String) {
        self.name?.content = name
    }
    
    func getName() -> String? {
        return self.name?.content
    }
    
    func setIconID(iconID: String) {
        self.iconID?.content = iconID
    }
    
    func getIconID() -> String? {
        return self.iconID?.content
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
extension Entry: Equatable {
    public static func == (lhs: Entry, rhs: Entry) -> Bool {
        return (lhs.KeyVals == rhs.keyVals &&
        lhs.iconID == rhs.iconID &&
        lhs.name == rhs.name)
    }
}

