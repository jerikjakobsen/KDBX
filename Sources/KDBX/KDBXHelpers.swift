//
//  File.swift
//  
//
//  Created by John Jakobsen on 4/15/23.
//

import Foundation
import CryptoKit
import CommonCrypto

enum HelperError: Error {
    case String
    case DataDecoding
    case DataConversion
    case UnableToReadStream
    case CannotOpenClosedStream
}

func _pointerToArray(buffer: UnsafeMutablePointer<UInt8>, bufferSize: Int) -> Data {
    var bufferArray: [UInt8] = []
    for i in 0..<bufferSize {
        bufferArray.append(buffer[i])
    }
    return Data(bufferArray)
}

func hexStringToData(_ str: String) -> Data {
    // Converts a hexadecimal string to Data
    return Data(hex: str)
}


func convertUInt32ToInt32(value: UInt32) -> Int32 {
    return Int32(bitPattern: value)
}

func boolToUInt8(value: Bool?) -> UInt8? {
    guard let notNilValue = value else {
        return nil
    }
    
    return notNilValue ? UInt8(1) : UInt8(0)
}

func unsignedToSigned<T: FixedWidthInteger & SignedInteger, V: FixedWidthInteger & UnsignedInteger>(_ value: V) -> T {
    let data = withUnsafeBytes(of: value) { Data($0) }
    return data.withUnsafeBytes { $0.load(as: T.self) }
}

func bytesToUTF8String(_ bytes: [UInt8]) throws -> String {
    guard let str = String(bytes: bytes, encoding: .utf8) else {throw HelperError.String}
    
    return str.lowercased()
}

func stringToUInt8Array(_ input: String) -> [UInt8] {
    // Turns the string into the utf-8 encoding of each character
    let utf8Data = input.data(using: .utf8)
    return utf8Data?.map { UInt8($0) } ?? []
}

@available(iOS 13.0, *)
@available(macOS 13.0, *)
func aesKDF(seed: Data, info: Data? = nil, outputKeyLength: Int) -> Data? {
    let blockSize = 16
    let numberOfBlocks = Int(ceil(Double(outputKeyLength) / Double(blockSize)))

    var derivedKeyData = Data()

    for counter in 1...numberOfBlocks {
        let counterData = Data([UInt8(counter)]).leftPadded(to: blockSize)
        let inputData = seed + counterData + (info ?? Data())

        do {
            let symmetricKey = SymmetricKey(data: seed)
            let sealedBox = try AES.GCM.seal(inputData, using: symmetricKey)
            let block = sealedBox.ciphertext

            derivedKeyData.append(block)
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil
        }
    }

    return derivedKeyData.prefix(outputKeyLength)
}

extension Data {
    func leftPadded(to size: Int) -> Data {
        if self.count >= size {
            return self
        }
        
        var paddedData = Data(repeating: 0, count: size - self.count)
        paddedData.append(self)
        return paddedData
    }
    
    func rightPadded(to size: Int) -> Data {
        if self.count >= size {
            return self
        }
        var copy = Data(self)
        let paddedData = Data(repeating: 0, count: size - self.count)
        copy.append(paddedData)
        return copy
    }
    
    func toHexString() -> String {
        var hexString = ""
        for byte in self.bytes {
            hexString += String(format: "%02X", byte)
        }
        return "0x" + hexString
    }
    
    func toUTF8String() throws -> String {
        guard let str = String(bytes: self.bytes, encoding: .utf8) else {throw HelperError.String}
        
        return str.lowercased()
    }
    
    func toSignedInteger<T: FixedWidthInteger & SignedInteger>() -> T {
        return T(littleEndian: self.withUnsafeBytes { $0.load(as: T.self) })
    }
    
    func toUnsignedInteger<T: FixedWidthInteger & UnsignedInteger>() -> T {
        return T(littleEndian: self.withUnsafeBytes { $0.load(as: T.self) })
    }
}


extension Int {
    var data: Data {
        var int = self.littleEndian
        return Data(bytes: &int, count: MemoryLayout<Int>.size)
    }
}

extension UInt8 {
    var data: Data {
        var int = self.littleEndian
        return Data(bytes: &int, count: MemoryLayout<UInt8>.size)
    }
}

extension UInt16 {
    var data: Data {
        var int = self.littleEndian
        return Data(bytes: &int, count: MemoryLayout<UInt16>.size)
    }
}

extension UInt32 {
    var data: Data {
        var int = self.littleEndian
        return Data(bytes: &int, count: MemoryLayout<UInt32>.size)
    }
}

extension UInt64 {
    var data: Data {
        var int = self.littleEndian
        return Data(bytes: &int, count: MemoryLayout<UInt64>.size)
    }
}

func Data(_ arr: [UInt8]?) -> Data? {
    guard let arrNotNil = arr else {
        return nil
    }
    let res: Data = Data(arrNotNil)
    return res
}

@available(iOS 13.0, *)
@available(macOS 13.0, *)
extension InputStream {
    func readNBytes(n: Int) throws -> Data {
        if (self.streamStatus == .notOpen) {
            self.open()
            guard self.streamStatus == .open else {
                throw HelperError.CannotOpenClosedStream
            }
        }
        let bufferSize = n
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        let bytesRead = self.read(buffer, maxLength: bufferSize)
        if bytesRead < 0 {
            throw self.streamError ?? HelperError.UnableToReadStream
        } else if bytesRead == 0 {
            return Data()
        }
        var arrSize = bufferSize
        if (bytesRead < n) {
            arrSize = bytesRead
        }
        let dataRead = _pointerToArray(buffer: buffer, bufferSize: arrSize)
        return dataRead
    }
}

extension OutputStream {
    @available(iOS 13.0, *)
    @available(macOS 13.0, *)
    func write(data: Data) throws {
        if (self.streamStatus == .notOpen) {
            self.open()
            guard self.streamStatus == .open else {
                throw HelperError.CannotOpenClosedStream
            }
        }
        guard self.hasSpaceAvailable else {
            throw KDBXBodyError.NoWriteSpace
        }
        let n = data.count
        try data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
            guard let pointerAddress = pointer.baseAddress else {
                throw KDBXBodyError.UnableToGetPointerAddress
            }
            let writeResult = self.write(pointerAddress, maxLength: n)
            if (writeResult == -1 || writeResult != n) {
                throw KDBXBodyError.UnableToWrite
            }
        }
    }
}
