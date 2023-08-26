//
//  Times.swift
//  
//
//  Created by John Jakobsen on 5/15/23.
//

import Foundation
import SWXMLHash
import StreamCiphers

enum DateError: Error {
    case DateDecoding
}
@available(iOS 15.0, *)
@available(macOS 13.0, *)
public final class TimesXML: XMLObjectDeserialization, Serializable, NSCopying {
    public var lastModificationTime: Date?
    public let creationTime: Date?
    public var lastAccessedTime: Date?
    public var expires: Bool?
    public var expiryTime: Date?
    public var timeOffset: Int64?
    
    init(lastModificationTime: Date? = nil, creationTime: Date? = nil, lastAccessedTime: Date? = nil, expires: Bool? = nil, expiryTime: Date? = nil, timeOffset: Int64? = nil) {
        self.lastModificationTime = lastModificationTime
        self.creationTime = creationTime
        self.lastAccessedTime = lastAccessedTime
        self.expires = expires
        self.expiryTime = expiryTime
        self.timeOffset = timeOffset
    }
    
    public static func deserialize(_ element: XMLIndexer) throws -> TimesXML {
        // Assumes time offset is from 1/1/01 12:00 AM GMT (if timeOffset is not available)
        let lmtStr: String = try element["LastModificationTime"].value()
        let ctStr: String = try element["CreationTime"].value()
        let expires: Bool = try element["Expires"].value()
        let et: String = try element["ExpiryTime"].value()
        let timeOffsetStr: String? = try? element["TimeOffset"].value()
        var timeOffsetInt64: Int64? = nil
        if let timeOffset: String = timeOffsetStr {
            timeOffsetInt64 = Int64(timeOffset)
        } else {
            timeOffsetInt64 = Int64(-62135596800)
        }
        
        return try TimesXML(
            lastModificationTime: convertToDate(s: lmtStr, offsetFromUnix: timeOffsetInt64),
            creationTime: convertToDate(s: ctStr, offsetFromUnix: timeOffsetInt64),
            lastAccessedTime: Date.now,
            expires: expires,
            expiryTime: convertToDate(s: et, offsetFromUnix: timeOffsetInt64),
            timeOffset: timeOffsetInt64
        )
    }
    
    public func serialize(base64Encoded: Bool = true, streamCipher: StreamCipher? = nil) throws -> String {
        
        var lmtString = ""
        if let lmt = lastModificationTime {
            lmtString = try convertToString(date: lmt)
        }
        
        var ctString = ""
        if let ct = lastModificationTime {
            ctString = try convertToString(date: ct)
        }
        
        var latString = ""
        if let lat = lastModificationTime {
            latString = try convertToString(date: lat)
        }
        
        var etString = ""
        if let et = lastModificationTime {
            etString = try convertToString(date: et)
        }
        
        return try """
<Times>
    \(timeOffset != nil ? XMLString(value: String(timeOffset!), name: "TimeOffset").serialize() : "")
    <LastModificationTime>\(lmtString)</LastModificationTime>
    <CreationTime>\(ctString)</CreationTime>
    <LastAccessTime>\(latString)</LastAccessTime>
    <ExpiryTime>\(etString)</ExpiryTime>
    <Expires>\(expires ?? false ? "True" : "False")</Expires>
</Times>
"""
    }
    
    public func update(modified: Bool, date: Date? = nil) {
        if (modified) {
            self.lastModificationTime = date ?? Date.now
        }
        self.lastAccessedTime = date ?? Date.now
    }
    
    public static func now(expires: Bool, expiryTime: Date? = nil) -> TimesXML {
        return TimesXML(lastModificationTime: Date.now, creationTime: Date.now, lastAccessedTime: Date.now, expires: expires, expiryTime: expiryTime, timeOffset: 0)
    }
    
    public override func copy() -> TimesXML {
        return TimesXML(lastModificationTime: self.lastModificationTime, creationTime: self.creationTime, lastAccessedTime: self.lastAccessedTime, expire: self.expires, expiryTime: self.expiryTime, timeOffset: self.timeOffset)
    }
}
