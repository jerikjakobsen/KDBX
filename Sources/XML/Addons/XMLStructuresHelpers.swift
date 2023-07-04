//
//  XMLHelpers.swift
//  
//
//  Created by John Jakobsen on 5/19/23.
//

import Foundation

enum DateHelperError: Error {
    case CouldNotEncodeString
}

func convertToDate(s: String, offsetFromUnix: Int64? = nil, base64Encoded: Bool = true) throws -> Date {
    let defaultOffset = Int64(-62135596800)
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
    return Date(timeIntervalSince1970: TimeInterval(Int64(time) + (offsetFromUnix ?? defaultOffset)))
}

func convertToString(date: Date, offsetFromUnix: Int64? = nil, base64Encoded: Bool = true) throws-> String {
    let defaultOffset = Int64(-62135596800)
    var timeInMilliseconds: Int64 = (Int64(date.timeIntervalSince1970) - (offsetFromUnix ?? defaultOffset)).littleEndian
    var timeAsData = Data(bytes: &timeInMilliseconds, count: MemoryLayout<Int64>.size)
    var finalString: String = ""
    if (base64Encoded) {
        finalString = timeAsData.base64EncodedString()
    } else {
        guard let s = String(data: timeAsData, encoding: .utf8) else {
            throw DateHelperError.CouldNotEncodeString
        }
        finalString = s
    }
    return finalString
}
