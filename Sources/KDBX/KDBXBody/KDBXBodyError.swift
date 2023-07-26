//
//  KDBXBodyError.swift
//  
//
//  Created by John Jakobsen on 7/24/23.
//

import Foundation

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
    case UnableToReadStream
    case HMACBaseKeyNil
    case HeaderBytesNil
    case HeaderHMACHashNil
    case ComputedHMACNotEqual
    case NoWriteSpace
    case UnableToGetPointerAddress
    case UnableToWrite
    case EncryptionFailed
    case DecryptionFailed
    case ContentSizeTooLarge
    case StreamCipherNil
    case StreamKeyNil
    case UnknownInnerHeaderType
}
