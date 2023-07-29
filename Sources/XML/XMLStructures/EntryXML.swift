//
//  Entry.swift
//  
//
//  Created by John Jakobsen on 5/16/23.
//

import Foundation
import StreamCiphers
import SWXMLHash

enum EntryXMLError: Error {
    case NoTitleFound
}

@available(iOS 15.0, *)
@available(macOS 13.0, *)
public final class EntryXML: NSObject, Serializable, XMLObjectDeserialization, ModifyListener {
    public var KeyVals: [KeyValXML]
    public let UUID: XMLString
    var iconID: XMLString
    private var times: TimesXML
    public var name: XMLString
    internal var modifyListener: ModifyListener?
    
    public lazy var email: String? = {
        return getValueWith(key: "Email")
    }()
    
    public lazy var username: String? = {
        return getValueWith(key: "Username")
    }()
    public lazy var password: String? = {
        return getValueWith(key: "Password")
    }()
    
    internal init(KeyVals: [KeyValXML], UUID: XMLString, iconID: XMLString, times: TimesXML, name: XMLString) {
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
    
    public init(iconID: String = "0", keyVals: [KeyValXML] = [], expires: Bool = false, expiryTime: Date? = nil, name: String) {
        let uuidXMLString = XMLString(value: Foundation.UUID().uuidString, name: "UUID")
        let iconIDXMLString: XMLString = XMLString(value: iconID, name: "IconID")
        let entryNameXMLString = XMLString(value: name, name: "EntryName")
        
        self.KeyVals = keyVals
        self.UUID = uuidXMLString
        self.iconID = iconIDXMLString
        self.times = TimesXML.now(expires: expires, expiryTime: expiryTime)
        self.name = entryNameXMLString
        super.init()
        self.name.modifyListener = self
        self.iconID.modifyListener = self
        for kv in self.KeyVals {
            kv.modifyListener = self
        }
    }
    
    public static func deserialize(_ element: XMLIndexer) throws -> EntryXML {
        var keyVals: [KeyValXML] = try element["String"].value()
        var entryNameXMLString: XMLString? = try? element["EntryName"].value()
        if entryNameXMLString == nil {
            let titleKeyVal = keyVals.filter({ kv in
                return kv.key.value == "Title"
            })
            
            if titleKeyVal.count == 0 {
                throw EntryXMLError.NoTitleFound
            }
            
            let name = titleKeyVal[0].value.value
            
            keyVals = keyVals.filter({ kv in
                return kv.key.value != "Title"
            })
            entryNameXMLString = XMLString(value: name, name: "EntryName")
        }
        
        guard let entryName = entryNameXMLString else {
            throw EntryXMLError.NoTitleFound
        }
        
        var times: TimesXML = try element["Times"].value()
        times.update(modified: false)
        
        return try EntryXML(KeyVals: keyVals,
                         UUID: element["UUID"].value(),
                         iconID: element["IconID"].value(),
                         times: times,
                         name: entryName)
    }
    public static func deserialize(_ element: XMLIndexer, streamCipher: StreamCipher? = nil) throws -> EntryXML {
        var keyVals: [KeyValXML] = try element["String"].all.map { keyval in
            return try KeyValXML.deserialize(keyval, streamCipher: streamCipher)
        }
        var entryNameXMLString: XMLString? = try? element["EntryName"].value()
        if entryNameXMLString == nil {
            let titleKeyVal = keyVals.filter({ kv in
                return kv.key.value == "Title"
            })
            
            if titleKeyVal.count == 0 {
                throw EntryXMLError.NoTitleFound
            }
            
            let name = titleKeyVal[0].value.value
            keyVals = keyVals.filter({ kv in
                return kv.key.value != "Title"
            })
            
            entryNameXMLString = XMLString(value: name, name: "EntryName")
        }
        
        guard let entryName = entryNameXMLString else {
            throw EntryXMLError.NoTitleFound
        }
        
        var times: TimesXML = try element["Times"].value()
        times.update(modified: false)
        
        return try EntryXML(KeyVals: keyVals,
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
    
    public func addKeyVal(keyVal: KeyValXML) {
        keyVal.modifyListener = self
        self.KeyVals.append(keyVal)
        let updateDate: Date = Date.now
        self.times.update(modified: true, date: updateDate)
        self.modifyListener?.didModify(date: updateDate)
    }
    
    public func addKeyVals(_ keyVals: [KeyValXML]) {
        for kv in keyVals {
            self.addKeyVal(keyVal: kv)
        }
    }
    
    public func removeKeyVal(key: String) {
        self.KeyVals.removeAll { kv in
            return kv.key.value != key
        }
        let updateDate: Date = Date.now
        self.times.update(modified: true, date: updateDate)
        self.modifyListener?.didModify(date: updateDate)
    }
    
    func didModify(date: Date) {
        self.modifyListener?.didModify(date: date)
    }
    
    func setName(name: String) {
        self.name.value = name
    }
    
    func getName() -> String {
        return self.name.value
    }
    
    func setIconID(iconID: String) {
        self.iconID.value = iconID
    }
    
    func getIconID() -> String {
        return self.iconID.value
    }
    
    public func isEqual(_ object: EntryXML?) -> Bool {
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
    
    public func getValueWith(key: String) -> String? {
        for kv in KeyVals {
            if kv.key.value == key {
                return kv.value.value
            }
        }
        return nil
    }
    
}


