//
//  KDBX.swift
//  
//
//  Created by John Jakobsen on 7/26/23.
//

import Foundation
import XML

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
class KDBX: NSObject {
    let header: KDBXHeader
    let body: KDBXBody
    let meta: MetaXML // Change this to one not XML
    let group: GroupXML // Change this to one not XML
    
    //Default Constructor, For Initializing New Database
    public init(title: String, description: String = "") throws {
        self.header = try KDBXHeader()
        self.body = KDBXBody(title: title, description: description)
        self.meta = body.meta
        self.group = body.group
    }
    
    private init(_ stream: InputStream, password: String) throws {
        self.header = try KDBXHeader.fromStream(stream, password: password)
        self.body = try KDBXBody.fromEncryptedStream(stream, header: header)
        self.meta = body.meta
        self.group = body.group
    }
    
    public static func fromEncryptedStream(_ stream: InputStream, password: String) throws -> KDBX {
        return try KDBX(stream, password: password)
    }
    
    public func encryptToStream(_ stream: OutputStream, password: String) throws {
        self.body.loadMeta(self.meta)
        self.body.loadGroup(self.group)
        
        try stream.write(data: self.header.convertToData(password: password))
        try stream.write(data: self.body.encrypt(header: self.header))
    }
}
