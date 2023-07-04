//
//  Color.swift
//  
//
//  Created by John Jakobsen on 5/17/23.
//

import Foundation
import SWXMLHash
import StreamCiphers

public struct Color: XMLObjectDeserialization {
    let red: Float
    let green: Float
    let blue: Float
    let alpha: Float
    let name: String
    
    public static func deserialize(_ element: XMLIndexer) throws -> Color {
        return try Color(
            red: element["Red"].value(),
            green: element["Green"].value(),
            blue: element["Blue"].value(),
            alpha: element["Alpha"].value(),
            name: element.element?.name ?? "")
    }
}

extension Color: Serializable {
    public func serialize() -> String {
        return """
<\(name)>
    <Red>\(red)</Red>
    <Green>\(green)</Green>
    <Blue>\(blue)</Blue>
    <Alpha>\(alpha)</Alpha>
</\(name)>
"""
    }
}
