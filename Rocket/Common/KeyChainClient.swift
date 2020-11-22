//
//  KeyChainClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/22.
//

import Foundation

class KeyChainClient {
    func save(key: String, value: String) {
        let valueData: Data = value.data(using: .utf8)!
        let dic: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrGeneric as String: key,
            kSecAttrAccount as String: "account",
            kSecValueData as String: valueData
        ]
        
        var itemAddStatus: OSStatus? = nil
        let matchingStatus = SecItemCopyMatching(dic as CFDictionary, nil)
        switch matchingStatus {
        case errSecItemNotFound:
            itemAddStatus = SecItemAdd(dic as CFDictionary, nil)
        case errSecSuccess:
            itemAddStatus = SecItemUpdate(dic as CFDictionary, [kSecValueData as String: valueData] as CFDictionary)
        default:
            print("error")
        }
        
        if itemAddStatus == errSecSuccess {
            print("ok")
        }
    }
    
    func get(key: String) -> String? {
        let dic: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                      kSecAttrGeneric as String: key,
                                      kSecReturnData as String: kCFBooleanTrue!]

        var data: AnyObject?
        let matchingStatus = withUnsafeMutablePointer(to: &data){
            SecItemCopyMatching(dic as CFDictionary, UnsafeMutablePointer($0))
        }

        if matchingStatus == errSecSuccess {
            print("取得成功")
            if let getData = data as? Data,
                let getStr = String(data: getData, encoding: .utf8) {
                return getStr
            }
            print("取得失敗: Dataが不正")
            return nil
        } else {
            print("取得失敗")
            return nil
        }
    }
    
    func delete(key: String) {
        let dic: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                      kSecAttrGeneric as String: key,
                                      kSecAttrAccount as String: "account"]

        if SecItemDelete(dic as CFDictionary) == errSecSuccess {
            print("削除成功")
        } else {
            print("削除失敗")
        }
    }
}
