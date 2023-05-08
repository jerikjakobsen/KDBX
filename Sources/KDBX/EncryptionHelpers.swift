//
//  File.swift
//  
//
//  Created by John Jakobsen on 4/22/23.
//

import Foundation
import CommonCrypto

enum AESType {
    case s256
    case s128
}

func encryptAESCBC(data: Data, key: Data, iv: Data, type: AESType) -> Data? {
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

func decryptAESCBC(data: Data, key: Data, iv: Data, type: AESType) -> Data? {
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
