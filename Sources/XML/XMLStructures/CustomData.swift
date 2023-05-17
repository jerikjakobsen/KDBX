//
//  CustomData.swift
//  
//
//  Created by John Jakobsen on 5/15/23.
//

import Foundation
import SWXMLHash

public struct CustomData: XMLObjectDeserialization {
    let lastModified: Date?
    let dateOffset: Int64?
    
    public static func deserialize(_ element: XMLIndexer) throws -> CustomData {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E MMM d HH:mm:ss yyyy z"
        
        let keyVals: [KeyVal] = try element["Item"].value()
        var lastModified: Date? = nil
        var dateOffset: Int64? = Int64(-62135596800)
        
        for keyval in keyVals {
            let keyStr = keyval.key
            let valStr = keyval.value
            switch (keyStr) {
                case "_LAST_MODIFIED":
                    lastModified = dateFormatter.date(from: valStr)
                    break
                case "DATE_OFFSET":
                    dateOffset = Int64(valStr)
                    break
                default:
                    break
            }
        }
        
        return CustomData(
            lastModified: lastModified,
            dateOffset: dateOffset)
    }
}
