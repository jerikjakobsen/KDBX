//
//  KDBXHeaderError.swift
//  
//
//  Created by John Jakobsen on 7/26/23.
//

import Foundation

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
    case NoCipherID
    case UnexpectedNil
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
    case HMACBaseKeyNil
    case HeaderBytesNil
    case ComputedHMACNotEqual
    case NoEncryptionIV
}
