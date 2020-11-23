//
//  KeyChainClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/22.
//

import Foundation
import KeychainAccess

class KeyChainClient {
    private let keyChain: Keychain
    
    init() {
        self.keyChain = Keychain(service: "dev.wall-of-death.Rocket")
    }
    
    public func save(key: String, value: String) throws {
        do {
            try keyChain.set(value, key: key)
        } catch let error {
            throw error
        }
    }
    
    public func get(key: String) throws -> String? {
        do {
            let val = try keyChain.getString(key)
            return val
        } catch let error {
            throw error
        }
    }
    
    public func delete(key: String) throws {
        do {
            try keyChain.remove(key)
        } catch let error {
            throw error
        }
    }
}
