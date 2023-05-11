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

struct KeyVal {
    let key: String?
    let value: String?
    let protected: Bool
}

struct Entry {
    let KeyVals: [KeyVal]
    let UUID: String
    let iconID: String
    let creationTime: Date
    let lastModifiedTime: Date
    let lastAccessTime: Date
    
}
@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
class KDBXXMLParser {
    
    let XMLData: Data
    var entries: [Entry] = []
    private let chachaStream: ChaChaStream
    
    enum ParserError: Error {
        case UnexpectedNilOnOptional
    }
    
    init(XMLData: Data, cipherKey: Data) throws {
        self.XMLData = XMLData
        //TODO: This is only for ChaCha20 stream cipher, will not work with others
        let hashedKey = Data(SHA512.hash(data: cipherKey))
        
        let key = hashedKey.prefix(32)
        let nonce = hashedKey.subdata(in: 32..<(32 + 12))
        
        self.chachaStream = try ChaChaStream(key: key, nonce: nonce)
        try self.processXMLData()
        print(entries)
    }
    
    private func processXMLData() throws {
        guard let xmlString = String(data: self.XMLData, encoding: .utf8) else {
            throw ParserError.UnexpectedNilOnOptional
        }
        let xmlParser = XMLHash.parse(xmlString)
        print(xmlParser)
        self.entries = try xmlParser["KeePassFile"]["Root"]["Group"]["Entry"].all.map { entry in
            let keyvals: [KeyVal] = try entry["String"].all.map { keyval in
                guard let key = keyval["Key"].element?.text else {
                    throw ParserError.UnexpectedNilOnOptional
                }
                guard let val = keyval["Value"].element?.text else {
                    throw ParserError.UnexpectedNilOnOptional
                }
                let protected = keyval["Value"].element?.attribute(by: "Protected")?.text ?? "False" == "True"
                //Base 64 decode, decrypt with chacha20
                var value = val
                if (protected) {
                    // This assumes all protected fields are base64 encoded
                    guard let base64Decoded = Data(base64Encoded: val) else {
                        throw ParserError.UnexpectedNilOnOptional
                    }
                    print("Decoded String")
                    let decryptedData = try chachaStream.decrypt(encryptedData: base64Decoded)
                    
                    guard let decryptedString = try String(data: decryptedData, encoding: .utf8) else {
                        throw ParserError.UnexpectedNilOnOptional
                    }
                    print("Decrypted")
                    value = decryptedString
                }
                print("Key: \(key) Val: \(value) Protected: \(protected ? "Y" : "N")")
                return KeyVal(key: key, value: value, protected: protected)
            }
            
            let times = entry["Times"]
            guard let creationTimeText = times["CreationTime"].element?.text else {
                throw ParserError.UnexpectedNilOnOptional
            }
            let creationTimeDate = try convertToDate(s: creationTimeText)
            
            guard let lastModifiedTimeText = times["LastModificationTime"].element?.text else {
                throw ParserError.UnexpectedNilOnOptional
            }
            let lastModifiedTimeDate = try convertToDate(s: lastModifiedTimeText)
            
            guard let lastAccessTimeText = times["LastAccessTime"].element?.text else {
                throw ParserError.UnexpectedNilOnOptional
            }
            let lastAccessTimeDate = try convertToDate(s: lastAccessTimeText)
            
            guard let uuid = entry["UUID"].element?.text else {
                throw ParserError.UnexpectedNilOnOptional
            }
            guard let iconID = entry["IconID"].element?.text else {
                throw ParserError.UnexpectedNilOnOptional
            }
            return Entry(KeyVals: keyvals, UUID: uuid, iconID: iconID, creationTime: creationTimeDate, lastModifiedTime: lastModifiedTimeDate, lastAccessTime: lastAccessTimeDate)
        }
    }
    
    

}
