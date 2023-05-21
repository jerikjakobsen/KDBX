//
//  StreamProtocol.swift
//  
//
//  Created by John Jakobsen on 5/15/23.
//

import Foundation

public protocol StreamCipher {
    func decrypt(encryptedData: Data) throws -> Data
    func encrypt(data: Data) throws -> Data
}
