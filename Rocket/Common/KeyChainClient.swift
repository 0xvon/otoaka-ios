//
//  KeyChainClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/22.
//

import Foundation
import KeychainAccess

class KeyChainClient {
    let keyChain: Keychain
    
    init() {
        self.keyChain = Keychain(service: "dev.wall-of-death.Rocket")
    }
    
    func save(key: String, value: String) {
        keyChain[key] = value
    }
    
    func get(key: String) -> String? {
        do {
            let val = try keyChain.getString(key)
            return val
        } catch let error {
            print(error)
            return nil
        }
    }
    
    func delete(key: String) {
        keyChain[key] = nil
    }
}
