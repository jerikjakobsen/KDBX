//
//  XMLHelpers.swift
//  
//
//  Created by John Jakobsen on 5/19/23.
//

import Foundation

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
