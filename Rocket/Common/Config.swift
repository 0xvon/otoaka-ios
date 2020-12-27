//
//  Config.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import Foundation

protocol Config {
    static var appClientId: String { get }
    static var appClientSecret: String { get }
    static var cognitoCcopes: Set<String> { get }
    static var cognitoSignInRedirectUri: String { get }
    static var cognitoSignOutRedirectUri: String { get }
    static var cognitoWebDomain: String { get }
    static var userPoolIdForEnablingASF: String { get }
    static var apiEndpoint: String { get }
    static var s3Bucket: String { get }
    static var identityPoolId: String { get }
    static var youTubeApiKey: String { get }
}
