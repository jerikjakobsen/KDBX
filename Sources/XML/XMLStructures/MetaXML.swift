//
//  Meta.swift
//  
//
//  Created by John Jakobsen on 5/13/23.
//

import Foundation
import SWXMLHash
import StreamCiphers

@available(iOS 13.0, *)
@available(macOS 13.0, *)
public final class MetaXML: NSObject, XMLObjectDeserialization, Serializable, ModifyListener {
    
    internal var generator: XMLString
    internal var databaseName: XMLString
    internal var databaseDescription: XMLString
    internal var times: TimesXML
    public var color: ColorXML? {
        didSet {
            self.color?.modifyListener = self
        }
    }
    
    internal init(generator: XMLString, databaseName: XMLString, databaseDescription: XMLString, times: TimesXML, color: ColorXML?) {
        self.generator = generator
        self.databaseName = databaseName
        self.databaseDescription = databaseDescription
        self.times = times
        self.color = color
        super.init()
        self.generator.modifyListener = self
        self.databaseName.modifyListener = self
        self.databaseDescription.modifyListener = self
        self.color?.modifyListener = self
    }
    
    public init(generator: String = "Keys", databaseName: String, databaseDescription: String, color: ColorXML? = nil) {
        self.generator = XMLString(content: generator, name: "Generator")
        self.databaseName = XMLString(content: databaseName, name: "DatabaseName")
        self.databaseDescription = XMLString(content: databaseDescription, name: "DatabaseDescription")
        self.times = TimesXML.now(expires: false, expiryTime: nil)
        self.color = color
        super.init()
        self.generator.modifyListener = self
        self.databaseName.modifyListener = self
        self.databaseDescription.modifyListener = self
        self.color?.modifyListener = self
    }
    
    public static func deserialize(_ element: XMLIndexer) throws -> MetaXML {
        
        var times: TimesXML = (try? element["Times"].value()) ?? TimesXML.now(expires: false)
        times.update(modified: false)
        
        return MetaXML(
            generator: try element["Generator"].value(),
            databaseName: try element["DatabaseName"].value(),
            databaseDescription: try element["DatabaseDescription"].value(),
            times: times,
            color: try? element["Color"].value())
    }
    
    func serialize(base64Encoded: Bool, streamCipher: StreamCipher?) throws -> String {
        return try """
<Meta>
\(generator.serialize())
\(databaseName.serialize())
\(databaseDescription.serialize())
\(color?.serialize() ?? "")
\(times.serialize())
</Meta>
"""
    }
    
    public func setDBName(name: String) {
        self.databaseName.content = name
    }
    public func getDBName() -> String {
        return self.databaseName.content
    }
    
    public func setDBDescription(description: String) {
        self.databaseDescription.content = description
    }
    
    public func getDBDescription() -> String {
        return self.databaseDescription.content
    }
    
    public func didModify(date: Date) {
        self.times.update(modified: true, date: date)
    }
    
    public func isEqual(_ object: MetaXML?) -> Bool {
        guard let notNil = object else {
            return false
        }
        return (notNil.generator.isEqual(generator) &&
                notNil.databaseName.isEqual(databaseName) &&
                notNil.databaseDescription.isEqual(databaseDescription))
    }
    public override var description: String {
        return "Generator: \(generator.description)\nDatabase Name: \(databaseName.description)\nDatabase Description: \(databaseDescription.description)"
    }
}
