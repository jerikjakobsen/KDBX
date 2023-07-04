//
//  CustomData.swift
//  
//
//  Created by John Jakobsen on 5/15/23.
//

import Foundation
import SWXMLHash

public struct CustomData: XMLObjectDeserialization, Serializable {
    let lastModified: Date?
    let dateOffset: Int64?
    static let dateFormatter = CustomDateFormatter()
    let Name: String = "CustomData"
    
    public static func deserialize(_ element: XMLIndexer) throws -> CustomData {
        
        let keyVals: [KeyVal] = try element["Item"].value()
        var lastModified: Date? = nil
        var dateOffset: Int64? = Int64(-62135596800)
        
        for keyval in keyVals {
            let keyStr = keyval.key
            let valStr = keyval.value
            switch (keyStr.content) {
                case "_LAST_MODIFIED":
                lastModified = dateFormatter.date(from: valStr.content)
                    break
                case "DATE_OFFSET":
                dateOffset = Int64(valStr.content)
                    break
                default:
                    break
            }
        }
        
        return CustomData(
            lastModified: lastModified,
            dateOffset: dateOffset)
    }
    
    private func serializeItem(key: String?, val: String?) -> String {
        
        if (key == nil || val == nil) {
            return ""
        }
        
        return """
            <Item>
                \(key!.XMLize(title: "Key"))
                \(val!.XMLize(title: "Value"))
            </Item>
            """
    }
    
    public func serialize() -> String {
        var dateOffsetString: String? = nil
        if let dateOffsetTemp = dateOffset {
            dateOffsetString = String(dateOffsetTemp)
        }
        
        var lastModifiedString: String? = nil
        if let lastModifiedTemp = lastModified {
            lastModifiedString = CustomData.dateFormatter.string(from: lastModifiedTemp)
        }
        
        return """
            <\(Name)>
                \(serializeItem(key: "_LAST_MODIFIED", val: lastModifiedString))
                \(serializeItem(key: "DATE_OFFSET", val: dateOffsetString))
            </\(Name)>
            """
    }
}
