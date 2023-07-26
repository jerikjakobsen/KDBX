import Foundation
import XML
import StreamCiphers
import Encryption
import CryptoKit

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
class KDBXManager {
    
    enum KDBXManagerError: Error {
        case BodyNil
        case StreamKeyNil
        case UnableToOpenStream
        case UnableToConvertStringToData
    }
    
    var header: KDBXHeader? = nil
    var body: KDBXBody? = nil
    let xmlManager: XMLManager
    internal var XMLData: Data? = nil
    init(password: String, fileURL: URL) throws {
        guard let stream = InputStream(url: fileURL) else {
            throw KDBXManagerError.UnableToOpenStream
        }
        stream.open()
        self.header = try KDBXHeader(stream: stream, password: password)
        self.body = try KDBXBody.fromEncryptedStream(password: password, header: self.header!, encryptedStream: stream)
        stream.close()
        guard let xmlData = self.body?.XMLData else {
            throw KDBXManagerError.BodyNil
        }
        self.XMLData = xmlData
        guard let streamKey = self.body?.streamKey else {
            throw KDBXManagerError.StreamKeyNil
        }
        self.xmlManager = try XMLManager(XMLData: xmlData, cipherKey: streamKey)
    }
    
    init(generator: String? = nil) {
        self.xmlManager = XMLManager(generator: generator)
    }
    
    //before dGVzdGluZzI=
    //after  dGVzdGluZzI=
    
    public func addEntry(entry: Entry) {
        self.xmlManager.group?.addEntry(entry: entry)
    }
    public func removeEntry(UUID: String) {
        self.xmlManager.group?.removeEntry(UUID: UUID)
    }
    public func getEntries() -> [Entry]? {
        return self.xmlManager.group?.getEntries()
    }
    
    public func getGroupName() -> String? {
        return self.xmlManager.group?.getName()
    }
    
    public func setGroupName(name: String) {
        self.xmlManager.group?.setName(name: name)
    }

    public func setDBName(name: String) {
        self.xmlManager.meta?.setDBName(name: name)
    }
    
    public func getDBName() -> String? {
        return self.xmlManager.meta?.getDBName()
    }
    
    public func setDBDescription(description: String) {
        self.xmlManager.meta?.setDBDescription(description: description)
    }
    
    public func getDBDescription() -> String? {
        return self.xmlManager.meta?.getDBDescription()
    }
    
    public func save(fileURL: URL, password: String) throws {
        guard let stream = OutputStream(url: fileURL, append: false) else {
            throw KDBXManagerError.UnableToOpenStream
        }
        stream.open()
        defer {
            stream.close()
        }
        
        if (self.header == nil || self.body == nil) {
            self.header = try KDBXHeader(password: password)
            self.body = try KDBXBody(header: self.header!)
        }
        try self.header?.writeOuterHeader(stream: stream, password: password)
        let newStreamKey = try generateRandomBytes(size: 64)
        
        let hashedKey = Data(SHA512.hash(data: newStreamKey))
        let key = hashedKey.prefix(32)
        let nonce = hashedKey.subdata(in: 32..<(32 + 12))
        
        let xmlString = try self.xmlManager.toXML(streamKey: key, nonce: nonce)
        guard let xmlData = xmlString.data(using: .utf8) else {
            throw KDBXManagerError.UnableToConvertStringToData
        }
        
        try self.body?.loadXMLData(xmlData: xmlData)
        self.body?.streamKey = newStreamKey
        self.body?.streamCipher = 3
        try self.body?.encrypt(writeStream: stream)
    }
    
}
