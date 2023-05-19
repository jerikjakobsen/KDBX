//
//  Color.swift
//  
//
//  Created by John Jakobsen on 5/17/23.
//

import Foundation
import SWXMLHash

public struct Color: XMLObjectDeserialization, Serializable {
    let red: Float
    let green: Float
    let blue: Float
    let alpha: Float
    
    public static func deserialize(_ element: XMLIndexer) throws -> Color {
        return try Color(
            red: element["Red"].value(),
            green: element["Green"].value(),
            blue: element["Blue"].value(),
            alpha: element["Alpha"].value())
    }
    
    public func serialize() -> String {
        return """
<Color>
    <Red>\(red)</Red>
    <Green>\(green)</Green>
    <Blue>\(blue)</Blue>
    <Alpha>\(alpha)</Alpha>
</Color>
"""
    }
}
