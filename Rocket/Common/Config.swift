//
//  Config.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import Foundation

protocol Config {
    static var cognitoAppClientId: String { get }
    static var cognitoAppClientSecret: String { get }
    static var cognitoScopes: Set<String> { get }
    static var cognitoSignInRedirectUri: String { get }
    static var cognitoSignOutRedirectUri: String { get }
    static var cognitoWebDomain: String { get }
    static var cognitoIdentityPoolId: String { get }

    static var apiEndpoint: String { get }
    static var s3Bucket: String { get }
    static var youTubeApiKey: String { get }
}
