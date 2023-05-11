//
//  File.swift
//  
//
//  Created by John Jakobsen on 4/22/23.
//

import Foundation
import CommonCrypto
import CryptoKit
import Argon2Swift

public enum AESType {
    case s256
    case s128
}

public func encryptAESCBC(data: Data, key: Data, iv: Data, type: AESType) -> Data? {
    let cryptLength = size_t(data.count + kCCBlockSizeAES128)
    var cryptData = Data(count: cryptLength)
    
    var numBytesEncrypted: size_t = 0
    let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
        data.withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                iv.withUnsafeBytes { ivBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, type == .s128 ? kCCKeySizeAES128 : kCCKeySizeAES256,
                        ivBytes.baseAddress,
                        dataBytes.baseAddress, data.count,
                        cryptBytes.baseAddress, cryptLength,
                        &numBytesEncrypted
                    )
                }
            }
        }
    }
    
    if cryptStatus == kCCSuccess {
        cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
        return cryptData
    } else {
        return nil
    }
}

public func decryptAESCBC(data: Data, key: Data, iv: Data, type: AESType) -> Data? {
    let cryptLength = size_t(data.count)
    var cryptData = Data(count: cryptLength)
    
    var numBytesDecrypted: size_t = 0
    let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
        data.withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                iv.withUnsafeBytes { ivBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, type == .s128 ? kCCKeySizeAES128 : kCCKeySizeAES256,
                        ivBytes.baseAddress,
                        dataBytes.baseAddress, data.count,
                        cryptBytes.baseAddress, cryptLength,
                        &numBytesDecrypted
                    )
                }
            }
        }
    }
    
    if cryptStatus == kCCSuccess {
        cryptData.removeSubrange(numBytesDecrypted..<cryptData.count)
        return cryptData
    } else {
        return nil
    }
}

public func ArgonHash(password: Data, salt: Data, iterations: Int, memory: Int, parallelism: Int, keyType: String, version: Int) throws -> Data {
    let argonSalt = Salt(bytes: salt)
    return try Argon2Swift.hashPasswordBytes(password: password, salt: argonSalt, iterations: iterations, memory: memory, parallelism: parallelism, type: keyType == "Argon2d" ? .d : .id, version: version == 0x10 ? .V10 : .V13 ).hashData()
}
//
//import Sodium
//
//class ProtectedStreamDecryptor {
//    private let key: Data
//    private let sodium: Sodium
//
//    init(key: Data) {
//        self.key = key
//        self.sodium = Sodium()
//    }
//
//    func decryptChunk(encryptedChunk: Data) throws -> Data {
//        let uint8ArrayData = encryptedChunk.withUnsafeBytes { Array($0.bindMemory(to: UInt8.self)) }
//        let uint8ArrayKey = self.key.withUnsafeBytes { Array($0.bindMemory(to: UInt8.self)) }
//        let decryptedChunk = sodium.secretBox.open(nonceAndAuthenticatedCipherText: uint8ArrayData, secretKey: uint8ArrayKey)
//
//        guard let decryptedData = decryptedChunk else {
//            throw DecryptionError.decryptionFailed
//        }
//
//        return Data(decryptedData)
//    }
//}
//
//enum DecryptionError: Error {
//    case decryptionFailed
//    // Add more specific error cases if needed
//}
//
//
//
//
