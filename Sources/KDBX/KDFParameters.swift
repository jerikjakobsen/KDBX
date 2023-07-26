//
//  File.swift
//  
//
//  Created by John Jakobsen on 4/16/23.
//

import Foundation
import Encryption

struct KDFParameters {
    enum KeyDerivationAlgorithm {
        case AESKDF
        case Argon2d
        case Argon2id
        case Unknown
    }
    
    enum KDFParametersError: Error {
        case ParseValue
        case IllegalValue
        case NilOptional
    }
    
    let UUID: Data
    let keyType: KeyDerivationAlgorithm
    // AES KDF Params
    var R: UInt64? = nil // Number of rounds
    var S: Data? = nil // Random Seed, length = 32
    
    //Argon2 Params
    var SArgon: Data? = nil // Random Salt
    var P: UInt32? = nil // Parallelism
    var M: UInt64? = nil // Memory usage in bytes, usually needs to be divided by 1024
    var I: UInt64? = nil // Iterations
    var V: UInt32? = nil // Argon2 version, either 0x10 or 0x13
    var K: Data? = nil // Optional Key (NOT USED IN KEEPASS)
    var A: Data? = nil // Optional Associated Data (NOT USED IN KEEPASS)
    
    init(UUID: Data, keyType: KeyDerivationAlgorithm, R: UInt64?, S: Data?, SArgon: Data?, P: UInt32?, M: UInt64?, I: UInt64?, V: UInt32?, K: Data?, A: Data?) {
        self.UUID = UUID
        self.keyType = keyType
        self.R = R
        self.S = S
        self.SArgon = SArgon
        self.P = P
        self.M = M
        self.I = I
        self.V = V
        self.K = K
        self.A = A
    }
    
    init(keyType: KeyDerivationAlgorithm? = nil) throws {
        self.keyType = keyType ?? KeyDerivationAlgorithm.Argon2d
        switch (self.keyType) {
        case .AESKDF:
            self.UUID = hexStringToData("0x9D9F39A628A4460BF740D08C18A4FEA")
            break
        case .Argon2d:
            self.UUID = hexStringToData("0xEF636DDF8C29444B91F7A9A403E30A0C")
            break
        case .Argon2id:
            self.UUID = hexStringToData("0x9E298B1956DB4773B23DFC3EC6F0A1E6")
            break
        case .Unknown:
            fallthrough
        default:
            throw KDFParametersError.IllegalValue
        }
        
        switch (self.keyType) {
        case .AESKDF:
            self.R = 19
            self.S = try generateRandomBytes(size: 32)
        case .Argon2d:
            fallthrough
        case .Argon2id:
            self.SArgon = try generateRandomBytes(size: 32)
            self.P = 2
            self.M = 67108864
            self.V = 19
            self.I = 19
            self.K = nil
            self.A = nil
        case .Unknown:
            fallthrough
        default:
            throw KDFParametersError.IllegalValue
        }
    }
    
    init(variantMap: [String: Any]) throws {
        guard let uuidT = variantMap["$uuid"] as? Data else {throw KDFParametersError.ParseValue}
        let strRep: String = uuidT.toHexString()
        switch (strRep) {
        case "0x9D9F39A628A4460BF740D08C18A4FEA":
            self.keyType = KeyDerivationAlgorithm.AESKDF
        case "0xEF636DDF8C29444B91F7A9A403E30A0C":
            self.keyType = KeyDerivationAlgorithm.Argon2d
        case "0x9E298B1956DB4773B23DFC3EC6F0A1E6":
            self.keyType = KeyDerivationAlgorithm.Argon2id
        default:
            self.keyType = KeyDerivationAlgorithm.Unknown
        }
        self.UUID = uuidT
        if (self.keyType == .AESKDF) {
            guard let rT = variantMap["r"] as? UInt64 else {throw KDFParametersError.ParseValue}
            self.R = rT
            
            guard let sT = variantMap["s"] as? Data else {throw KDFParametersError.ParseValue}
            if (sT.count != 32) {throw KDFParametersError.IllegalValue}
            self.S = sT
        } else if (self.keyType == .Argon2d || self.keyType == .Argon2id) {
            guard let sT = variantMap["s"] as? Data else {throw KDFParametersError.ParseValue} //
            self.SArgon = sT
            
            guard let pT = variantMap["p"] as? UInt32 else {throw KDFParametersError.ParseValue} //
            self.P = pT
            
            guard let mT = variantMap["m"] as? UInt64 else {throw KDFParametersError.ParseValue} //
            self.M = mT
            
            guard let iT = variantMap["i"] as? UInt64 else {throw KDFParametersError.ParseValue} //
            self.I = iT
            
            guard let vT = variantMap["v"] as? UInt32 else {throw KDFParametersError.ParseValue}
            self.V = vT
            
            if let kT = variantMap["k"] as? Data {
                self.K = kT
            }
            
            if let aT = variantMap["a"] as? Data {
                self.A = aT
            }
        }
    }
    
    public func updateSeeds() throws -> KDFParameters {
        let SSeed = try generateRandomBytes(size: 32)
        
        return KDFParameters(UUID: UUID, keyType: keyType, R: R, S: SSeed, SArgon: SSeed, P: P, M: M, I: I, V: V, K: K, A: A)
    }
    
    public func encodeVariantMap() throws -> Data {
        // Type - UInt8, 1 byte
        // KeySize - UInt32, 4 bytes
        // Key - byte[KeySize], keySize bytes
        // ValueSize - UInt32, 4 bytes
        // Value byte[ValueSize] -> Convert to type, valueSize bytes
        // total Variant Map entry bytes = 1 + 4 + 4 + keySize + valueSize = 9 + keySize + valueSize
//      Value Type Codes
//        0x04    UInt32
//        0x05    UInt64
//        0x08    bool (1 byte)
//        0x0C    Int32
//        0x0D    Int64
//        0x18    String (UTF-8 without BOM)
//        0x42    byte[]
        var encodedData = Data()
        encodedData += UInt16(0x100).data // VariantMap Version, 2 bytes
        encodedData += try createVariantMapEntry(key: Data(stringToUInt8Array("$UUID")), keySize: 5, valueType: 0x42, value: Data(self.UUID), valueSize: 16) // 30 bytes
        switch (self.keyType) {
        case .AESKDF:
            guard let rData = self.R?.data,
                  let sdata = self.S
            else {
                throw KDFParametersError.NilOptional
            }
            encodedData += try createVariantMapEntry(key: Data(stringToUInt8Array("r")), keySize: 1, valueType: 0x05, value: rData, valueSize: 8)
            encodedData += try createVariantMapEntry(key: Data(stringToUInt8Array("s")), keySize: 1, valueType: 0x42, value: Data(sdata), valueSize: 32)
            break
        case .Argon2d:
            fallthrough
        case .Argon2id:
            guard let pData = self.P?.data,
                  let mData = self.M?.data,
                  let iData = self.I?.data,
                  let vData = self.V?.data,
                  let sargon = self.SArgon
            else {
                throw KDFParametersError.NilOptional
            }
            
            encodedData += try createVariantMapEntry(key: Data(stringToUInt8Array("s")), keySize: 1, valueType: 0x42, value: Data(sargon), valueSize: 32) // Ignore this when testing, 42 bytes
            encodedData += try createVariantMapEntry(key: Data(stringToUInt8Array("p")), keySize: 1, valueType: 0x04, value: pData, valueSize: 4) // 14 bytes
            encodedData += try createVariantMapEntry(key: Data(stringToUInt8Array("m")), keySize: 1, valueType: 0x05, value: mData, valueSize: 8) // 18 bytes
            encodedData += try createVariantMapEntry(key: Data(stringToUInt8Array("i")), keySize: 1, valueType: 0x05, value: iData, valueSize: 8) // 18 bytes
            encodedData += try createVariantMapEntry(key: Data(stringToUInt8Array("v")), keySize: 1, valueType: 0x04, value: vData, valueSize: 4) // 14 bytes
            
            if let kData = self.K {
                encodedData += try createVariantMapEntry(key: Data(stringToUInt8Array("k")), keySize: 1, valueType: 0x42, value: Data(kData), valueSize: UInt32(kData.count))
            }
            if let aData = self.A {
                encodedData += try createVariantMapEntry(key: Data(stringToUInt8Array("a")), keySize: 1, valueType: 0x42, value: Data(aData), valueSize: UInt32(aData.count))
            }
            break
        case .Unknown:
            throw KDFParametersError.IllegalValue
        }
        encodedData += UInt8(0).data // 1 byte
        
        return encodedData
    }
    
    private func createVariantMapEntry(key: Data, keySize: UInt32, valueType: UInt8, value: Data, valueSize: UInt32)  throws -> Data {
        guard UInt32(key.count) == keySize else {
            throw KDFParametersError.IllegalValue
        }
        guard UInt32(value.count) == valueSize else {
            throw KDFParametersError.IllegalValue
        }
        
        return valueType.data + keySize.data + key + valueSize.data + value
    }
}
