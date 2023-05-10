//
//  KDBXManagerTests.swift
//
//
//  Created by John Jakobsen on 4/17/23.
//

import XCTest
@testable import KDBX

final class KDBXManagerTests: XCTestCase {
    
    func testManagerInit() throws {
        if #available(macOS 13.0, *) {
            let fileName = "Passwords.kdbx"

            // Get the current file URL
            let currentFileURL = URL(fileURLWithPath: #file)

            // Get the directory URL
            let directoryURL = currentFileURL.deletingLastPathComponent()

            // Create the file URL for the "Passwords.kdbx" file
            let fileURL = directoryURL.appendingPathComponent(fileName)
            XCTAssertNotNil(fileURL)
            let stream: InputStream? = InputStream(url: fileURL)
            XCTAssertNotNil(stream)
            stream!.open()
            let manager = try KDBXManager(password: "butter", stream: stream!)
            let xmlParser = try KDBXXMLParser(XMLData: manager.body.cleanInnerData!)
            stream?.close()
        }
    }
    
}
