//
//  Color.swift
//  
//
//  Created by John Jakobsen on 5/17/23.
//

import Foundation
import SWXMLHash
import StreamCiphers

@available(iOS 13.0, *)
@available(macOS 13.0, *)
public final class Color: NSObject, XMLObjectDeserialization, Serializable {
    var red: Float {
        didSet {
            self.modifyListener?.didModify(date: Date.now)
        }
    }
    var green: Float {
        didSet {
            self.modifyListener?.didModify(date: Date.now)
        }
    }
    var blue: Float {
        didSet {
            self.modifyListener?.didModify(date: Date.now)
        }
    }
    var alpha: Float {
        didSet {
            self.modifyListener?.didModify(date: Date.now)
        }
    }
    internal var modifyListener: ModifyListener? = nil
    
    public init(red: Float, green: Float, blue: Float, alpha: Float) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
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
    
    public func isEqual(_ object: Color?) -> Bool {
        guard let notNil = object else {
            return false
        }
        
        return (notNil.red == red &&
                notNil.green == green &&
                notNil.blue == blue &&
                notNil.alpha == alpha)
    }
}
