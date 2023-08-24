//
//  KDBX.swift
//  
//
//  Created by John Jakobsen on 7/26/23.
//

import Foundation
import XML

@available(iOS 15.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
public class KDBX: NSObject {
    let header: KDBXHeader
    let body: KDBXBody
    public let meta: MetaXML // Change this to one not XML
    public let group: GroupXML // Change this to one not XML
    
    //Default Constructor, For Initializing New Database
    public init(title: String, description: String = "") throws {
        self.header = try KDBXHeader()
        self.body = KDBXBody(title: title, description: description)
        self.meta = body.meta
        self.group = body.group
    }
    
    internal init(header: KDBXHeader, body: KDBXBody) {
        self.header = header
        self.body = body
        self.meta = body.meta
        self.group = body.group
    }
    
    private init(_ stream: InputStream, password: String) async throws {
        self.header = try KDBXHeader.fromStream(stream, password: password)
        self.body = try KDBXBody.fromEncryptedStream(stream, header: header)
        self.meta = body.meta
        self.group = body.group
    }
    
    public static func fromEncryptedStream(_ stream: InputStream, password: String) async throws -> KDBX {
        return try await KDBX(stream, password: password)
    }
    
    public static func fromEncryptedData(_ data: Data, password: String) async throws -> KDBX {
        let readStream = InputStream(data: data)
        readStream.open()
        let kdbx = try await KDBX(readStream, password: password)
        readStream.close()
        return kdbx
    }
    
    public func encryptToStream(_ stream: OutputStream, password: String) async throws {
        self.body.loadMeta(self.meta)
        self.body.loadGroup(self.group)
        
        try stream.write(data: self.header.convertToData(password: password))
        try stream.write(data: self.body.encrypt(header: self.header))
    }
    
    public func encryptToData(password: String) async throws -> Data {
        self.body.loadMeta(self.meta)
        self.body.loadGroup(self.group)
        
        return try (self.header.convertToData(password: password) + self.body.encrypt(header: self.header))
    }
    
}

