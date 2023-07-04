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
@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
public struct Times: XMLObjectDeserialization, Serializable {
    let lastModificationTime: Date?
    let creationTime: Date?
    let lastAccessedTime: Date?
    let expires: Bool?
    let expiryTime: Date?
    let timeOffset: Int64?
    
    public static func deserialize(_ element: XMLIndexer) throws -> Times {
        // Assumes time offset is from 1/1/01 12:00 AM GMT (if not timeOffset is available)
        let lmtStr: String = try element["LastModificationTime"].value()
        let ctStr: String = try element["CreationTime"].value()
        let expires: Bool = try element["Expires"].value()
        let et: String = try element["ExpiryTime"].value()
        let timeOffsetStr: String? = try? element["TimeOffset"].value()
        var timeOffsetInt64: Int64? = nil
        if let timeOffset: String = timeOffsetStr {
            timeOffsetInt64 = Int64(timeOffset)
        }
        
        return try Times(
            lastModificationTime: convertToDate(s: lmtStr, offsetFromUnix: timeOffsetInt64),
            creationTime: convertToDate(s: ctStr, offsetFromUnix: timeOffsetInt64),
            lastAccessedTime: Date.now,
            expires: expires,
            expiryTime: convertToDate(s: et, offsetFromUnix: timeOffsetInt64),
            timeOffset: timeOffsetInt64
        )
    }
    
    public func serialize(base64Encoded: Bool = true, streamCipher: StreamCipher? = nil) throws -> String {
        return try """
<Times>
    \(timeOffset != nil ? XMLString(content: String(timeOffset!), name: "TimeOffset").serialize() : "")
    <LastModificationTime>\(convertToString(date: lastModificationTime!))</LastModificationTime>
    <CreationTime>\(convertToString(date: creationTime!))</CreationTime>
    <LastAccessTime>\(convertToString(date: lastAccessedTime!))</LastAccessTime>
    <ExpiryTime>\(convertToString(date: expiryTime!))</ExpiryTime>
    <Expires>\(expires ?? false ? "True" : "False")</Expires>
</Times>
"""
    }
    
    public func modify(newLastModificationTime: Date? = nil, newLastAccessTime: Date? = nil, newExpiryTime: Date? = nil, newExpires: Bool? = nil, newTimeOffset: Int64? = nil) -> Times {
        if (newLastAccessTime == nil && newLastModificationTime == nil && newExpires == nil && newExpiryTime == nil && newTimeOffset == nil) {
            return self
        }
        return Times(lastModificationTime: newLastModificationTime ?? self.lastModificationTime,
                     creationTime: self.creationTime,
                     lastAccessedTime: newLastAccessTime ?? self.lastAccessedTime,
                     expires: newExpires ?? self.expires,
                     expiryTime: newExpiryTime ?? self.expiryTime,
                     timeOffset: newTimeOffset ?? self.timeOffset)
    }
    
    public func update(modified: Bool) -> Times {
        return self.modify(newLastModificationTime: modified ? Date.now : nil, newLastAccessTime: Date.now)
    }
    
    public static func now(expires: Bool, expiryTime: Date? = nil) -> Times {
        return Times(lastModificationTime: Date.now, creationTime: Date.now, lastAccessedTime: Date.now, expires: expires, expiryTime: expiryTime, timeOffset: 0)
    }
}
