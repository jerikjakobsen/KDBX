//
//  File.swift
//  
//
//  Created by John Jakobsen on 4/16/23.
//

import Foundation

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
    }
    
    let UUID: [UInt8]
    lazy var keyType: KeyDerivationAlgorithm = {
        let strRep: String = uint8ArrayToHexString(UUID)
        switch (strRep) {
        case "0x9D9F39A628A4460BF740D08C18A4FEA":
            return KeyDerivationAlgorithm.AESKDF
        case "0xEF636DDF8C29444B91F7A9A403E30A0C":
            return KeyDerivationAlgorithm.Argon2d
        case "0x9E298B1956DB4773B23DFC3EC6F0A1E6":
            return KeyDerivationAlgorithm.Argon2id
        default:
            return KeyDerivationAlgorithm.Unknown
        }
    }()
    // AES KDF Params
    var R: UInt64? = nil // Number of rounds
    var S: [UInt8]? = nil // Random Seed, length = 32
    
    //Argon2 Params
    var SArgon: [UInt8]? = nil // Random Salt
    var P: UInt32? = nil // Parallelism
    var M: UInt64? = nil // Memory usage in bytes, usually needs to be divided by 1024
    var I: UInt64? = nil // Iterations
    var V: UInt32? = nil // Argon2 version, either 0x10 or 0x13
    var K: [UInt8]? = nil // Optional Key (NOT USED IN KEEPASS)
    var A: [UInt8]? = nil // Optional Associated Data (NOT USED IN KEEPASS)
    
    init(variantMap: [String: Any]) throws {
        guard let uuidT = variantMap["$uuid"] as? [UInt8] else {throw KDFParametersError.ParseValue}
        self.UUID = uuidT
        if (self.keyType == .AESKDF) {
            guard let rT = variantMap["r"] as? UInt64 else {throw KDFParametersError.ParseValue}
            self.R = rT
            
            guard let sT = variantMap["s"] as? [UInt8] else {throw KDFParametersError.ParseValue}
            if (sT.count != 32) {throw KDFParametersError.IllegalValue}
            self.S = sT
        } else if (self.keyType == .Argon2d || self.keyType == .Argon2id) {
            guard let sT = variantMap["s"] as? [UInt8] else {throw KDFParametersError.ParseValue}
            self.SArgon = sT
            
            guard let pT = variantMap["p"] as? UInt32 else {throw KDFParametersError.ParseValue}
            self.P = pT
            
            guard let mT = variantMap["m"] as? UInt64 else {throw KDFParametersError.ParseValue}
            self.M = mT
            
            guard let iT = variantMap["i"] as? UInt64 else {throw KDFParametersError.ParseValue}
            self.I = iT
            
            guard let vT = variantMap["v"] as? UInt32 else {throw KDFParametersError.ParseValue}
            self.V = vT
            
            if let kT = variantMap["k"] as? [UInt8] {
                self.K = kT
            }
            
            if let aT = variantMap["a"] as? [UInt8] {
                self.A = aT
            }
        }
    }
}
