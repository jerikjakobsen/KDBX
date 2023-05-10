//
//  KDBXXMLParser.swift
//  
//
//  Created by John Jakobsen on 5/8/23.
//

import Foundation
import SWXMLHash

struct KeyVal {
    let key: String?
    let value: String?
}

struct Entry {
    let KeyVals: [KeyVal]
    let UUID: String
    let iconID: String
    let creationTime: Date
    let lastModifiedTime: Date
    let lastAccessTime: Date
    
}

class KDBXXMLParser {
    
    let XMLData: Data
    var entries: [Entry] = []
    
    enum ParserError: Error {
        case UnexpectedNilOnOptional
    }
    
    init(XMLData: Data) throws {
        self.XMLData = XMLData
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
                print("Key: \(key) Val: \(val)")
                return KeyVal(key: key, value: val)
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
