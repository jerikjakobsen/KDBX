//
//  File.swift
//  
//
//  Created by John Jakobsen on 4/12/23.
//

import Foundation
import CryptoKit

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
class KDBXHeader {
    var cipherID: [UInt8]? = nil
    var compressionFlag: Bool? = nil
    var masterSeed: [UInt8]? = nil
    var transformSeed: [UInt8]? = nil
    var transfromRounds: Int? = nil
    var streamStartBytes: [UInt8]? = nil
    var innerRandomStreamID: [UInt8]? = nil
    var encryptionIV: [UInt8]? = nil
    var kdfParameters: KDFParameters? = nil
    var publicCustomData: [String: Any]? = nil
    var headerHash: [UInt8]? = nil
    var headerSignature: [UInt8]? = nil
    var headerBytes: [UInt8]? = nil
    var HMACKey: [UInt8]? = nil
    static let signature1: UInt32 = 0x9AA2D903
    static let signature2: UInt32 = 0xB54BFB67
    static let kdbxVMinor: UInt16 = 1
    static let kdbxVMajor: UInt16 = 4
    
    enum Cipher {
        case AES128CBC
        case AES256CBC
        case TwofishCBC
        case ChaCha20
    }
    
    enum HeaderTypeCode: Int {
        case EndOfHeader = 0
        case Comment = 1
        case CipherID = 2
        case CompressionFlags = 3
        case MasterSeed = 4
        case TransformSeed = 5
        case TransformRounds = 6
        case EncryptionIV = 7
        case ProtectedStreamKey = 8
        case StreamStartBytes = 9
        case InnerRandomStreamID = 10
        case KDFParameters = 11
        case PublicCustomData = 12
        case Unknown = 13
    }
    
    enum VariantMapType: UInt8 {
        case EndOfMap = 0x00
        case UInt32 = 0x04
        case UInt64 = 0x05
        case Bool = 0x08
        case Int32 = 0x0c
        case Int64 = 0x0d
        case StringUTF8 = 0x18
        case ByteArray = 0x42
        case Unknown = 0x88
    }
    
    enum KDBXHeaderError: Error {
        case SignatureParse
        case WrongSignature
        case VersionParse
        case WrongMajorVersion
        case ParseLength
        case ParseCode
        case ParseValue
        case IllegalValue
        case VariantMapParse
        case ReadHeaderHash
        case ReadHeaderSignatureHash
        case HashNotEqual
        case ReadHeaderBytes
        case NoCipherID
        case UnknownCipher
    }
    
    init(stream: InputStream, offset: Int? = nil) throws {
        headerBytes = []
        try parseOuterHeader(stream: stream)
        guard let hHash = _readNBytes(stream: stream, n: 32, saveBytes: false) else {throw KDBXHeaderError.ReadHeaderHash}
        guard let hmacHash = _readNBytes(stream: stream, n: 32, saveBytes: false) else {throw KDBXHeaderError.ReadHeaderSignatureHash}
        guard let rawHeaderBytes = self.headerBytes else {throw KDBXHeaderError.ReadHeaderBytes}
        let hash = Array(SHA256.hash(data: Data(rawHeaderBytes)).makeIterator())
        guard hash == hHash else {throw KDBXHeaderError.HashNotEqual}
        
    }
    
    static func _byteToCode(num: UInt8) -> HeaderTypeCode {
        switch (num) {
        case 0:
            return HeaderTypeCode.EndOfHeader
        case 1:
            return HeaderTypeCode.Comment
        case 2:
            return HeaderTypeCode.CipherID
        case 3:
            return HeaderTypeCode.CompressionFlags
        case 4:
            return HeaderTypeCode.MasterSeed
        case 5:
            return HeaderTypeCode.TransformSeed
        case 6:
            return HeaderTypeCode.TransformRounds
        case 7:
            return HeaderTypeCode.EncryptionIV
        case 8:
            return HeaderTypeCode.ProtectedStreamKey
        case 9:
            return HeaderTypeCode.StreamStartBytes
        case 10:
            return HeaderTypeCode.InnerRandomStreamID
        case 11:
            return HeaderTypeCode.KDFParameters
        case 12:
            return HeaderTypeCode.PublicCustomData
        default:
            return HeaderTypeCode.Unknown
        }
    }
    
    static func _byteToVariantMapType(byte: UInt8) -> VariantMapType {
        switch (byte) {
        case VariantMapType.EndOfMap.rawValue:
            return VariantMapType.EndOfMap
        case VariantMapType.UInt32.rawValue:
            return VariantMapType.UInt32
        case VariantMapType.UInt64.rawValue:
            return VariantMapType.UInt64
        case VariantMapType.Bool.rawValue:
            return VariantMapType.Bool
        case VariantMapType.Int32.rawValue:
            return VariantMapType.Int32
        case VariantMapType.Int64.rawValue:
            return VariantMapType.Int64
        case VariantMapType.StringUTF8.rawValue:
            return VariantMapType.StringUTF8
        case VariantMapType.ByteArray.rawValue:
            return VariantMapType.ByteArray
        default:
            return VariantMapType.Unknown
        }
    }
    
    func _readVariantMap(stream: InputStream) throws -> [String: Any] {
        func _readVariantMapEntry(stream: InputStream) throws -> (String, Any?, VariantMapType) {
            // Type - UInt8
            // KeySize - UInt32
            // Key - byte[KeySize]
            // ValueSize - UInt32
            // Value byte[ValueSize] -> Convert to type
            
            guard let tT = _readNBytes(stream: stream, n: 1, saveBytes: false) else {throw KDBXHeaderError.VariantMapParse}
            guard tT.count == 1 else {throw KDBXHeaderError.VariantMapParse}
            let type = KDBXHeader._byteToVariantMapType(byte: tT[0])
            
            if (type == .EndOfMap) {return ("", nil, VariantMapType.EndOfMap)}
            
            guard let ksT = _readNBytes(stream: stream, n: 4, saveBytes: false) else {throw KDBXHeaderError.VariantMapParse}
            guard ksT.count == 4 else {throw KDBXHeaderError.VariantMapParse}
            let keySize: UInt32 = bytesToUnsignedInteger(ksT)

            guard let kT = _readNBytes(stream: stream, n: Int(keySize), saveBytes: false) else {throw KDBXHeaderError.VariantMapParse}
            guard kT.count == Int(keySize) else {throw KDBXHeaderError.VariantMapParse}
            let key: String
            do {
                key = try bytesToUTF8String(kT)
            } catch {
                throw error
            }
            
            guard let vsT = _readNBytes(stream: stream, n: 4, saveBytes: false) else {throw KDBXHeaderError.VariantMapParse}
            guard vsT.count == 4 else {throw KDBXHeaderError.VariantMapParse}
            let valueSize: UInt32 = bytesToUnsignedInteger(vsT)
            
            guard let vT = _readNBytes(stream: stream, n: Int(valueSize), saveBytes: false) else {throw KDBXHeaderError.VariantMapParse}
            guard vT.count == Int(valueSize) else {throw KDBXHeaderError.VariantMapParse}
            
            var value: Any?
            switch (type) {
                case .Bool:
                    value = vT[0] == 1
                    break
                case .ByteArray:
                    value = vT
                    break
                case .Int32:
                    let num: Int32 = bytesToSignedInteger(vT)
                    value = num
                    break
                case .Int64:
                    let num: Int64 = bytesToSignedInteger(vT)
                    value = num
                    break
                case .StringUTF8:
                    do {
                        let str: String = try bytesToUTF8String(vT)
                        value = str
                    } catch {
                        throw error
                    }
                    break
                case .UInt32:
                    let num: UInt32 = bytesToUnsignedInteger(vT)
                    value = num
                    break
                case .UInt64:
                    let num: UInt64 = bytesToUnsignedInteger(vT)
                    value = num
                    break
                default:
                    value = nil
                    break
            }
            return (key, value, type)
        }
        // Check Variant Map Version
        
        guard let versionBytes = _readNBytes(stream: stream, n: 2, saveBytes: false) else {throw KDBXHeaderError.ParseValue}
        let versionNum: UInt16 = bytesToUnsignedInteger(versionBytes)
        // TODO: Check version Number
        var variantMap: [String: Any] = [:]
        while (stream.hasBytesAvailable) {
            do {
                let (key, val, type) = try _readVariantMapEntry(stream: stream)
                if (type == .EndOfMap) {
                    break
                }
                variantMap[key] = val
            } catch {
                throw error
            }
        }
        return variantMap
    }
    
    func _readHeaderLength(stream: InputStream) throws -> UInt32  {
        guard let lengthBytes = _readNBytes(stream: stream, n: 4) else {throw KDBXHeaderError.ParseLength}
        let length: UInt32 = bytesToUnsignedInteger(lengthBytes)
        return length
    }
    func _readHeaderCode(stream: InputStream) throws -> HeaderTypeCode {
        guard let codeByte = _readNBytes(stream: stream, n: 1) else {throw KDBXHeaderError.ParseCode}
        let codeInt: UInt8 = bytesToUnsignedInteger(codeByte)
        return KDBXHeader._byteToCode(num: codeInt)
    }
    
    
    func _readHeaderTLV(stream: InputStream) throws -> Bool {

        if (!stream.hasBytesAvailable) {
            return false
        }
        let code: HeaderTypeCode
        do {
            code = try _readHeaderCode(stream: stream)
        } catch {
            throw error
        }
        
        let length: UInt32
        do {
            length = try _readHeaderLength(stream: stream)
        } catch {
            throw error
        }
        let lengthInt = Int(length)
        guard let valueBytes = _readNBytes(stream: stream, n: lengthInt) else {
            throw KDBXHeaderError.ParseValue
        }
        switch (code) {
        case .CipherID:
            guard valueBytes.count == 16 else {
                throw KDBXHeaderError.IllegalValue
            }
            self.cipherID = valueBytes
            break
        case .CompressionFlags:
            guard valueBytes.count == 4 else {
                throw KDBXHeaderError.IllegalValue
            }
            let compVal: UInt32 = bytesToUnsignedInteger(valueBytes)
            self.compressionFlag = compVal == 1
            break
        case .MasterSeed:
            guard valueBytes.count == 32 else {
                throw KDBXHeaderError.IllegalValue
            }
            self.masterSeed = valueBytes
            break
        case .EncryptionIV:
            guard valueBytes.count == length else {
                throw KDBXHeaderError.IllegalValue
            }
            self.encryptionIV = valueBytes
            break
        case .KDFParameters:
            do {
                let kdfStream = InputStream(data: Data(valueBytes))
                kdfStream.open()
                self.kdfParameters = try KDFParameters(variantMap: _readVariantMap(stream: kdfStream))
                kdfStream.close()
            } catch {
                throw error
            }
            break
        case.PublicCustomData:
            do {
                self.publicCustomData = try _readVariantMap(stream: stream)
            } catch {
                throw error
            }
            break
        case .EndOfHeader:
            return false
        default:
            break
        }
        return true
    }
    
    // Outer Header Parser ------------------------------------------------------------------------------
    func parseOuterHeader(stream: InputStream) throws {
        // Outer Header is as such
        /*
         Signature 1, Signature 2, Version Minor, Version Major
         
         
         */
        guard let sig1Bytes = _readNBytes(stream: stream, n: 4) else {throw KDBXHeaderError.SignatureParse}
        let sig1: UInt32 = bytesToUnsignedInteger(sig1Bytes)
        guard let sig2Bytes = _readNBytes(stream: stream, n: 4) else {throw KDBXHeaderError.SignatureParse}
        let sig2: UInt32 = bytesToUnsignedInteger(sig2Bytes)
        if (sig2 != KDBXHeader.signature2 || sig1 != KDBXHeader.signature1) {
            throw KDBXHeaderError.WrongSignature
        }
        guard let vMinorBytes = _readNBytes(stream: stream, n: 2) else {throw KDBXHeaderError.VersionParse}
        guard let vMajorBytes = _readNBytes(stream: stream, n: 2) else {throw KDBXHeaderError.VersionParse}
        let vMajor: UInt16 = bytesToUnsignedInteger(vMajorBytes)
        if (vMajor != KDBXHeader.kdbxVMajor) {
            throw KDBXHeaderError.WrongMajorVersion
        }
        while (stream.hasBytesAvailable) {
            do {
                let res = try _readHeaderTLV(stream: stream)
                if (!res) {return}
            } catch {
                throw error
            }
        }
    }
    
    
    func _readNBytes(stream: InputStream, n: Int, saveBytes: Bool = true) -> [UInt8]? {
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
            if (saveBytes) {
                headerBytes?.append(contentsOf: arr ?? [])
            }
        }
        buffer.deallocate()
        return arr
    }
    
    func getCipher() throws -> Cipher {
        guard let cipherID: [UInt8] = self.cipherID else {throw KDBXHeaderError.NoCipherID}
        let cipherIDString: String = uint8ArrayToHexString(cipherID)
        
        switch (cipherIDString) {
        case "0x61AB05A1946441C38D743A563DF8DD35":
            return Cipher.AES128CBC
        case "0x31C1F2E6BF714350BE5805216AFC5AFF":
            return Cipher.AES256CBC
        case "0xAD68F29F576F4BB9A36AD47AF965346C":
            return Cipher.TwofishCBC
        case "0xD6038A2B8B6F4CB5A524339A31DBB59A":
            return Cipher.ChaCha20
        default:
            throw KDBXHeaderError.UnknownCipher
        }
        
    }
}

