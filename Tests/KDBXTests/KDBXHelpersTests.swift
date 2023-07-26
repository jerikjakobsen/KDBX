import XCTest
@testable import KDBX

final class KDBXHelpersTests: XCTestCase {
    func testBytesToSignedInt() throws {
        let storedNum64: Data = Data([0x21, 0x43, 0xFF, 0xFF, 0x21, 0x43, 0xFF, 0xFF]) // 64 bits
        let storedNum32: Data = Data([0x21, 0x43, 0xFF, 0xFF]) // 32 bits
        let storedNum16: Data = Data([0x21, 0xFF]) // 16 bits
        let convertedNum64: Int64 = storedNum64.toSignedInteger()
        let convertedNum32: Int32 = storedNum32.toSignedInteger()
        let convertedNum16: Int16 = storedNum16.toSignedInteger()
        XCTAssertEqual(convertedNum64, -207661668809951)
        XCTAssertEqual(convertedNum32, -48351)
        XCTAssertEqual(convertedNum16, -223)
    }
    
    func testBytesToUnsignedInt() throws {
        let storedNum64: Data = Data([0x21, 0x43, 0xFF, 0xFF, 0x21, 0x43, 0xFF, 0xFF]) // 64 bits
        let storedNum32: Data = Data([0x21, 0x43, 0xFF, 0xFF]) // 32 bits
        let storedNum16: Data = Data([0x21, 0xFF]) // 16 bits
        let convertedNum64: UInt64 = storedNum64.toUnsignedInteger()
        let convertedNum32: UInt32 = storedNum32.toUnsignedInteger()
        let convertedNum16: UInt16 = storedNum16.toUnsignedInteger()
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
        let storedNum: Data = Data([0x21, 0x43, 0xFF, 0xFF])
        XCTAssertEqual(storedNum.toHexString(), "0x2143FFFF")
    }
    
    func testStringToUintArr() {
        let testString: String = "0x31C1F2E6BF714350BE5805216AFC5AFF"
        let arr = stringToUInt8Array(testString)
        print(arr)
    }
    
    func testHexStringToUIntArr() throws {
        let testString: String = "0x31C1F2E6BF714350BE5805216AFC5AFF"
        let uint8Arr = hexStringToData(testString)
        let testResult: Data = Data([49, 193, 242, 230, 191, 113, 67, 80, 190, 88, 5, 33, 106, 252, 90, 255])
        XCTAssertEqual(testResult, uint8Arr)
    }
    
    func testUIntToData() {
        var testUInt: UInt32 = 0x9AA2D903
        let data: Data = testUInt.data
        XCTAssert(data.bytes == [3, 217, 162, 154])
    }
    
}
