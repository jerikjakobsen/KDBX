// Singleton Pattern
// KDBXManager(kdbxFileURL?, MasterPassword, keyFileURL?, writeFileURL?)
/*
 
 if no fdbxFileURL is given then no decryption needed since there is no file to decrypt
 otherwise we must decrypt this file to get the passwords
 if no writeFileURL is given default to saved.kdbx
 let properties = [String: Any]? JSON Format
 let HashedMasterPassword: String
 let keyFileURL: URL?
 let keyFromKeyFile: String?
 let kdbxFileURL: URL?
 let writeFileURL: URL?
 
 - SaveEntries()
 otherwise write to writeFileURL using the masterpassword and keyFile? to encrypt
 use await Encrypt(self.properties, self.HashedMasterPassword, self.keyFromKeyFile, self.writeFileURL, offset = Int)
 offset is the number of bytes to skip in the destination file to write the encrypted data to
 if error throw error
 
 */
// Decrypt KDBX File(fileURL, MasterPassword, Keyfile ?= nil, offset = Int) -> Returns JSON of properties from kdbx
//
// Async Encrypt KDBX File(properties, HashedMasterPassword, keyFromKeyFile ?= nil, writeFileURL) -> Returns the URL to encrypted kdbx file if encryption and write was succesful and nil otherwise



/*
 ReadHeader()
 
 Read first 4 bytes
 - Make sure its 0xB54BFB65
 Read second 4 bytes
 - Make sure its 0xB54BFB67
 
 After this there is a sequence of Type-Length-Value
 where the type code takes 1 byte, the length takes 2 bytes and the Value takes length bytes
 done = true
 While (!done) {
    typeByte = Read(Stream, 1 byte)
    type = getTypeForByte(typeByte)
    if (type == 0) {
        done == true
        break
    }
    lengthBytes = Read(Stream, 2 bytes)
    length = getLengthForBytes(lengthBytes)
    dataBytes = Read(Stream, length bytes)
    switch (type) {
    case
    }
 }
 
 
 
 
 */

class KDBXManager {
    
//    let header: KDBXHeader
//    let stream: InputStream?
//
//    init(password: String, fileURL: URL) throws {
//
//        self.stream = try InputStream(url: fileURL)
//
//        self.header = try KDBXHeader(stream: self.stream, userPassword: password)
//    }
}
