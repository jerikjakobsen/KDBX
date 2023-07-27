//
//  KDBXHeader.swift
//  
//
//  Created by John Jakobsen on 4/12/23.
//

import Foundation
import CryptoKit
import Encryption

enum Cipher {
    case AES128CBC
    case AES256CBC
    case TwofishCBC
    case ChaCha20
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
class KDBXHeader {
    var cipherID: Data? = nil
    var compressionFlag: Bool? = nil
    private var masterSeed: Data? = nil
    private(set) var encryptionIV: Data? = nil
    private var kdfParameters: KDFParameters? = nil
    private(set) var encryptionKey: Data? = nil
    var baseHMACKey: Data? = nil
    private var headerBytes: Data? = nil
    
    static let signature1: UInt32 = 0x9AA2D903
    static let signature2: UInt32 = 0xB54BFB67
    static let kdbxVMinor: UInt16 = 1
    static let kdbxVMajor: UInt16 = 4
    
    enum HeaderTypeCode: UInt8 {
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
        case Data = 0x42
        case Unknown = 0x88
    }
    
    // From File
    private init(stream: InputStream, password: String) throws {
        try parseOuterHeader(stream: stream)
        guard let headerBytes = self.headerBytes else {
            throw KDBXHeaderError.HeaderBytesNil
        }
        guard let readHeaderHash = try _readNBytes(stream: stream, n: 32, saveBytes: false) else {
            throw KDBXHeaderError.ReadHeaderHash
        }
        guard let readhmacHash = try _readNBytes(stream: stream, n: 32, saveBytes: false) else {
            throw KDBXHeaderError.ReadHeaderSignatureHash
        }
        let readHMACHashData = Data(readhmacHash)

        let computedHash = Data(SHA256.hash(data: Data(headerBytes)))
        guard computedHash == Data(readHeaderHash) else {
            throw KDBXHeaderError.HashNotEqual
        }
        try computeKeys(password: password)

        guard try computeHMACSignature() == readHMACHashData else {
            throw KDBXHeaderError.ComputedHMACNotEqual
        }
        
        // These should be set before accessing again (ie for encrypting body to file)
        self.headerBytes = nil
        self.masterSeed = nil
    }
    
    public static func fromStream(_ stream: InputStream, password: String) throws -> KDBXHeader {
        return try KDBXHeader(stream: stream, password: password)
    }
    
    public init() throws {
        self.cipherID = hexStringToData(DefaultValues.CipherID)

        self.compressionFlag = DefaultValues.CompressionFlag

        self.kdfParameters = try KDFParameters()
    }
    
    public func refresh(password: String) throws {
        try self.kdfParameters?.refresh()
        self.masterSeed = try generateRandomBytes(size: 32)
        self.encryptionIV = try generateRandomBytes(size: 16)
        try self.computeKeys(password: password)
    }
    
    func computeKeys(password: String) throws {
        //TODO: Check for keyfile, this implementation only uses the password
        let hashOnce = Data(SHA256.hash(data: Data(stringToUInt8Array(password))))
        let compositeKey = Data(SHA256.hash(data: hashOnce))
        var derivedKey: Data? = nil
        switch (self.kdfParameters?.keyType) {
            case .Argon2d:
            fallthrough
            case .Argon2id:
            guard let argSalt = self.kdfParameters?.SArgon else {throw KDBXHeaderError.NoArgonSalt}
            guard let iterations = self.kdfParameters?.I else {throw KDBXHeaderError.NoArgonIterations}
            guard let memory = self.kdfParameters?.M else {throw KDBXHeaderError.NoArgonMemory}
            guard let parallelism = self.kdfParameters?.P else {throw KDBXHeaderError.NoArgonParallelism}
            guard let version = self.kdfParameters?.V else {throw KDBXHeaderError.NoArgonVersion}
            derivedKey = try ArgonHash(password: compositeKey, salt: Data(argSalt), iterations: Int(iterations), memory: Int(memory)/1024, parallelism: Int(parallelism), keyType: self.kdfParameters?.keyType == .Argon2d ? "Argon2d" : "Argon2id", version: Int(version))
                break
            case .AESKDF:
            // TODO: Check this over, currently not supported
            guard let AESSalt = self.kdfParameters?.S else {throw KDBXHeaderError.NoAESSalt}
            guard let rounds = self.kdfParameters?.R else {throw KDBXHeaderError.NoRounds}
            derivedKey = aesKDF(seed: compositeKey, outputKeyLength: 32)
                break
            case .Unknown:
                throw KDBXHeaderError.UnknownCipher
            default:
                throw KDBXHeaderError.UnknownCipher
        }
        guard let masterSeed = self.masterSeed else {throw KDBXHeaderError.NoMasterSeed}
        guard let derivedKeyNotNull = derivedKey else {throw KDBXHeaderError.KeyCreationUnsuccessful}
        self.encryptionKey = Data(SHA256.hash(data: Data(masterSeed) + derivedKeyNotNull))
        self.baseHMACKey = Data(SHA512.hash(data: Data(masterSeed) + Data(derivedKeyNotNull) + Data(repeating: 0x01, count: 1)))
    }
    
    func computeHMACSignature(headerBytes: Data? = nil, baseHMACKey: Data? = nil) throws -> Data {
        guard let baseHMACKey = baseHMACKey ?? self.baseHMACKey else {
            throw KDBXHeaderError.HMACBaseKeyNil
        }
        
        let computedHMacKey = Data(SHA512.hash(data: Data(repeating: 0xFF, count: 8) + baseHMACKey))
        
        guard let headerBytes = headerBytes ?? self.headerBytes else {
            throw KDBXHeaderError.HeaderBytesNil
        }
        return Data(HMAC<SHA256>.authenticationCode(for: Data(headerBytes), using: SymmetricKey(data: computedHMacKey)))
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
        case VariantMapType.Data.rawValue:
            return VariantMapType.Data
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
            
            guard let tT = try _readNBytes(stream: stream, n: 1, saveBytes: false) else {throw KDBXHeaderError.VariantMapParse}
            guard tT.count == 1 else {throw KDBXHeaderError.VariantMapParse}
            let type = KDBXHeader._byteToVariantMapType(byte: tT[0])
            
            if (type == .EndOfMap) {return ("", nil, VariantMapType.EndOfMap)}
            
            guard let ksT = try _readNBytes(stream: stream, n: 4, saveBytes: false) else {throw KDBXHeaderError.VariantMapParse}
            guard ksT.count == 4 else {throw KDBXHeaderError.VariantMapParse}
            let keySize: UInt32 = ksT.toUnsignedInteger()

            guard let kT = try _readNBytes(stream: stream, n: Int(keySize), saveBytes: false) else {throw KDBXHeaderError.VariantMapParse}
            guard kT.count == Int(keySize) else {throw KDBXHeaderError.VariantMapParse}
            let key: String
            do {
                key = try kT.toUTF8String()
            } catch {
                throw error
            }
            
            guard let vsT = try _readNBytes(stream: stream, n: 4, saveBytes: false) else {throw KDBXHeaderError.VariantMapParse}
            guard vsT.count == 4 else {throw KDBXHeaderError.VariantMapParse}
            let valueSize: UInt32 = vsT.toUnsignedInteger()
            
            guard let vT = try _readNBytes(stream: stream, n: Int(valueSize), saveBytes: false) else {throw KDBXHeaderError.VariantMapParse}
            guard vT.count == Int(valueSize) else {throw KDBXHeaderError.VariantMapParse}
            
            var value: Any?
            switch (type) {
                case .Bool:
                    value = vT[0] == 1
                    break
                case .Data:
                    value = vT
                    break
                case .Int32:
                let num: Int32 = vT.toSignedInteger()
                    value = num
                    break
                case .Int64:
                let num: Int64 = vT.toSignedInteger()
                    value = num
                    break
                case .StringUTF8:
                    do {
                        let str: String = try vT.toUTF8String()
                        value = str
                    } catch {
                        throw error
                    }
                    break
                case .UInt32:
                let num: UInt32 = vT.toUnsignedInteger()
                    value = num
                    break
                case .UInt64:
                let num: UInt64 = vT.toUnsignedInteger()
                    value = num
                    break
                default:
                    value = nil
                    break
            }
            return (key, value, type)
        }
        // Check Variant Map Version
        
        guard let versionBytes = try _readNBytes(stream: stream, n: 2, saveBytes: false) else {throw KDBXHeaderError.ParseValue}
        let versionNum: UInt16 = versionBytes.toUnsignedInteger()
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
        guard let lengthBytes = try _readNBytes(stream: stream, n: 4) else {throw KDBXHeaderError.ParseLength}
        let length: UInt32 = lengthBytes.toUnsignedInteger()
        return length
    }
    func _readHeaderCode(stream: InputStream) throws -> HeaderTypeCode {
        guard let codeByte = try _readNBytes(stream: stream, n: 1) else {throw KDBXHeaderError.ParseCode}
        let codeInt: UInt8 = codeByte.toUnsignedInteger()
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
        guard let valueBytes = try _readNBytes(stream: stream, n: lengthInt) else {
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
            let compVal: UInt32 = valueBytes.toUnsignedInteger()
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
            try _readVariantMap(stream: stream)
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
        guard let sig1Bytes = try _readNBytes(stream: stream, n: 4) else {throw KDBXHeaderError.SignatureParse}
        let sig1: UInt32 = sig1Bytes.toUnsignedInteger()
        guard let sig2Bytes = try _readNBytes(stream: stream, n: 4) else {throw KDBXHeaderError.SignatureParse}
        let sig2: UInt32 = sig2Bytes.toUnsignedInteger()
        if (sig2 != KDBXHeader.signature2 || sig1 != KDBXHeader.signature1) {
            throw KDBXHeaderError.WrongSignature
        }
        guard let vMinorBytes = try _readNBytes(stream: stream, n: 2) else {throw KDBXHeaderError.VersionParse}
        guard let vMajorBytes = try _readNBytes(stream: stream, n: 2) else {throw KDBXHeaderError.VersionParse}
        let vMajor: UInt16 = vMajorBytes.toUnsignedInteger()
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
    
    func getCipher() throws -> Cipher {
        guard let cipherID: Data = self.cipherID else {throw KDBXHeaderError.NoCipherID}
        let cipherIDString: String = cipherID.toHexString()
        
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
    
    // MARK: Write Portion of the header file
    
    func convertToData(password: String) throws -> Data {
        try self.refresh(password: password)
        var headerBytes = Data()
        headerBytes += KDBXHeader.signature1.data // 4
        headerBytes += KDBXHeader.signature2.data // 4
        headerBytes += KDBXHeader.kdbxVMinor.data // 2
        headerBytes += KDBXHeader.kdbxVMajor.data // 2
        
        let cipherID: Data = self.cipherID ?? hexStringToData(DefaultValues.CipherID)
        headerBytes += try createTLV(type: HeaderTypeCode.CipherID.rawValue, data: cipherID) // 5 + 16 = 21
        
        let compressionValue = Data([boolToUInt8(value: self.compressionFlag) ?? UInt8(1)]).rightPadded(to: 4)
        headerBytes += try createTLV(type: HeaderTypeCode.CompressionFlags.rawValue, data: compressionValue) // 5 + 4 = 9
        
        guard let masterSeed = self.masterSeed else {
            throw KDBXHeaderError.NoMasterSeed
        }
        headerBytes += try createTLV(type: HeaderTypeCode.MasterSeed.rawValue, data: masterSeed)
        
        guard let encryptionIV = self.encryptionIV else {
            throw KDBXHeaderError.NoEncryptionIV
        }
        headerBytes += try createTLV(type: HeaderTypeCode.EncryptionIV.rawValue, data: encryptionIV)
        
        guard let kdfparamsEncoding = try self.kdfParameters?.encodeVariantMap() else {
            throw KDBXHeaderError.UnexpectedNil
        }
        headerBytes += try createTLV(type: HeaderTypeCode.KDFParameters.rawValue, data: kdfparamsEncoding)
        
        let endHeader: Data = Data([0x0d, 0x0a, 0x0d, 0x0a])
        headerBytes += try createTLV(type: 0, data: endHeader)
        
        var hashes = Data()
        
        try self.computeKeys(password: password)
        let computedHash = Data(SHA256.hash(data: Data(headerBytes)))
        hashes += computedHash
        
        let computedHMacSignature = try computeHMACSignature(headerBytes: headerBytes)
        hashes += computedHMacSignature
        
        self.masterSeed = nil
        self.headerBytes = nil
        
        return headerBytes + hashes
    }
    
    func createTLV(type: UInt8, data: Data) throws -> Data {
        let length = UInt32(data.count.magnitude).littleEndian.data.bytes
        return Data([type] + length + data.bytes)
    }
    
    func _writeNBytes(stream: OutputStream, data: Data, saveBytes: Bool = true) throws {
        try stream.write(data: data)
        if (saveBytes) {
            if (headerBytes == nil) {
                headerBytes = Data()
            }
            headerBytes?.append(contentsOf: [UInt8](data))
        }
    }
    func _readNBytes(stream: InputStream, n: Int, saveBytes: Bool = true) throws -> Data? {
        let data = try stream.readNBytes(n: n)
        if (saveBytes) {
            if (self.headerBytes == nil) {
                self.headerBytes = Data()
            }
            self.headerBytes?.append(data)
        }
        return data
    }
}

