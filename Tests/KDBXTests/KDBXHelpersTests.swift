import XCTest
@testable import KDBX

final class KDBXHelpersTests: XCTestCase {
    func testBytesToSignedInt() throws {
        let storedNum64: [UInt8] = [0x21, 0x43, 0xFF, 0xFF, 0x21, 0x43, 0xFF, 0xFF] // 64 bits
        let storedNum32: [UInt8] = [0x21, 0x43, 0xFF, 0xFF] // 32 bits
        let storedNum16: [UInt8] = [0x21, 0xFF] // 16 bits
        let convertedNum64: Int64 = bytesToSignedInteger(storedNum64)
        let convertedNum32: Int32 = bytesToSignedInteger(storedNum32)
        let convertedNum16: Int16 = bytesToSignedInteger(storedNum16)
        XCTAssertEqual(convertedNum64, -207661668809951)
        XCTAssertEqual(convertedNum32, -48351)
        XCTAssertEqual(convertedNum16, -223)
    }
    
    func testBytesToUnsignedInt() throws {
        let storedNum64: [UInt8] = [0x21, 0x43, 0xFF, 0xFF, 0x21, 0x43, 0xFF, 0xFF] // 64 bits
        let storedNum32: [UInt8] = [0x21, 0x43, 0xFF, 0xFF] // 32 bits
        let storedNum16: [UInt8] = [0x21, 0xFF] // 16 bits
        let convertedNum64: UInt64 = bytesToUnsignedInteger(storedNum64)
        let convertedNum32: UInt32 = bytesToUnsignedInteger(storedNum32)
        let convertedNum16: UInt16 = bytesToUnsignedInteger(storedNum16)
        XCTAssertEqual(convertedNum64, 18446536412040741665)
        XCTAssertEqual(convertedNum32, 4294918945)
        XCTAssertEqual(convertedNum16, 65313)
    }
    
    func testUinttoIntConversion() throws {
        let storedNum64: UInt64 = 18446536412040741665
        let storedNum32: UInt32 = 4294918945
        let storedNum16: UInt16 = 65313
        let correctRes64: Int64 = -207661668809951
        let correctRes32: Int32 = -48351
        let correctRes16: Int16 = -223
        
        let res64: Int64 = unsignedToSigned(storedNum64)
        let res32: Int32 = unsignedToSigned(storedNum32)
        let res16: Int16 = unsignedToSigned(storedNum16)
        XCTAssertEqual(correctRes64, res64)
        XCTAssertEqual(correctRes32, res32)
        XCTAssertEqual(correctRes16, res16)
    }
    
    func testUIntArrtoString() throws {
        let storedNum: [UInt8] = [0x21, 0x43, 0xFF, 0xFF]
        XCTAssertEqual(uint8ArrayToHexString(storedNum), "0x2143FFFF")
    }
    
}
