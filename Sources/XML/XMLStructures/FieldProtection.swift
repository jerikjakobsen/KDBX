//
//  FieldProtection.swift
//  
//
//  Created by John Jakobsen on 5/17/23.
//

import Foundation
import SWXMLHash

enum FieldProtectionError: Error {
    case AllNil
}

public struct FieldProtection: XMLObjectDeserialization {
    let title: Bool
    let username: Bool
    let password: Bool
    let url: Bool
    let notes: Bool
    
    public static func deserialize(_ element: XMLIndexer) throws -> FieldProtection {
        let title: Bool? = try? element["ProtectTitle"].value()
        let username: Bool? = try? element["ProtectUsername"].value()
        let password: Bool? = try? element["ProtectPassword"].value()
        let url: Bool? = try? element["ProtectURL"].value()
        let notes: Bool? = try? element["ProtectNotes"].value()
        guard title != nil || username != nil || password != nil || url != nil || notes != nil else {
            throw FieldProtectionError.AllNil
        }
        return FieldProtection(
            title: title ?? false,
            username: username ?? false,
            password: password ?? false,
            url: url ?? false,
            notes: notes ?? false)
    }
}
