//
//  File.swift
//  
//
//  Created by John Jakobsen on 4/21/23.
//

import Foundation
import CryptoKit
import Encryption
import Gzip

@available(iOS 13.0, *)
@available(macOS 13.0, *)
class KDBXBody: NSObject {
    
    let header: KDBXHeader
    var innerEncryptedData: Data? // Encrypted Inner Header + XML Data
    var innerDecryptedData: Data? // Decrypted Inner Header + XML Data
    var XMLData: Data? // Decrypted XML Data
    var streamCipher: UInt32?
    var streamKey: Data?
    var binary: Data?
    
    public static func fromEncryptedStream(password: String, header: KDBXHeader, encryptedStream: InputStream) throws -> KDBXBody {
        return try KDBXBody(password: password, header: header, encryptedStream: encryptedStream)
    }
    
    public static func fromXMLStream(header: KDBXHeader, xmlStream: InputStream) throws -> KDBXBody {
        let body = try KDBXBody(header: header)
        let xmlData = try readAllData(from: xmlStream)
        try body.loadXMLData(xmlData: xmlData)
        return body
    }

    private init(password: String, header: KDBXHeader, encryptedStream: InputStream) throws {
        self.header = header
        super.init()
        let deblockifiedData = try deblockifyData(stream: encryptedStream)
        
        guard let key = self.header.encryptionKey else {throw KDBXBodyError.NoKey}
        guard let encryptionIV = self.header.encryptionIV else {throw KDBXBodyError.NoEncryptionIV}
        let cipher = try self.header.getCipher()
        guard let decryptedData = try decryptData(encryptedData: deblockifiedData, key: key, encryptionIV: encryptionIV, cipher: cipher) else {
            throw KDBXBodyError.DecryptionFailed
        }
        
        var innerData = decryptedData
        if (header.compressionFlag ?? true) {
            innerData = try decryptedData.gunzipped()
        }
        let decryptedInnerDataStream = InputStream(data: innerData)
        decryptedInnerDataStream.open()
        defer {
            decryptedInnerDataStream.close()
        }
        try readInnerHeader(stream: decryptedInnerDataStream)
        self.XMLData = try readAllData(from: decryptedInnerDataStream)
    }
    
    func getBlock(stream: InputStream, index: UInt64) throws -> Data? {
        let blockSignature: Data = try stream.readNBytes(n: 32)
        let blockLength: Data = try stream.readNBytes( n: 4)
        let n: UInt32 = blockLength.toUnsignedInteger()
        
        if (n == 0) {
            return nil
        }
        let blockContent = try stream.readNBytes( n: Int(n))
        
        // Check if HMAC Signature is the same
        let blockKey = try HMACKeyForBlockIndex(index: index, baseHMACKey: self.header.baseHMACKey)
        let derivedHMACSignature = Data(HMAC<SHA256>.authenticationCode(for: (index.data + Data(blockLength) + Data(blockContent)), using: SymmetricKey(data: blockKey)))
        guard derivedHMACSignature == Data(blockSignature) else {
            throw KDBXBodyError.DataCompromised
        }
        return blockContent
    }
    
    func deblockifyData(stream: InputStream) throws -> Data {
        if (stream.streamStatus == .notOpen) {
            stream.open()
        }
        defer {
            stream.close()
        }
        var i: UInt64 = 0
        var blocks = Data()
        while (stream.hasBytesAvailable) {
            guard let blockContent = try getBlock(stream: stream, index: i) else {
                return blocks
            }
            
            blocks += blockContent
            i+=1
        }
        return blocks
    }
    
    func readTLV(stream: InputStream) throws -> (type: UInt8, size: UInt32?, data: Data?) {
        let type = try stream.readNBytes(n: 1)
        let lengthData = try stream.readNBytes(n: 4)
        let length: UInt32 = lengthData.toUnsignedInteger()
        if (type[0] == 0) {
            return (type: type[0], size: nil, data: nil)
        }
        let value = try stream.readNBytes(n: Int(length))
        
        return (type: type[0], size: length, data: value)
    }
    
    func readInnerHeader(stream: InputStream) throws {
        var tlv = try readTLV(stream: stream)
        while (tlv.type > 0) {
            guard let d = tlv.data else {
                throw KDBXBodyError.ParseError
            }
            switch (tlv.type) {
            case 1:
                self.streamCipher = d.toUnsignedInteger()
                break
            case 2:
                self.streamKey = d
                break
            case 3:
                self.binary = d
                break
            default:
                throw KDBXBodyError.UnknownInnerHeaderType
            }
            tlv = try readTLV(stream: stream)
        }
    }

    // Save Section

    init(header: KDBXHeader) throws {
        self.header = header
        super.init()
    }
    
    func loadXMLData(xmlData: Data) throws {
        self.XMLData = xmlData
    }
    
    func createTLV(type: UInt8, data: Data) throws -> Data {
        let length = UInt32(data.count.magnitude).littleEndian.data.bytes
        return Data([type] + length + data.bytes)
    }
    
    func createInnerHeader() throws -> Data {
        var workingData = Data()
        guard let streamCipher = self.streamCipher?.data else {
            throw KDBXBodyError.StreamCipherNil
        }
        workingData += try createTLV(type: 1, data: streamCipher)
        
        guard let streamKey = self.streamKey else {
            throw KDBXBodyError.StreamKeyNil
        }
        workingData += try createTLV(type: 2, data: streamKey)
        
        if let binaryData = self.binary {
            workingData += try createTLV(type: 3, data: binaryData)
        }
        
        workingData += try createTLV(type: 0, data: Data())
        
        return workingData
    }

    func _writeNBytes(stream: OutputStream, data: Data) throws {
        guard stream.hasSpaceAvailable else {
            throw KDBXBodyError.NoWriteSpace
        }
        let n = data.count
        try data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
            guard let pointerAddress = pointer.baseAddress else {
                throw KDBXBodyError.UnableToGetPointerAddress
            }
            let writeResult = stream.write(pointerAddress, maxLength: n)
            if (writeResult == -1 || writeResult != n) {
                throw KDBXBodyError.UnableToWrite
            }
        }
    }

    func createBlock(content: Data, index: UInt64, blockSize: UInt32) throws -> Data {
        guard blockSize >= content.count else {
            throw KDBXBodyError.ContentSizeTooLarge
        }
        let blockKey = try HMACKeyForBlockIndex(index: index, baseHMACKey: self.header.baseHMACKey)
        let derivedHMACSignature = Data(HMAC<SHA256>.authenticationCode(for: (index.data + blockSize.data + content), using: SymmetricKey(data: blockKey)))
        return Data(derivedHMACSignature + blockSize.data + content) // Placeholder
    }
    
    func convertToBlocks(content: Data) throws -> Data {
        var blocks: Data = Data()
        var index: UInt64 = 0
        let blockSize: UInt32 = 1296
        let stream: InputStream = InputStream(data: content)
        stream.open()
        defer {
            stream.close()
        }
        while (stream.hasBytesAvailable) {
            let bytes: Data = try stream.readNBytes(n: Int(blockSize))
            blocks += try createBlock(content: bytes, index: index, blockSize: UInt32(bytes.count))
            index += 1
        }
        
        blocks += try createBlock(content: Data(), index: index, blockSize: 0)
        return blocks
    }
    
    func encrypt(writeStream: OutputStream) throws {
        var workingData = try createInnerHeader()
        
        guard let xmlData = self.XMLData else {
            throw KDBXBodyError.InnerDecryptedDataNil
        }
        
        workingData += xmlData
        
        if (self.header.compressionFlag ?? false) {
            workingData = try workingData.gzipped()
        }
        guard let key = self.header.encryptionKey else {throw KDBXBodyError.NoKey}
        guard let encryptionIV = self.header.encryptionIV else {throw KDBXBodyError.NoEncryptionIV}
        let cipher = try self.header.getCipher()
        workingData = try encryptData(decryptedData: workingData, key: key, encryptionIV: encryptionIV, cipher: cipher)
        
        // split it blocks
        workingData = try convertToBlocks(content: workingData)
        
        try _writeNBytes(stream: writeStream, data: workingData)
    }
}
