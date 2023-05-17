//
//  KDBXXMLParser.swift
//  
//
//  Created by John Jakobsen on 5/8/23.
//

import Foundation
import SWXMLHash
import StreamCiphers
import CryptoKit

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
public class XMLManager {
    
    public let XMLData: Data
    public private(set) var entries: [Entry] = []
    public private(set) var meta: Meta? = nil
    private let chachaStream: ChaChaStream
    
    enum ParserError: Error {
        case UnexpectedNilOnOptional
    }
    
    public init(XMLData: Data, cipherKey: Data) throws {
        self.XMLData = XMLData
        //TODO: This is only for ChaCha20 stream cipher, will not work with others
        let hashedKey = Data(SHA512.hash(data: cipherKey))
        
        let key = hashedKey.prefix(32)
        let nonce = hashedKey.subdata(in: 32..<(32 + 12))
        
        self.chachaStream = try ChaChaStream(key: key, nonce: nonce)
        try self.processXMLData()
    }
    
    private func processXMLData() throws {
        guard let xmlString = String(data: self.XMLData, encoding: .utf8) else {
            throw ParserError.UnexpectedNilOnOptional
        }
        let xmlParser = XMLHash.parse(xmlString)
        self.meta = try xmlParser["KeePassFile"]["Meta"].value()
        self.entries = xmlParser["KeePassFile"]["Root"]["Group"]["Entry"].all.map { entry in
            let keyvals: [KeyVal?] = entry["String"].all.map { keyval in
                return try? KeyVal.deserialize(keyval, streamCipher: self.chachaStream)
            }
            let times: Times? = try? entry["Times"].value()
            let uuid: String? = try? entry["UUID"].value()
            let iconID: String? = try? entry["IconID"].value()
            
            return Entry(KeyVals: keyvals, UUID: uuid, iconID: iconID, times: times)
        }
    }
    
}
