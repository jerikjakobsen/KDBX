//
//  File.swift
//  
//
//  Created by John Jakobsen on 4/17/23.
//

import XCTest
@testable import KDBX

final class KDBXHeaderTests: XCTestCase {
    
    func testParseOuterHeader() throws {
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
            let header = try KDBXHeader.fromStream(stream!, password: "butter")
            XCTAssertNotNil(header)
            let cipherID = "0x31C1F2E6BF714350BE5805216AFC5AFF"
            let compressionFlag = true
            let masterSeedLength = 32
            let encryptionIVLength = 16
            XCTAssertNotNil(header.cipherID)
            XCTAssertEqual(cipherID, header.cipherID!.toHexString())
            XCTAssertNotNilAndEqual(header.compressionFlag, compressionFlag, "Compression flag not equal")
            XCTAssertNotNil(header.encryptionKey)
            XCTAssertEqual(header.encryptionKey?.count, masterSeedLength)
            XCTAssertEqual(header.encryptionIV?.count, encryptionIVLength)
            stream?.close()
        }
    }
    
    func XCTAssertNotNilAndEqual<T: Equatable>(_ optionalValue: T?, _ expectedValue: T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotNil(optionalValue, "Value is nil. " + message(), file: file, line: line)
        if let unwrappedValue = optionalValue {
            XCTAssertEqual(unwrappedValue, expectedValue, message(), file: file, line: line)
        }
    }
    
    @available(iOS 13.0, *)
    @available(macOS 13.0, *)
    func testEncodeHeader() throws {
        let header = try KDBXHeader()
        let attemptedHeaderData = try header.convertToData(password: "butter")
        let readStream = InputStream(data: attemptedHeaderData)
        let headerFromWrite = try KDBXHeader.fromStream(readStream, password: "butter")
        XCTAssertEqual(header.cipherID, headerFromWrite.cipherID)
    }
}
