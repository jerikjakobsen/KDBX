//
//  KDBXTests.swift
//  
//
//  Created by John Jakobsen on 7/26/23.
//

import Foundation
import XCTest
import XML
@testable import KDBX

@available(iOS 13.0, *)
@available(macOS 13.0, *)
class KDBXTests: XCTestCase {
    func helperRelativePath(path: String) -> URL {
        // Get the current file URL
        let currentFileURL = URL(fileURLWithPath: #file)

        // Get the directory URL
        let directoryURL = currentFileURL.deletingLastPathComponent()

        // Create the file URL for the "Passwords.kdbx" file
        return directoryURL.appendingPathComponent(path)
    }
    
        func helperCreateMockManager() throws -> KDBX {
            let mockDB = try KDBX(title: "Test", description: "")
            mockDB.meta.setGenerator("KeePassXC")
            let entry1 = EntryXML(name: "Testing")
            let keyVals1 = [
                KeyValXML(key: "Notes", value: ""),
                KeyValXML(key: "Password", value: "testing", protected: true),
                KeyValXML(key: "URL", value: ""),
                KeyValXML(key: "UserName", value: "John"),
            ]
            for kv in keyVals1 {
                entry1.addKeyVal(keyVal: kv)
            }
            mockDB.group.addEntry(entry: entry1)
    
            let entry2 = EntryXML(name: "Testing2")
            let keyVals2 = [
                KeyValXML(key: "Notes", value: ""),
                KeyValXML(key: "Password", value: "testing2", protected: true),
                KeyValXML(key: "URL", value: ""),
                KeyValXML(key: "UserName", value: "john"),
            ]
            for kv in keyVals2 {
                entry2.addKeyVal(keyVal: kv)
            }
            mockDB.group.addEntry(entry: entry2)
            mockDB.group.setIconID(iconID: "48")
    
            return mockDB
        }
    
    func testKDBXFromRead() throws {
        let stream = InputStream(url: helperRelativePath(path: "EncryptedPasswords.kdbx"))
        stream?.open()
        let kdbx = try KDBX.fromEncryptedStream(stream!, password: "butter")
        stream?.close()
        print(kdbx.meta)
        print(kdbx.group)
        
        let mockDB = try helperCreateMockManager()
        XCTAssertTrue(mockDB.meta.isEqual(kdbx.meta))
        XCTAssertTrue(mockDB.group.isEqual(kdbx.group))
    }
    
    func testEncryption() throws {
        let mockKDBX = try helperCreateMockManager()
        let stream = OutputStream(url: helperRelativePath(path: "MockEncryptedPasswords.kdbx"), append: false)
        stream?.open()
        try mockKDBX.encryptToStream(stream!, password: "butter")
        stream?.close()
        
        let mockEncryptedStream = InputStream(url: helperRelativePath(path: "MockEncryptedPasswords.kdbx"))
        mockEncryptedStream?.open()
        let mockKDBXFromEncryptedFile = try KDBX.fromEncryptedStream(mockEncryptedStream!, password: "butter")
        mockEncryptedStream?.close()
        XCTAssertTrue(mockKDBX.meta.isEqual(mockKDBXFromEncryptedFile.meta))
        XCTAssertTrue(mockKDBX.group.isEqual(mockKDBXFromEncryptedFile.group))
    }
    
}
