//
//  File.swift
//  
//
//  Created by John Jakobsen on 4/21/23.
//

import Foundation
import CryptoKit
import Argon2Swift
import Gzip

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
class KDBXBody {
    
    let header: KDBXHeader
    var encryptionKey: Data?
    var baseHMACKey: Data?
    var innerEncryptedData: Data?
    var innerDecryptedData: Data?
    var streamCipher: UInt32?
    var streamKey: Data?
    var binary: Data?
    var cleanInnerData: Data?
    
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
        case ParseError
        case InnerDecryptedDataNil
        case CouldNotCreateStream
    }
    init(password: String, header: KDBXHeader, stream: InputStream) throws {
        self.header = header
        try computeKeys(password: password)
        try getBlocks(stream: stream)
        try decryptData()
        if (header.compressionFlag ?? false) {
            try unzipData()
        }
        guard self.innerDecryptedData != nil else {
            throw KDBXBodyError.InnerDecryptedDataNil
        }
        let decryptedInnerDataStream = InputStream(data: self.innerDecryptedData!)
        decryptedInnerDataStream.open()
        try readInnerHeader(stream: decryptedInnerDataStream)
        saveCleanInnerData(stream: decryptedInnerDataStream)
        stream.close()
    }
    
    func computeKeys(password: String) throws {
        print("Computing keys")
        //TODO: Check for keyfile, this implementation only uses the password
        let hashOnce = Data(SHA256.hash(data: Data(stringToUInt8Array(password))))
        let compositeKey = Data(SHA256.hash(data: hashOnce))
        print("1")
        var derivedKey: Data? = nil
        switch (self.header.kdfParameters?.keyType) {
            case .Argon2d:
            fallthrough
            case .Argon2id:
            print("2")
            guard let argSalt = self.header.kdfParameters?.SArgon else {throw KDBXBodyError.NoArgonSalt}
            guard let iterations = self.header.kdfParameters?.I else {throw KDBXBodyError.NoArgonIterations}
            guard let memory = self.header.kdfParameters?.M else {throw KDBXBodyError.NoArgonMemory}
            guard let parallelism = self.header.kdfParameters?.P else {throw KDBXBodyError.NoArgonParallelism}
            guard let version = self.header.kdfParameters?.V else {throw KDBXBodyError.NoArgonVersion}
            let salt = Salt(bytes: Data(argSalt))
            print("Salt: \(argSalt)\niterations: \(iterations)\nmemory: \(Int(memory)/1024)\nparallelism: \(parallelism)\nversion: \(version)\n compositeKey: \(compositeKey)")
            derivedKey = try Argon2Swift.hashPasswordBytes(password: compositeKey, salt: salt, iterations: Int(iterations), memory: Int(memory)/1024, parallelism: Int(parallelism), type: self.header.kdfParameters?.keyType == .Argon2d ? .d : .id, version: version == 0x10 ? .V10 : .V13 ).hashData()
            
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
        print("3")
        guard let masterSeed = self.header.masterSeed else {throw KDBXBodyError.NoMasterSeed}
        guard let derivedKeyNotNull = derivedKey else {throw KDBXBodyError.KeyCreationUnsuccessful}
        self.encryptionKey = Data(SHA256.hash(data: Data(masterSeed) + derivedKeyNotNull))
        self.baseHMACKey = Data(SHA512.hash(data: Data(masterSeed) + Data(derivedKeyNotNull) + Data(repeating: 0x01, count: 1)))
        print("Finished Computing Keys")
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
    
    func getBlock(stream: InputStream, index: UInt64) throws -> Data? {
        guard let blockSignature = _readNBytes(stream: stream, n: 32) else {throw KDBXBodyError.BlockParseError}
        print("Got sig")
        guard let blockLength = _readNBytes(stream: stream, n: 4) else {throw KDBXBodyError.BlockParseError}
        let n: UInt32 = bytesToUnsignedInteger(blockLength)
        if (n == 0) {
            return nil
        }
        print("got length: \(n)")
        guard let blockContent = _readNBytes(stream: stream, n: Int(n)) else {throw KDBXBodyError.BlockParseError}
        print("got content: \(blockContent)")
        
        // Check if HMAC Signature is the same
        let blockKey = try HMACKeyForBlockIndex(index: index)
        let derivedHMACSignature = Data(HMAC<SHA256>.authenticationCode(for: (withUnsafeBytes(of: index.littleEndian) {Data($0)} + Data(blockLength) + Data(blockContent)), using: SymmetricKey(data: blockKey)))
        guard derivedHMACSignature == Data(blockSignature) else {throw KDBXBodyError.DataCompromised}
        return Data(blockContent)
    }
    
    func getBlocks(stream: InputStream) throws {
        var i: UInt64 = 0
        if self.innerEncryptedData == nil {
            self.innerEncryptedData = Data()
        }
        while (stream.hasBytesAvailable) {
            let blockContent = try getBlock(stream: stream, index: i)
            if (blockContent == nil) {
                return
            }
            self.innerEncryptedData! += blockContent!
            i+=1
        }
    }
    
    func decryptData() throws {
        print("Decrypting data")
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
    
    func unzipData() throws {
        print("Unzipping inner data")
        let unzippedData: Data? = try self.innerDecryptedData?.gunzipped()
        self.innerDecryptedData = unzippedData
    }
    
    func readTLV(stream: InputStream) throws -> (type: UInt8, size: UInt32?, data: Data?) {
        guard let type: [UInt8] = _readNBytes(stream: stream, n: 1) else {
            print("1")
            throw KDBXBodyError.ParseError
        }
        if (type[0] == 0) {
            return (type: type[0], size: nil, data: nil)
        }
        guard let lengthBytes: [UInt8] = _readNBytes(stream: stream, n: 4) else {
            print("2")
            throw KDBXBodyError.ParseError
        }
        let length: UInt32 = bytesToUnsignedInteger(lengthBytes)
        
        guard let valueBytes: [UInt8] = _readNBytes(stream: stream, n: Int(length)) else {
            throw KDBXBodyError.ParseError
        }
        let value: Data = Data(valueBytes)
        
        return (type: type[0], size: length, data: value)
    }
    
    func readInnerHeader(stream: InputStream) throws {
        print("Reading Inner Header")
        var tlv = try readTLV(stream: stream)
        while (tlv.type > 0) {
            guard let d = tlv.data else {
                throw KDBXBodyError.ParseError
            }
            switch (tlv.type) {
            case 1:
                self.streamCipher = bytesToUnsignedInteger([UInt8](d))
            case 2:
                self.streamKey = d
            case 3:
                self.binary = d
            default:
                throw KDBXBodyError.ParseError
            }
            tlv = try readTLV(stream: stream)
        }
    }
    
    func saveCleanInnerData(stream: InputStream) {
        self.cleanInnerData = readAllData(from: stream)
    }
    
    func readAllData(from stream: InputStream) -> Data? {
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var data = Data()
        stream.open()
        defer {
            stream.close()
        }
        while stream.hasBytesAvailable {
            let bytesRead = stream.read(&buffer, maxLength: bufferSize)
            if bytesRead < 0 {
                return nil
            }
            data.append(buffer, count: bytesRead)
        }
        return data
    }

}
