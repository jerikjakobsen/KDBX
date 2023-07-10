import Foundation
import XML
import StreamCiphers

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
class KDBXManager {
    
    enum KDBXManagerError: Error {
        case BodyNil
        case StreamKeyNil
        case UnableToOpenStream
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
        self.header = try KDBXHeader(stream: stream)
        self.body = try KDBXBody(password: password, header: self.header!, stream: stream)
        stream.close()
        guard let xmlData = self.body?.cleanInnerData else {
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
}
