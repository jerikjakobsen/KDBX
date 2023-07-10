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
@available(macOS 13.0, *)
public final class Entry: NSObject, Serializable, XMLObjectDeserialization, ModifyListener {
    public var KeyVals: [KeyVal]
    public let UUID: XMLString
    var iconID: XMLString
    private var times: Times
    public var name: XMLString
    internal var modifyListener: ModifyListener?
    
    internal init(KeyVals: [KeyVal], UUID: XMLString, iconID: XMLString, times: Times, name: XMLString) {
        self.KeyVals = KeyVals
        self.UUID = UUID
        self.iconID = iconID
        self.times = times
        self.name = name
        super.init()
        self.name.modifyListener = self
        self.iconID.modifyListener = self
        for kv in self.KeyVals {
            kv.modifyListener = self
        }
    }
    
    public init(iconID: String = "0", keyVals: [KeyVal] = [], expires: Bool = false, expiryTime: Date? = nil, name: String) {
        let uuidXMLString = XMLString(content: Foundation.UUID().uuidString, name: "UUID")
        var iconIDXMLString: XMLString = XMLString(content: iconID, name: "IconID")
        let entryNameXMLString = XMLString(content: name, name: "EntryName")
        
        self.KeyVals = keyVals
        self.UUID = uuidXMLString
        self.iconID = iconIDXMLString
        self.times = Times.now(expires: expires, expiryTime: expiryTime)
        self.name = entryNameXMLString
        super.init()
        self.name.modifyListener = self
        self.iconID.modifyListener = self
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
        
        guard let entryName = entryNameXMLString else {
            throw EntryError.NoTitleFound
        }
        
        var times: Times = try element["Times"].value()
        times.update(modified: false)
        
        return try Entry(KeyVals: keyVals,
                         UUID: element["UUID"].value(),
                         iconID: element["IconID"].value(),
                         times: times,
                         name: entryName)
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
        
        guard let entryName = entryNameXMLString else {
            throw EntryError.NoTitleFound
        }
        
        var times: Times = try element["Times"].value()
        times.update(modified: false)
        
        return try Entry(KeyVals: keyVals,
                         UUID: element["UUID"].value(),
                         iconID: element["IconID"].value(),
                         times: times,
                         name: entryName)
    }
    
    public func serialize(base64Encoded: Bool, streamCipher: StreamCipher?) throws -> String {
        let keyvalsString = try KeyVals.map({ kv in
            return try kv.serialize(streamCipher: streamCipher)
        }).joined(separator: "\n")
        return try """
                <Entry>
                \(UUID.serialize())
                \(name.serialize())
                \(iconID.serialize())
                \(times.serialize())
                \(keyvalsString)
                </Entry>
            """
    }
    
    public func addKeyVal(keyVal: KeyVal) {
        keyVal.modifyListener = self
        self.KeyVals.append(keyVal)
        let updateDate: Date = Date.now
        self.times.update(modified: true, date: updateDate)
        self.modifyListener?.didModify(date: updateDate)
    }
    
    public func removeKeyVal(key: String) {
        self.KeyVals.removeAll { kv in
            return kv.key.content != key
        }
        let updateDate: Date = Date.now
        self.times.update(modified: true, date: updateDate)
        self.modifyListener?.didModify(date: updateDate)
    }
    
    func didModify(date: Date) {
        self.modifyListener?.didModify(date: date)
    }
    
    func setName(name: String) {
        self.name.content = name
    }
    
    func getName() -> String {
        return self.name.content
    }
    
    func setIconID(iconID: String) {
        self.iconID.content = iconID
    }
    
    func getIconID() -> String {
        return self.iconID.content
    }
    
    public func isEqual(_ object: Entry?) -> Bool {
        guard let notNil = object else {
            return false
        }
        var keyValsEq = true
        for kv in KeyVals {
            var found = false
            for kv2 in notNil.KeyVals {
                if kv.isEqual(kv2) {
                    found = true
                    break
                }
            }
            if !found {
                keyValsEq = false
                break
            }
        }
        keyValsEq = keyValsEq && notNil.KeyVals.count == KeyVals.count
        return (keyValsEq &&
                notNil.iconID.isEqual(iconID) &&
                notNil.name.isEqual(name))
    }
    
    public override var description: String {
        let keyValsStr = KeyVals.map { kv in
            return kv.description
        }.joined(separator: "\n")
        return "KeyVals: [\(keyValsStr)]\niconID: \(iconID)\nname: \(name)\n"
    }
}


