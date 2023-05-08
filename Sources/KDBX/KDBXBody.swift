//
//  File.swift
//  
//
//  Created by John Jakobsen on 4/21/23.
//

import Foundation
import CryptoKit
import Argon2Swift

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
class KDBXBody {
    
    let header: KDBXHeader
    var encryptionKey: Data?
    var baseHMACKey: Data?
    var innerEncryptedData: Data?
    var innerDecryptedData: Data?
    enum KDBXBodyError: Error {
        case UnknownCipher
        case NoArgonSalt
        case NoArgonIterations
        case NoArgonMemory
        case NoArgonParallelism
        case NoArgonVersion
        case NoAESSalt
        case NoRounds
        case NoMasterSeed
        case KeyCreationUnsuccessful
        case BlockParseError
        case DataCompromised
        case NoEncryptionIV
        case NoData
        case NoKey
    }
    init(password: String, header: KDBXHeader, stream: InputStream) throws {
        self.header = header
        computeKeys(password: password)
        
    }
    
    func computeKeys(password: String) throws -> Data {
        //TODO: Check for keyfile, this implementation only uses the password
        let hashOnce = Data(SHA256.hash(data: Data(stringToUInt8Array(password))))
        let compositeKey = Data(SHA256.hash(data: hashOnce))
        var derivedKey: Data? = nil
        switch (self.header.kdfParameters?.keyType) {
            case .Argon2d:
            fallthrough
            case .Argon2id:
            guard let argSalt = self.header.kdfParameters?.SArgon else {throw KDBXBodyError.NoArgonSalt}
            guard let iterations = self.header.kdfParameters?.I else {throw KDBXBodyError.NoArgonIterations}
            guard let memory = self.header.kdfParameters?.M else {throw KDBXBodyError.NoArgonMemory}
            guard let parallelism = self.header.kdfParameters?.P else {throw KDBXBodyError.NoArgonParallelism}
            guard let version = self.header.kdfParameters?.V else {throw KDBXBodyError.NoArgonVersion}
            let salt = Salt(bytes: Data(argSalt))
            derivedKey = try Argon2Swift.hashPasswordBytes(password: compositeKey, salt: salt, iterations: Int(iterations), memory: Int(memory), parallelism: Int(parallelism), type: self.header.kdfParameters?.keyType == .Argon2d ? .d : .id, version: version == 0x10 ? .V10 : .V13 ).hashData()
                break
            case .AESKDF:
            // TODO: Check this over, currently not supported
            guard let AESSalt = self.header.kdfParameters?.S else {throw KDBXBodyError.NoAESSalt}
            guard let rounds = self.header.kdfParameters?.R else {throw KDBXBodyError.NoRounds}
            derivedKey = aesKDF(seed: compositeKey, outputKeyLength: 32)
                break
            case .Unknown:
                throw KDBXBodyError.UnknownCipher
            default:
                throw KDBXBodyError.UnknownCipher
        }
        guard let masterSeed = self.header.masterSeed else {throw KDBXBodyError.NoMasterSeed}
        guard let derivedKeyNotNull = derivedKey else {throw KDBXBodyError.KeyCreationUnsuccessful}
        self.encryptionKey = Data(SHA256.hash(data: Data(masterSeed) + derivedKeyNotNull))
        self.baseHMACKey = Data(SHA512.hash(data: Data(masterSeed) + Data(derivedKeyNotNull) + Data(repeating: 0x01, count: 1)))
    }
    
    func HMACKeyForBlockIndex(index: UInt64) throws -> Data {
        guard let key: Data = self.baseHMACKey else {throw KDBXBodyError.KeyCreationUnsuccessful}
        return Data(SHA512.hash(data: withUnsafeBytes(of: index.littleEndian) {Data($0)} + key))
    }
    
    func _readNBytes(stream: InputStream, n: Int) -> [UInt8]? {
        let bufferSize = n
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        let bytesRead = stream.read(buffer, maxLength: bufferSize)
        var arr: [UInt8]? = nil
        if bytesRead < 0 {
            print("An error occurred while reading the file: \(stream.streamError?.localizedDescription ?? "Unknown error")")
        } else if bytesRead == 0 {
            print("End of file reached.")
        } else {
            arr = _pointerToArray(buffer: buffer, bufferSize: n)
        }
        buffer.deallocate()
        return arr
    }
    
    func getBlock(stream: InputStream, index: UInt64) throws -> Data {
        guard let blockSignature = _readNBytes(stream: stream, n: 32) else {throw KDBXBodyError.BlockParseError}
        guard let blockLength = _readNBytes(stream: stream, n: 4) else {throw KDBXBodyError.BlockParseError}
        let n: UInt32 = bytesToUnsignedInteger(blockLength)
        guard let blockContent = _readNBytes(stream: stream, n: Int(n)) else {throw KDBXBodyError.BlockParseError}
        
        // Check if HMAC Signature is the same
        let blockKey = try HMACKeyForBlockIndex(index: index)
        let derivedHMACSignature = Data(HMAC<SHA256>.authenticationCode(for: (withUnsafeBytes(of: index.littleEndian) {Data($0)} + Data(blockLength) + Data(blockContent)), using: SymmetricKey(data: blockKey)))
        guard derivedHMACSignature == Data(blockSignature) else {throw KDBXBodyError.DataCompromised}
        return Data(blockContent)
    }
    
    func getBlocks(stream: InputStream) throws {
        var i: UInt64 = 0
        while (stream.hasBytesAvailable) {
            let blockContent = try getBlock(stream: stream, index: i)
            self.innerEncryptedData! += blockContent
            i+=1
        }
    }
    
    func decryptData() throws {
        let cipher = try self.header.getCipher()
        guard let encryptionIV = self.header.encryptionIV else {throw KDBXBodyError.NoEncryptionIV}
        guard let encryptedData = self.innerEncryptedData else {throw KDBXBodyError.NoData}
        guard let key = self.encryptionKey else {throw KDBXBodyError.NoKey}
        switch (cipher) {
        case .AES128CBC:
            // TODO: Check implementation of AES 128 CBC cipher
            self.innerDecryptedData = decryptAESCBC(data: encryptedData, key: key, iv: Data(encryptionIV), type: .s128)
            break
        case .AES256CBC:
            self.innerDecryptedData = decryptAESCBC(data: encryptedData, key: key, iv: Data(encryptionIV), type: .s256)
            break
        case .ChaCha20:
            //TODO: Implement chacha20
            break
        case .TwofishCBC:
            //TODO: Implement twofish
            break
        }
    }
    
    func unzipDate() throws {
        
    }
}
