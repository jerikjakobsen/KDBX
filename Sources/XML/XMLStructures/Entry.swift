//
//  Entry.swift
//  
//
//  Created by John Jakobsen on 5/16/23.
//

import Foundation
import StreamCiphers
import SWXMLHash

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
public struct Entry: Serializable, XMLObjectDeserialization {
    let KeyVals: [KeyVal]?
    let UUID: XMLString?
    let iconID: XMLString?
    let times: Times?
    
    public static func deserialize(_ element: XMLIndexer) throws -> Entry {
        
        
        return try Entry(KeyVals: element["String"].value(),
                         UUID: element["UUID"].value(),
                         iconID: element["IconID"].value(),
                         times: element["Times"].value())
    }
    
    public func serialize(base64Encoded: Bool, streamCipher: StreamCipher?) throws -> String {
        let keyvalsString = try? KeyVals?.map({ kv in
            return try kv.serialize(streamCipher: streamCipher)
        }).joined(separator: "\n")
        return try """
<Entry>
    \(UUID?.serialize() ?? "")
    \(iconID?.serialize() ?? "")
    \(times?.serialize() ?? "")
    \(keyvalsString ?? "")
</Entry>
"""
    }
}
