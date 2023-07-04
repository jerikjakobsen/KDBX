//
//  KDBXManagerTests.swift
//
//
//  Created by John Jakobsen on 4/17/23.
//

import XCTest
import XML
@testable import KDBX

final class KDBXManagerTests: XCTestCase {
    
    func testManagerInit() throws {
        if #available(macOS 13.0, *) {
            let fileName = "Passwords2.kdbx"

            // Get the current file URL
            let currentFileURL = URL(fileURLWithPath: #file)

            // Get the directory URL
            let directoryURL = currentFileURL.deletingLastPathComponent()

            // Create the file URL for the "Passwords.kdbx" file
            let fileURL = directoryURL.appendingPathComponent(fileName)
            XCTAssertNotNil(fileURL)
            let manager = try KDBXManager(password: "butter", fileURL: fileURL)
            print(try manager.XMLParser.toXML())
        }
    }
    
}
