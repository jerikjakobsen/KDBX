//
//  KDBXBodyError.swift
//  
//
//  Created by John Jakobsen on 7/24/23.
//

import Foundation

enum KDBXBodyError: Error {
    case DataCompromised
    case NoEncryptionIV
    case NoKey
    case ParseError
    case HMACBaseKeyNil
    case NoWriteSpace
    case UnableToGetPointerAddress
    case UnableToWrite
    case EncryptionFailed
    case DecryptionFailed
    case ContentSizeTooLarge
    case StreamCipherNil
    case StreamKeyNil
    case UnknownInnerHeaderType
    case MetaNil
    case GroupNil
    case FailedToConvertXMLStringToData
    case KeyCreationUnsuccessful
}
