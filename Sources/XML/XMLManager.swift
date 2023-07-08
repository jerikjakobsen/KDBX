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
    
    //public let XMLData: Data?
    public private(set) var group: Group? = nil
    public private(set) var meta: Meta? = nil
    private let chachaStream: ChaChaStream?
    
    enum ParserError: Error {
        case UnexpectedNilOnOptional
    }
    
    public init(XMLData: Data, cipherKey: Data) throws {
        //TODO: This is only for ChaCha20 stream cipher, will not work with others
        let hashedKey = Data(SHA512.hash(data: cipherKey))
        
        let key = hashedKey.prefix(32)
        let nonce = hashedKey.subdata(in: 32..<(32 + 12))
        
        let chachaStream = try ChaChaStream(key: key, nonce: nonce)
        self.chachaStream = chachaStream
        guard let xmlString = String(data: XMLData, encoding: .utf8) else {
            throw ParserError.UnexpectedNilOnOptional
        }
        let xmlParser = XMLHash.parse(xmlString)
        self.meta = try xmlParser["KeePassFile"]["Meta"].value()
        self.group = try Group.deserialize(xmlParser["KeePassFile"]["Root"]["Group"], streamCipher: chachaStream)
        self.group?.modifyListener = self.meta
    }
    
    public init(databaseName: String = "", databaseDescription: String = "") {
        // Initializer when creating a new database
        self.group = Group()
        self.meta = Meta(generator: "Keys", databaseName: databaseName, databaseDescription: databaseDescription)
        self.group?.modifyListener = self.meta
        self.chachaStream = nil
    }
    
//    public func modifyMeta(databaseName: String? = nil, databaseDescription: String? = nil) {
//        self.meta = self.meta?.modify(newDatabaseName: databaseName, newDatabaseDescription: databaseDescription)
//    }
    //TODO: Replace self.chachastream with parameter
    public func toXML() throws -> String {
//        let hashedKey = Data(SHA512.hash(data: cipherKey))
//
//        let key = hashedKey.prefix(32)
//        let nonce = hashedKey.subdata(in: 32..<(32 + 12))
//
//        let chachaStream = try ChaChaStream(key: key, nonce: nonce)
        return try """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <KeePassFile>
                \(self.meta?.serialize(base64Encoded: true, streamCipher: self.chachaStream) ?? "")
                <Root>
                    \(self.group?.serialize(base64Encoded: true, streamCipher: self.chachaStream) ?? "")
                <Root>
            </KeePassFile>
        """
    }
    
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
extension XMLManager: Equatable {
    public static func == (lhs: XMLManager, rhs: XMLManager) -> Bool {
        return (lhs.meta == rhs.meta &&
                lhs.group == rhs.group)
    }
}
