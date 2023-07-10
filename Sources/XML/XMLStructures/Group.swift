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
@available(macOS 13.0, *)
public final class Group: NSObject, XMLObjectDeserialization, Serializable {
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
    private var times: Times
    public var entries: [Entry]
    internal var modifyListener: ModifyListener?
    
    internal init(UUID: XMLString, name: XMLString, iconID: XMLString, times: Times, entries: [Entry] = []) {
        self.UUID = UUID
        self.name = name
        self.iconID = iconID
        self.times = times
        self.entries = entries
    }
    
    public init(name: String = "Root", iconID: String = "0", entries: [Entry] = [], expires: Bool = false, expiryTime: Date? = nil) {
        self.UUID = XMLString(content: Foundation.UUID().uuidString, name: "UUID")
        self.name = XMLString(content: name, name: "Name")
        self.iconID = XMLString(content: iconID, name: "IconID")
        self.times =  Times.now(expires: expires, expiryTime: expiryTime)
        self.entries = entries
    }
    
    public static func deserialize(_ element: XMLIndexer, streamCipher: StreamCipher) throws -> Group {
        let entries = try element["Entry"].all.map { entry in
            return try Entry.deserialize(entry, streamCipher: streamCipher)
        }
        
        var times: Times = (try? element["Times"].value()) ?? Times.now(expires: false)
        times.update(modified: false)
        
        return try Group(UUID: element["UUID"].value(),
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
    
    public func addEntry(entry: Entry) {
        self.entries.append(entry)
        
        let updateDate: Date = Date.now
        self.times.update(modified: true, date: updateDate)
        self.modifyListener?.didModify(date: updateDate)
    }
    
    public func removeEntry(UUID: String) {
        self.entries.removeAll { entry in
            return entry.UUID.content != UUID
        }
        
        let updateDate: Date = Date.now
        self.times.update(modified: true, date: updateDate)
        self.modifyListener?.didModify(date: updateDate)
    }
    
    public func setName(name: String) {
        self.name.content = name
    }
    
    public func getName() -> String {
        return self.name.content
    }
    
    public func setIconID(iconID: String) {
        self.iconID.content = iconID
    }
    
    public func getIconID() -> String? {
        return self.iconID.content
    }
    
    public func getEntries() -> [Entry] {
        return self.entries
    }
    
    public func isEqual(_ object: Group?) -> Bool {
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
