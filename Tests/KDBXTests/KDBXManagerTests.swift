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
        let xmlString = try managerFromDecryption.xmlManager.toXML()
        chachastream?.reset()
        let copyXMLManager = try XMLManager(xmlString: xmlString, chachaStream: chachastream!)
        XCTAssertTrue(copyXMLManager.equalContents(managerFromDecryption.xmlManager))
        
    }
    
    func helperCreateManager() throws -> KDBXManager {
        // Get the current file URL
        let currentFileURL = URL(fileURLWithPath: #file)

        // Get the directory URL
        let directoryURL = currentFileURL.deletingLastPathComponent()

        // Create the file URL for the "Passwords.kdbx" file
        let passwordsEncryptedFileURL = directoryURL.appendingPathComponent("Passwords.kdbx")
        
        return try KDBXManager(password: "butter", fileURL: passwordsEncryptedFileURL)
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
    
}
