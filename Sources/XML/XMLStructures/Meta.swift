//
//  Meta.swift
//  
//
//  Created by John Jakobsen on 5/13/23.
//

import Foundation
import SWXMLHash

public struct Meta: XMLObjectDeserialization {
    let generator: String?
    let databaseName: String?
    let databaseDescription: String?
    let memoryProtection: FieldProtection?
    let customData: CustomData?
    let color: Color?
    
    public static func deserialize(_ element: XMLIndexer) throws -> Meta {
        return Meta(
            generator: try? element["Generator"].value(),
            databaseName: try element["DatabaseName"].value(),
            databaseDescription: try? element["DatabaseDescription"].value(),
            memoryProtection: try? element["MemoryProtection"].value(),
            customData: try? element["CustomData"].value(),
            color: try? element["Color"].value())
    }
}
