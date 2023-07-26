//
//  StreamCiphers.swift
//  
//
//  Created by John Jakobsen on 5/10/23.
//

import Foundation
import CryptoSwift
import Encryption

public class ChaChaStream: StreamCipher {
    
    private var chacha: ChaCha20
    private var key: Data
    private var nonce: Data
    private var encryptOffset: Int = 0
    private var decryptOffset: Int = 0
    
    public init(key: Data, nonce: Data) throws {
        self.chacha = try ChaCha20(key: key.bytes, iv: nonce.bytes)
        self.key = key
        self.nonce = nonce
    }
    
    public func decrypt(encryptedData: Data) throws -> Data {
        let paddedData = padDataWithDummyBytes(data: encryptedData, paddingLength: decryptOffset)
        let decryptedDataWithPad = try Data(chacha.decrypt(paddedData.bytes))
        let decryptedData = decryptedDataWithPad.subdata(in: decryptOffset..<decryptedDataWithPad.count)
        decryptOffset += encryptedData.bytes.count
        
        return decryptedData
    }
    
    public func encrypt(data: Data) throws -> Data {
        let paddedData = padDataWithDummyBytes(data: data, paddingLength: encryptOffset)
        let encryptedDataWithPad = try Data(chacha.encrypt(paddedData.bytes))
        let encryptedData = encryptedDataWithPad.subdata(in: encryptOffset..<encryptedDataWithPad.count)
        encryptOffset += data.bytes.count

        return encryptedData
    }
    
    public func refresh(key: Data, nonce: Data) throws {
        self.key = key
        self.nonce = nonce
        self.encryptOffset = 0
        self.decryptOffset = 0
        self.chacha = try ChaCha20(key: key.bytes, iv: nonce.bytes)
    }
    
    public func reset() {
        encryptOffset = 0
        decryptOffset = 0
    }
    
    private func padDataWithDummyBytes(data: Data, paddingLength: Int) -> Data {
        if (paddingLength <= 0) {
            return data
        }
        let dummyBytes = Data(repeating: 0x00, count: paddingLength)
        return dummyBytes + data
    }
}
