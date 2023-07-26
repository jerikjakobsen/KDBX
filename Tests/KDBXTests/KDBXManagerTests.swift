//
//  KDBXManagerTests.swift
//
//
//  Created by John Jakobsen on 4/17/23.
//

import XCTest
import XML
@testable import KDBX

@available(iOS 13.0, *)
@available(macOS 13.0, *)
final class KDBXManagerTests: XCTestCase {
    
    // Test the manager properly decrypts file
    func testManagerDecryption() throws {
        let currentFileURL = URL(fileURLWithPath: #file)
        let directoryURL = currentFileURL.deletingLastPathComponent()
        let passwordsDecryptedFileURL = directoryURL.appendingPathComponent("DecryptedPasswords.xml")
        let passwordsDecryptedFileString = NSURL(string: passwordsDecryptedFileURL.absoluteString)?.path
        
        let manager = try helperCreateManager()
        let decryptedXMLData = manager.XMLData
        
        let fileManager = FileManager()
        XCTAssertEqual(fileManager.contents(atPath: passwordsDecryptedFileString!), decryptedXMLData)
    }
    
    func testManagerDecoding() throws {
        let mockManager = try helperCreateMockManager().xmlManager
        let managerFromDecryption = try helperCreateManager().xmlManager
        
        XCTAssertTrue(mockManager.equalContents(managerFromDecryption))
    }
    
    func testManagerDecodeEncode() throws {
        let managerFromDecryption = try helperCreateManager()
        let chachastream = managerFromDecryption.xmlManager.chachaStream
        let xmlString = try managerFromDecryption.xmlManager.toXML(streamCipher: chachastream!)
        chachastream?.reset()
        let copyXMLManager = try XMLManager(XMLData: xmlString.data(using: .utf8)!, cipherKey: managerFromDecryption.body!.streamKey!)
        XCTAssertTrue(copyXMLManager.equalContents(managerFromDecryption.xmlManager))
        
    }
    
    func helperCreateManager() throws -> KDBXManager {
        return try KDBXManager(password: "butter", fileURL: helperRelativePath(path: "Passwords.kdbx"))
    }
    
    func helperRelativePath(path: String) -> URL {
        // Get the current file URL
        let currentFileURL = URL(fileURLWithPath: #file)

        // Get the directory URL
        let directoryURL = currentFileURL.deletingLastPathComponent()

        // Create the file URL for the "Passwords.kdbx" file
        return directoryURL.appendingPathComponent(path)
    }
    
    func helperCreateMockManager() throws -> KDBXManager {
        let mockManager = KDBXManager(generator: "KeePassXC")
        mockManager.setDBName(name: "Test")
        mockManager.setDBDescription(description: "")
        let entry1 = Entry(name: "Testing")
        let keyVals1 = [
            KeyVal(key: "Notes", value: ""),
            KeyVal(key: "Password", value: "testing", protected: true),
            KeyVal(key: "URL", value: ""),
            KeyVal(key: "UserName", value: "John"),
        ]
        for kv in keyVals1 {
            entry1.addKeyVal(keyVal: kv)
        }
        mockManager.addEntry(entry: entry1)
        
        let entry2 = Entry(name: "Testing2")
        let keyVals2 = [
            KeyVal(key: "Notes", value: ""),
            KeyVal(key: "Password", value: "testing2", protected: true),
            KeyVal(key: "URL", value: ""),
            KeyVal(key: "UserName", value: "john"),
        ]
        for kv in keyVals2 {
            entry2.addKeyVal(keyVal: kv)
        }
        mockManager.addEntry(entry: entry2)
        mockManager.xmlManager.group?.setIconID(iconID: "48")
        
        return mockManager
    }
    
    func testEncryption() throws {
        let manager = try helperCreateManager()
        try manager.save(fileURL: helperRelativePath(path: "EncryptedPasswords.kdbx"), password: "butter")
        
        let managerFromEncrypted = try KDBXManager(password: "butter", fileURL: helperRelativePath(path: "EncryptedPasswords.kdbx"))
        XCTAssertTrue(manager.xmlManager.meta?.isEqual(managerFromEncrypted.xmlManager.meta) ?? false)
        XCTAssertTrue(manager.xmlManager.group?.isEqual(managerFromEncrypted.xmlManager.group) ?? false)
        
        try managerFromEncrypted.save(fileURL: helperRelativePath(path: "EncryptedPasswords2.kdbx"), password: "butter")
        
        let managerFromEncrypted2 = try KDBXManager(password: "butter", fileURL: helperRelativePath(path: "EncryptedPasswords2.kdbx"))
        
        XCTAssertTrue(managerFromEncrypted.xmlManager.meta?.isEqual(managerFromEncrypted2.xmlManager.meta) ?? false)
        XCTAssertTrue(managerFromEncrypted.xmlManager.group?.isEqual(managerFromEncrypted2.xmlManager.group) ?? false)
    }
    
    func testMockEncryption() throws {
        let mockManager = try helperCreateMockManager()
        
        try mockManager.save(fileURL: helperRelativePath(path: "MockEncryptedPasswords.kdbx"), password: "butter")
        let managerFromMockEncrypted = try KDBXManager(password: "butter", fileURL: helperRelativePath(path: "MockEncryptedPasswords.kdbx"))
        XCTAssertTrue(mockManager.xmlManager.meta?.isEqual(managerFromMockEncrypted.xmlManager.meta) ?? false)
        XCTAssertTrue(mockManager.xmlManager.group?.isEqual(managerFromMockEncrypted.xmlManager.group) ?? false)
    }
}
