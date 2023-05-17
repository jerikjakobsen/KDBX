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
}

func _pointerToArray(buffer: UnsafeMutablePointer<UInt8>, bufferSize: Int) -> [UInt8] {
    var bufferArray: [UInt8] = []
    for i in 0..<bufferSize {
        bufferArray.append(buffer[i])
    }
    return bufferArray
}

func uint8ArrayToHexString(_ byteArray: [UInt8]) -> String {
    var hexString = ""
    for byte in byteArray {
        hexString += String(format: "%02X", byte)
    }
    return "0x" + hexString
}


func convertUInt32ToInt32(value: UInt32) -> Int32 {
    return Int32(bitPattern: value)
}

func unsignedToSigned<T: FixedWidthInteger & SignedInteger, V: FixedWidthInteger & UnsignedInteger>(_ value: V) -> T {
    let data = withUnsafeBytes(of: value) { Data($0) }
    return data.withUnsafeBytes { $0.load(as: T.self) }
}


func bytesToSignedInteger<T: FixedWidthInteger & SignedInteger>(_ byteArray: [UInt8]) -> T {
    // Stored as little endian
    let data = Data(byteArray)
    return T(littleEndian: data.withUnsafeBytes { $0.load(as: T.self) })
}

func bytesToUnsignedInteger<T: FixedWidthInteger & UnsignedInteger>(_ byteArray: [UInt8]) -> T {
    // Stored as little endian
    let data = Data(byteArray)
    return T(littleEndian: data.withUnsafeBytes { $0.load(as: T.self) })
}

func bytesToUTF8String(_ bytes: [UInt8]) throws -> String {
    guard let str = String(bytes: bytes, encoding: .utf8) else {throw HelperError.String}
    
    return str.lowercased()
}

func stringToUInt8Array(_ input: String) -> [UInt8] {
    let utf8Data = input.data(using: .utf8)
    return utf8Data?.map { UInt8($0) } ?? []
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
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
}
