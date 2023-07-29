//
//  Group.swift
//  
//
//  Created by John Jakobsen on 7/2/23.
//

import Foundation
import StreamCiphers
import SWXMLHash

@available(iOS 15.0, *)
@available(macOS 13.0, *)
public final class GroupXML: NSObject, XMLObjectDeserialization, Serializable {
    public let UUID: XMLString
    var name: XMLString {
        didSet {
            let updateDate: Date = Date.now
            self.times.update(modified: true, date: updateDate)
            self.modifyListener?.didModify(date: updateDate)
        }
    }
    var iconID: XMLString  {
        didSet {
            let updateDate: Date = Date.now
            self.times.update(modified: true, date: updateDate)
            self.modifyListener?.didModify(date: updateDate)
        }
    }
    private var times: TimesXML
    public var entries: [EntryXML]
    internal var modifyListener: ModifyListener?
    
    internal init(UUID: XMLString, name: XMLString, iconID: XMLString, times: TimesXML, entries: [EntryXML] = []) {
        self.UUID = UUID
        self.name = name
        self.iconID = iconID
        self.times = times
        self.entries = entries
    }
    
    public init(name: String = "Root", iconID: String = "0", entries: [EntryXML] = [], expires: Bool = false, expiryTime: Date? = nil) {
        self.UUID = XMLString(value: Foundation.UUID().uuidString, name: "UUID")
        self.name = XMLString(value: name, name: "Name")
        self.iconID = XMLString(value: iconID, name: "IconID")
        self.times =  TimesXML.now(expires: expires, expiryTime: expiryTime)
        self.entries = entries
    }
    
    public static func deserialize(_ element: XMLIndexer, streamCipher: StreamCipher) throws -> GroupXML {
        let entries = try element["Entry"].all.map { entry in
            return try EntryXML.deserialize(entry, streamCipher: streamCipher)
        }
        
        var times: TimesXML = (try? element["Times"].value()) ?? TimesXML.now(expires: false)
        times.update(modified: false)
        
        return try GroupXML(UUID: element["UUID"].value(),
                         name: element["Name"].value(),
                         iconID: element["IconID"].value(),
                         times: times,
                         entries: entries)
    }
    
    public func serialize(base64Encoded: Bool, streamCipher: StreamCipher?) throws -> String {
        let entriesString = try entries.map({ entry in
            return try entry.serialize(base64Encoded: base64Encoded, streamCipher: streamCipher)
        }).joined(separator: "\n")
        return try """
<Group>
\(UUID.serialize())
\(name.serialize())
\(iconID.serialize())
\(times.serialize())
\(entriesString)
</Group>
"""
    }
    
    public func addEntry(entry: EntryXML) {
        self.entries.append(entry)
        
        let updateDate: Date = Date.now
        self.times.update(modified: true, date: updateDate)
        self.modifyListener?.didModify(date: updateDate)
    }
    
    public func removeEntry(UUID: String) {
        self.entries.removeAll { entry in
            return entry.UUID.value != UUID
        }
        
        let updateDate: Date = Date.now
        self.times.update(modified: true, date: updateDate)
        self.modifyListener?.didModify(date: updateDate)
    }
    
    public func setName(name: String) {
        self.name.value = name
    }
    
    public func getName() -> String {
        return self.name.value
    }
    
    public func setIconID(iconID: String) {
        self.iconID.value = iconID
    }
    
    public func getIconID() -> String? {
        return self.iconID.value
    }
    
    public func getEntries() -> [EntryXML] {
        return self.entries
    }
    
    public func isEqual(_ object: GroupXML?) -> Bool {
        guard let notNil = object else {
            return false
        }
        var entriesEq = true
        for entry in entries {
            var found = false
            for entry2 in notNil.entries {
                if entry.isEqual(entry2) {
                    found = true
                    break
                }
            }
            if !found {
                entriesEq = false
                break
            }
        }
        entriesEq = entriesEq && notNil.entries.count == entries.count
        return (notNil.name.isEqual(name) &&
                notNil.iconID.isEqual(iconID) &&
                entriesEq)
    }
    
    public override var description: String {
        let entriesStr = entries.map { entry in
            return entry.description
        }.joined(separator: "\n")
        return "name: \(name)\niconID: \(iconID)\nentries: \(entriesStr)"
    }
}
