//
//  DefaultValues.swift
//  
//
//  Created by John Jakobsen on 7/10/23.
//

import Foundation

struct DefaultValues {
    static let CipherID: String = "0x31C1F2E6BF714350BE5805216AFC5AFF" // AES256-CBC
    static let CompressionFlag: Bool = true
    
    static let KDFParametersP: UInt32 = 2
    static let KDFParametersM: UInt64 = 67108864
    static let KDFParametersV: UInt32 = 19
    static let KDFParametersI: UInt64 = 19
    
    static let StreamCipherID: UInt32 = 3
}
