//
//  String+XMLize.swift
//  
//
//  Created by John Jakobsen on 5/21/23.
//

import Foundation
import SWXMLHash

extension String: Serializable {
    
    func XMLize(title: String, properties: [String: String]? = nil) -> String {
        if (self.count == 0) {
            return "<\(title)/>"
        }
        return """
            <\(title)\((properties?.count ?? 0) > 0 ? " \(String.propertiesXMLize(properties: properties ?? [:]))" : "")>\(self)</\(title)>
            """
    }
    
    private static func propertiesXMLize(properties: [String: String]) -> String {
        return String(properties.map { (key, value) in
            return """
                \(key)="\(value)"
                """
        }.joined(separator: " "))
    }
}

//extension String? {
//    func XMLize(title: String, properties: )
//}
//
//extension String: XMLObjectDeserialization {
//    public static func deserialize(_ element: XMLIndexer) throws -> String {
//        element.element?.name
//    }
//}
