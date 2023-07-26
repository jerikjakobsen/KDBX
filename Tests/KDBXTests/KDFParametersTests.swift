//
//  KDFParametersTests.swift
//  
//
//  Created by John Jakobsen on 7/12/23.
//

import Foundation
import XCTest
@testable import KDBX

class KDFParametersTests: XCTestCase {
    func testNewInit() throws {
        let kdfParameters = try KDFParameters()
        try kdfParameters.encodeVariantMap()
    }
}
