//
//  KDBXBodyHelpers.swift
//  
//
//  Created by John Jakobsen on 7/24/23.
//

import Foundation
import CryptoKit
import Encryption

@available(iOS 13.0, *)
@available(macOS 13.0, *)
func HMACKeyForBlockIndex(index: UInt64, baseHMACKey: Data?) throws -> Data {
    guard let key: Data = baseHMACKey else {throw KDBXBodyError.KeyCreationUnsuccessful}
    return Data(SHA512.hash(data: withUnsafeBytes(of: index.littleEndian) {Data($0)} + key))
}

@available(iOS 13.0, *)
@available(macOS 13.0, *)
func readAllData(from stream: InputStream) throws -> Data {
    if (stream.streamStatus == .notOpen) {
        stream.open()
    }
    let bufferSize = 4096
    var data = Data()
    while stream.hasBytesAvailable {
        let bytesRead = try stream.readNBytes(n: bufferSize)
        data += bytesRead
    }
    return data
}

func decryptData(encryptedData: Data, key: Data, encryptionIV: Data, cipher: Cipher) throws -> Data? {
    switch (cipher) {
    case .AES128CBC:
        // TODO: Check implementation of AES 128 CBC cipher
        return decryptAESCBC(data: encryptedData, key: key, iv: Data(encryptionIV), type: .s128)
    case .AES256CBC:
        return decryptAESCBC(data: encryptedData, key: key, iv: Data(encryptionIV), type: .s256)
    case .ChaCha20:
        //TODO: Implement chacha20
        break
    case .TwofishCBC:
        //TODO: Implement twofish
        break
    }
    throw KDBXBodyError.DecryptionFailed
}

func encryptData(decryptedData: Data, key: Data, encryptionIV: Data, cipher: Cipher) throws -> Data {
    switch (cipher) {
    case .AES128CBC:
        // TODO: Check implementation of AES 128 CBC cipher
        guard let encryptedData = encryptAESCBC(data: decryptedData, key: key, iv: encryptionIV, type: .s128) else {
            throw KDBXBodyError.EncryptionFailed
        }
        return encryptedData
    case .AES256CBC:
        guard let encryptedData = encryptAESCBC(data: decryptedData, key: key, iv: Data(encryptionIV), type: .s256) else {
            throw KDBXBodyError.EncryptionFailed
        }
        return encryptedData
    case .ChaCha20:
        //TODO: Implement chacha20
        break
    case .TwofishCBC:
        //TODO: Implement twofish
        break
    }
    throw KDBXBodyError.EncryptionFailed
}
