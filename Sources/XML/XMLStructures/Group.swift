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
public final class Group: XMLObjectDeserialization, Serializable {
    public let UUID: XMLString?
    var name: XMLString? {
        didSet {
            let updateDate: Date = Date.now
            self.times?.update(modified: true, date: updateDate)
            self.modifyListener?.didModify(date: updateDate)
        }
    }
    var iconID: XMLString?  {
        didSet {
            let updateDate: Date = Date.now
            self.times?.update(modified: true, date: updateDate)
            self.modifyListener?.didModify(date: updateDate)
        }
    }
    private var times: Times?
    private var entries: [Entry]
    internal var modifyListener: ModifyListener?
    
    internal init(UUID: XMLString?, name: XMLString?, iconID: XMLString?, times: Times?, entries: [Entry] = []) {
        self.UUID = UUID
        self.name = name
        self.iconID = iconID
        self.times = times
        self.entries = entries
    }
    
    public init(name: String = "", iconID: String = "", entries: [Entry] = [], expires: Bool = false, expiryTime: Date? = nil) {
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
        
        var times: Times = try element["Times"].value()
        times.update(modified: false)
        
        return try Group(UUID: element["UUID"].value(),
                         name: element["Name"].value(),
                         iconID: element["IconID"].value(),
                         times: times,
                         entries: entries)
    }
    
    public func serialize(base64Encoded: Bool, streamCipher: StreamCipher?) throws -> String {
        let entriesString = try? entries.map({ entry in
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
    
    public func addEntry(entry: Entry) {
        self.entries.append(entry)
        
        let updateDate: Date = Date.now
        self.times?.update(modified: true, date: updateDate)
        self.modifyListener?.didModify(date: updateDate)
    }
    
    public func removeEntry(UUID: String) {
        self.entries.removeAll { entry in
            return entry.UUID?.content != UUID
        }
        
        let updateDate: Date = Date.now
        self.times?.update(modified: true, date: updateDate)
        self.modifyListener?.didModify(date: updateDate)
    }
    
    public func setName(name: String) {
        self.name?.content = name
    }
    
    public func getName() -> String? {
        return self.name?.content
    }
    
    public func setIconID(iconID: String) {
        self.iconID?.content = iconID
    }
    
    public func getIconID() -> String? {
        return self.iconID?.content
    }
    
    public func getEntries() -> [Entry] {
        return self.entries
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
extension Group: Equatable {
    public static func == (lhs: Group, rhs: Group) -> Bool {
        return (lhs.name == rhs.name &&
        lhs.iconID == rhs.iconID &&
        lhs.entries == rhs.entries)
    }
}
