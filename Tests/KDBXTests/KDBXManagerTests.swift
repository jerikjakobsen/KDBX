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
@available(macOS 10.15, *)
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
    
    func testManagerEntries() throws {
        let manager = try helperCreateManager()
        
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
        let mockManager = KDBXManager()
        mockManager.setDBName(name: "Test")
        mockManager.setDBDescription(description: "")
        
    }
    
}
