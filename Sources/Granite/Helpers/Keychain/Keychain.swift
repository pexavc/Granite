//
//  Keychain.swift
//
//
//  Created by PEXAVC on 2/11/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import AuthenticationServices
import CryptoKit

public enum KeychainError: Error {
    case secCallFailed(OSStatus)
    case notFound
    case badData
    case archiveFailure(Error)
}

public protocol Keychain {
    associatedtype DataType: Codable

    var account: String { get set }
    var service: String { get set }

    func remove() throws
    func retrieve() throws -> DataType
    func store(_ data: DataType) throws
}

extension Keychain {
    public func remove() throws {
        let status = SecItemDelete(keychainQuery() as CFDictionary)
        guard status == noErr || status == errSecItemNotFound else {
            throw KeychainError.secCallFailed(status)
        }
    }

    public func retrieve() throws -> DataType {
        var query = keychainQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        guard status != errSecItemNotFound else { throw KeychainError.notFound }
        guard status == noErr else { throw KeychainError.secCallFailed(status) }

        do {
            guard
            let dict = result as? [String: AnyObject],
            let data = dict[kSecAttrGeneric as String] as? Data,
            let userData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? DataType
            else {
                throw KeychainError.badData
            }

            return userData
        } catch {
            throw KeychainError.archiveFailure(error)
        }
    }

    public func store(_ data: DataType) throws {
        var query = keychainQuery()

        let archived: AnyObject
        do {
            archived = try NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true) as AnyObject
        } catch {
            throw KeychainError.archiveFailure(error)
        }

        let status: OSStatus
        do {
            _ = try retrieve()

            let updates = [
                String(kSecAttrGeneric): archived
            ]

            status = SecItemUpdate(query as CFDictionary, updates as CFDictionary)
        } catch KeychainError.notFound {
            query[kSecAttrGeneric as String] = archived
            status = SecItemAdd(query as CFDictionary, nil)
        }

        guard status == noErr else {
            throw KeychainError.secCallFailed(status)
        }
    }

    private func keychainQuery() -> [String: AnyObject] {
        var query: [String: AnyObject] = [:]
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject
        query[kSecAttrAccount as String] = account as AnyObject

        return query
    }
}

public class UserData: NSObject, Codable, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    public let email: String

    public let name: PersonNameComponents

    public let identifier: String

    public init(
        email: String,
        name: PersonNameComponents,
        identifier: String) {
        
        self.email = email
        self.name = name
        self.identifier = identifier
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(email, forKey: "email")
        coder.encode(identifier, forKey: "identifier")
    }
    
    public required convenience init?(coder: NSCoder) {
        let nameDecode = coder.decodeObject(forKey: "name") as? PersonNameComponents
        let emailDecode = coder.decodeObject(forKey: "email") as? String
        let idDecode = coder.decodeObject(forKey: "identifier") as? String
        guard   let name = nameDecode,
                let email = emailDecode,
                let id = idDecode else { return nil }
        
        
        self.init(email: email, name: name, identifier: id)
    }
    
    public func displayName(
        style: PersonNameComponentsFormatter.Style = .default) -> String {
        PersonNameComponentsFormatter.localizedString(
            from: name,
            style: style)
    }
}

public struct UserDataKeychain: Keychain {
    public var account = "com.linenandsole.stoic"
    public var service = "com.linenandsole.stoic.account"
    public var currentNonce: String
    public typealias DataType = UserData
    
    public init() {
        let nonce = UserDataKeychain.randomNonceString()
        self.currentNonce = nonce
    }
    
    public func generateRequest() -> (data: DataType?, provider: ASAuthorizationAppleIDProvider, request: ASAuthorizationAppleIDRequest) {
        let userData = try? retrieve()
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = UserDataKeychain.sha256(currentNonce)
        
        return (userData, appleIDProvider, request)
    }
    
    public static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()

        return hashString
    }
    
    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}
