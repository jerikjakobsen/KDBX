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
import XML

@available(iOS 15.0, *)
@available(macOS 13.0, *)
class KDBXBody: NSObject {
    var streamCipher: UInt32?
    var binary: Data?
    
    public var meta: MetaXML
    public var group: GroupXML
    
    public static func fromEncryptedStream(_ encryptedStream: InputStream, header: KDBXHeader) throws -> KDBXBody {
        return try KDBXBody(header: header, encryptedStream: encryptedStream)
    }

    private init(header: KDBXHeader, encryptedStream: InputStream) throws {
        guard let baseHMACKey = header.baseHMACKey else {
            throw KDBXBodyError.HMACBaseKeyNil
        }
        let deblockifiedData = try KDBXBody.deblockifyData(stream: encryptedStream, baseHMACKey: baseHMACKey)
        
        guard let key = header.encryptionKey else {throw KDBXBodyError.NoKey}
        guard let encryptionIV = header.encryptionIV else {throw KDBXBodyError.NoEncryptionIV}
        let cipher = try header.getCipher()
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
        let innerHeader = try KDBXBody.readInnerHeader(stream: decryptedInnerDataStream)
        self.streamCipher = innerHeader.streamCipher
        self.binary = innerHeader.binary
        let XMLData = try readAllData(from: decryptedInnerDataStream)
        let xmlManager = try XMLManager(XMLData: XMLData, cipherKey: innerHeader.streamKey)
        guard let meta = xmlManager.meta else {
            throw KDBXBodyError.MetaNil
        }
        
        guard let group = xmlManager.group else {
            throw KDBXBodyError.GroupNil
        }
        self.meta = meta
        self.group = group
        
    }
    
    public init(title: String = "", description: String = "") {
        self.streamCipher = DefaultValues.StreamCipherID
        self.meta = MetaXML(databaseName: title, databaseDescription: description)
        self.group = GroupXML(name: "Root")
    }
    
    func loadMeta(_ meta: MetaXML) {
        self.meta = meta
    }
    
    func loadGroup(_ group: GroupXML) {
        self.group = group
    }
    
    static func getBlockContent(stream: InputStream, index: UInt64, baseHMACKey: Data) throws -> Data? {
        let blockSignature: Data = try stream.readNBytes(n: 32)
        let blockLength: Data = try stream.readNBytes( n: 4)
        let n: UInt32 = blockLength.toUnsignedInteger()
        
        if (n == 0) {
            return nil
        }
        let blockContent = try stream.readNBytes( n: Int(n))
        
        // Check if HMAC Signature is the same
        let blockKey = try HMACKeyForBlockIndex(index: index, baseHMACKey: baseHMACKey)
        let derivedHMACSignature = Data(HMAC<SHA256>.authenticationCode(for: (index.data + Data(blockLength) + Data(blockContent)), using: SymmetricKey(data: blockKey)))
        guard derivedHMACSignature == Data(blockSignature) else {
            throw KDBXBodyError.DataCompromised
        }
        return blockContent
    }
    
    static func deblockifyData(stream: InputStream, baseHMACKey: Data) throws -> Data {
        if (stream.streamStatus == .notOpen) {
            stream.open()
        }
        defer {
            stream.close()
        }
        var i: UInt64 = 0
        var blocks = Data()
        while (stream.hasBytesAvailable) {
            guard let blockContent = try getBlockContent(stream: stream, index: i, baseHMACKey: baseHMACKey) else {
                return blocks
            }
            
            blocks += blockContent
            i+=1
        }
        return blocks
    }
    
    static func readTLV(stream: InputStream) throws -> (type: UInt8, size: UInt32?, data: Data?) {
        let type = try stream.readNBytes(n: 1)
        let lengthData = try stream.readNBytes(n: 4)
        let length: UInt32 = lengthData.toUnsignedInteger()
        if (type[0] == 0) {
            return (type: type[0], size: nil, data: nil)
        }
        let value = try stream.readNBytes(n: Int(length))
        
        return (type: type[0], size: length, data: value)
    }
    
    static func readInnerHeader(stream: InputStream) throws -> (streamCipher: UInt32, streamKey: Data, binary: Data?) {
        var tlv = try readTLV(stream: stream)
        var streamCipher: UInt32? = nil
        var streamKey: Data? = nil
        var binary: Data? = nil
        while (tlv.type > 0) {
            guard let d = tlv.data else {
                throw KDBXBodyError.ParseError
            }
            switch (tlv.type) {
            case 1:
                streamCipher = d.toUnsignedInteger()
                break
            case 2:
                streamKey = d
                break
            case 3:
                binary = d
                break
            default:
                throw KDBXBodyError.UnknownInnerHeaderType
            }
            tlv = try readTLV(stream: stream)
        }
        guard let SC = streamCipher else {
            throw KDBXBodyError.StreamCipherNil
        }
        guard let SK = streamKey else {
            throw KDBXBodyError.StreamKeyNil
        }
        return (SC, SK, binary)
    }

    // Save Section
    
    func createTLV(type: UInt8, data: Data) throws -> Data {
        let length = UInt32(data.count.magnitude).littleEndian.data.bytes
        return Data([type] + length + data.bytes)
    }
    
    func createInnerHeader(streamKey: Data) throws -> Data {
        var workingData = Data()
        guard let streamCipher = self.streamCipher?.data else {
            throw KDBXBodyError.StreamCipherNil
        }
        workingData += try createTLV(type: 1, data: streamCipher)
        
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

    func createBlock(content: Data, index: UInt64, blockSize: UInt32, baseHMACKey: Data) throws -> Data {
        guard blockSize >= content.count else {
            throw KDBXBodyError.ContentSizeTooLarge
        }
        let blockKey = try HMACKeyForBlockIndex(index: index, baseHMACKey: baseHMACKey)
        let derivedHMACSignature = Data(HMAC<SHA256>.authenticationCode(for: (index.data + blockSize.data + content), using: SymmetricKey(data: blockKey)))
        return Data(derivedHMACSignature + blockSize.data + content) // Placeholder
    }
    
    func convertToBlocks(content: Data, baseHMACKey: Data) throws -> Data {
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
            blocks += try createBlock(content: bytes, index: index, blockSize: UInt32(bytes.count), baseHMACKey: baseHMACKey)
            index += 1
        }
        
        blocks += try createBlock(content: Data(), index: index, blockSize: 0, baseHMACKey: baseHMACKey)
        return blocks
    }
    
    func encrypt(header: KDBXHeader) throws -> Data {
        let newStreamKey = try generateRandomBytes(size: 64)
        
        let hashedKey = Data(SHA512.hash(data: newStreamKey))
        let key = hashedKey.prefix(32)
        let nonce = hashedKey.subdata(in: 32..<(32 + 12))
        
        var workingData = try createInnerHeader(streamKey: newStreamKey)
        
        let xmlManager = XMLManager(meta: self.meta, group: self.group)
        
        guard let xmlData = try xmlManager.toXML(streamKey: key, nonce: nonce).data(using: .utf8) else {
            throw KDBXBodyError.FailedToConvertXMLStringToData
        }
        workingData += xmlData
        
        if (header.compressionFlag ?? false) {
            workingData = try workingData.gzipped()
        }
        guard let key = header.encryptionKey else {throw KDBXBodyError.NoKey}
        guard let encryptionIV = header.encryptionIV else {throw KDBXBodyError.NoEncryptionIV}
        let cipher = try header.getCipher()
        workingData = try encryptData(decryptedData: workingData, key: key, encryptionIV: encryptionIV, cipher: cipher)
        
        guard let baseHMACKey = header.baseHMACKey else {
            throw KDBXBodyError.HMACBaseKeyNil
        }
        
        workingData = try convertToBlocks(content: workingData, baseHMACKey: baseHMACKey)
        
        return workingData
    }
}
