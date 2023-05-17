//
//  StreamCiphers.swift
//  
//
//  Created by John Jakobsen on 5/10/23.
//

import Foundation
import CryptoSwift

public class ChaChaStream: StreamCipher {
    
    private let chacha: ChaCha20
    private var offset: Int = 0
    
    public init(key: Data, nonce: Data) throws {
        self.chacha = try ChaCha20(key: key.bytes, iv: nonce.bytes)
    }
    
    public func decrypt(encryptedData: Data) throws -> Data {
        let paddedData = padDataWithDummyBytes(data: encryptedData, paddingLength: offset)
        let decryptedDataWithPad = try Data(chacha.decrypt(paddedData.bytes))
        let decryptedData = decryptedDataWithPad.subdata(in: offset..<decryptedDataWithPad.count)
        offset += encryptedData.bytes.count
        
        return decryptedData
    }
    
    public func encrypt(data: Data) throws {
        //TODO: Implement Encrypt
    }
    
    private func padDataWithDummyBytes(data: Data, paddingLength: Int) -> Data {
        if (paddingLength <= 0) {
            return data
        }
        let dummyBytes = Data(repeating: 0x00, count: paddingLength)
        return dummyBytes + data
    }
}
