//
//  SwiftHex.swift
//  SwiftHex
//
//  Adapted from code from Stack Overflow and the Go encoding/hex library.
//  Licensed under MIT See LICENCE file in the root of this project for details.
//

import Foundation

let hexTable = "0123456789abcdef"

enum HexError : Error {
    case OddLength
    case InvalidByte
}


public func encodeToString(hexBytes: [UInt8]) -> String {
    var outString = ""
    for val in hexBytes {
        // Prefix with 0 for values less than 16.
        if val < 16 { outString += "0" }
        outString += String(val, radix: 16)
    }
    return outString
}

private func trimString(theString: String) -> String? {
    
    let trimmedString = theString.trimmingCharacters(in: CharacterSet(charactersIn: "<> ")).replacingOccurrences(of: " ", with: "")
    
    // Clean up string to remove non-hex digits.
    // Ensure there is an even number of digits.
    do {
        
        let regex = try NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)
        let found = regex.firstMatch(in: trimmedString, options: [], range: NSMakeRange(0, trimmedString.count))
            
        if found == nil || found?.range.location == NSNotFound || trimmedString.count % 2 != 0 {
            return nil
        }
        
        return trimmedString
        
    } catch {
        GraniteLogger.info("Regular expression failed \(error)")
        return nil
    }
}

func decode(source: [UInt8]) throws -> [UInt8] {
    
    let srcLength = source.count
    var decoded: [UInt8] = []
    // Make sure we have an even length.
    if srcLength % 2 == 1 { throw HexError.OddLength }
    
    for i in 0..<srcLength/2 {
        guard let hexVal1 = fromHexChar(hexChar: source[i<<1]) else { throw HexError.InvalidByte }
        
        guard let hexVal2 = fromHexChar(hexChar: source[(i<<1)+1]) else { throw HexError.InvalidByte }
        
        decoded.append(hexVal1 << 4 | hexVal2)
    }
    
    return decoded
}

func fromHexChar(hexChar: UInt8) -> UInt8? {
    
    switch UnicodeScalar(hexChar) {
    case let c where c >= UnicodeScalar("0") && c <= UnicodeScalar("9") :
        return UInt8(c.value - UnicodeScalar("0").value)
        
    case let c where c >= UnicodeScalar("a") && c <= UnicodeScalar("f") :
        let val = c.value - UnicodeScalar("a").value + 10
        return UInt8(val)
        
    case let c where c >= UnicodeScalar("A") && c <= UnicodeScalar("F") :
        let val = c.value - UnicodeScalar("A").value + 10
        return UInt8(val)
        
    default:
        return nil
    }
    
}

/** Takes a hexadecimal number as a string and converts it into bytes.*/
public func decodeString(hexString: String) throws -> [UInt8] {
    let src = [UInt8](hexString.utf8)
    let dest = try decode(source: src)
    return dest
}
