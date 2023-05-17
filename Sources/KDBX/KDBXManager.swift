import Foundation
import XML

@available(iOS 13.0, *)
@available(macOS 10.15, *)
@available(macOS 13.0, *)
class KDBXManager {
    
    enum KDBXManagerError: Error {
        case BodyNil
        case StreamKeyNil
        case UnableToOpenStream
    }
    
    let header: KDBXHeader
    let body: KDBXBody
    let entries: [Entry]

    init(password: String, fileURL: URL) throws {
        guard let stream = InputStream(url: fileURL) else {
            throw KDBXManagerError.UnableToOpenStream
        }
        stream.open()
        self.header = try KDBXHeader(stream: stream)
        self.body = try KDBXBody(password: password, header: self.header, stream: stream)
        stream.close()
        guard let xmlData = self.body.cleanInnerData else {
            throw KDBXManagerError.BodyNil
        }
        guard let streamKey = self.body.streamKey else {
            throw KDBXManagerError.StreamKeyNil
        }
        let xmlParser = try XMLManager(XMLData: xmlData, cipherKey: streamKey)
        self.entries = xmlParser.entries
    }
    
    func addEntry(entry: Entry) {
        
    }
    
    func getEntries() -> [Entry] {
        return self.entries
    }
}
