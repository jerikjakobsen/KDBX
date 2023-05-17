//
//  Times.swift
//  
//
//  Created by John Jakobsen on 5/15/23.
//

import Foundation
import SWXMLHash

enum DateError: Error {
    case DateDecoding
}

func convertToDate(s: String, offsetFromUnix: Int64 = Int64(-62135596800), base64Encoded: Bool = true) throws -> Date {
    var d: Data
    if (base64Encoded) {
        guard let stringData = Data(base64Encoded: s) else {
            throw DateError.DateDecoding
        }
        d = stringData
    } else {
        guard let stringData = s.data(using: .utf8) else {
            throw DateError.DateDecoding
        }
        d = stringData
    }
    
    
    let time = UInt64(littleEndian: d.withUnsafeBytes { $0.load(as: UInt64.self) })
    return Date(timeIntervalSince1970: TimeInterval(Int64(time) + offsetFromUnix))
}

public struct Times: XMLObjectDeserialization {
    let lastModificationTime: Date?
    let creationTime: Date?
    let lastAccessedTime: Date?
    let expires: Bool?
    let expiryTime: Date?
    
    public static func deserialize(_ element: XMLIndexer) throws -> Times {
        // Assumes time offset is from 1/1/01 12:00 AM GMT
        let lmtStr: String = try element["LastModificationTime"].value()
        let ctStr: String = try element["CreationTime"].value()
        let latStr: String = try element["LastAccessTime"].value()
        let expires: Bool = try element["Expires"].value()
        let et: String = try element["ExpiryTime"].value()
        
        return try Times(
            lastModificationTime: convertToDate(s: lmtStr),
            creationTime: convertToDate(s: ctStr),
            lastAccessedTime: convertToDate(s: latStr),
            expires: expires,
            expiryTime: convertToDate(s: et))
    }
}
