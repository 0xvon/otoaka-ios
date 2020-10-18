//
//  Config.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import Foundation

protocol Config {
    
    static var poolId: String { get }
    static var appClientId: String { get }
    static var appClientSecret: String { get }
    static var scopes: Set<String> { get }
    static var signInRedirectUri: String { get }
    static var signOutRedirectUri: String { get }
    static var webDomain: String { get }
    static var userPoolIdForEnablingASF: String { get }
}
