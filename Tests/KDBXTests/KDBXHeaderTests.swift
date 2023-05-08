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
            let header = try KDBXHeader(stream: stream!)
            XCTAssertNotNil(header)
            let cipherID = "0x31C1F2E6BF714350BE5805216AFC5AFF"
            let compressionFlag = true
            let masterSeedLength = 32
            let encryptionIVLength = 16
            XCTAssertNotNil(header.cipherID)
            XCTAssertEqual(cipherID, uint8ArrayToHexString(header.cipherID!))
            XCTAssertNotNilAndEqual(header.compressionFlag, compressionFlag, "Compression flag not equal")
            XCTAssertNotNil(header.masterSeed)
            XCTAssertEqual(header.masterSeed?.count, masterSeedLength)
            XCTAssertEqual(header.encryptionIV?.count, encryptionIVLength)
            AssertKDFParametersHelper(kdfParameters: header.kdfParameters)
            stream?.close()
        }
    }
    
    func AssertKDFParametersHelper(kdfParameters: KDFParameters?) {
        let UUID = "0xEF636DDF8C29444B91F7A9A403E30A0C"
        let saltLength = 32
        let P: UInt32 = 2
        let M: UInt64 = 67108864
        let I: UInt64 = 19
        let V: UInt32 = 19
        XCTAssertNotNil(kdfParameters)
        if let params = kdfParameters {
            XCTAssertNotNil(params.UUID)
            XCTAssertEqual(uint8ArrayToHexString(params.UUID), UUID)
            XCTAssertNotNil(params.SArgon)
            XCTAssertEqual(params.SArgon?.count, saltLength)
            XCTAssertNotNilAndEqual(params.P, P)
            XCTAssertNotNilAndEqual(params.M, M)
            XCTAssertNotNilAndEqual(params.I, I)
            XCTAssertNotNilAndEqual(params.V, V)
        }
    }
    
    func XCTAssertNotNilAndEqual<T: Equatable>(_ optionalValue: T?, _ expectedValue: T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotNil(optionalValue, "Value is nil. " + message(), file: file, line: line)
        if let unwrappedValue = optionalValue {
            XCTAssertEqual(unwrappedValue, expectedValue, message(), file: file, line: line)
        }
    }
}
