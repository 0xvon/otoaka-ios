//
//  DependencyProvider.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import Foundation
import AWSCognitoAuth

struct DependencyProvider {
    var auth: AWSCognitoAuth
}

extension DependencyProvider {

    #if DEBUG
    static func make() -> DependencyProvider {
        .make(config: DevelopmentConfig.self)
    }
    #endif
    static func make(config: Config.Type) -> DependencyProvider {
        let cognitoConfiguration = AWSCognitoAuthConfiguration(
            appClientId: config.appClientId,
            appClientSecret: config.appClientSecret,
            scopes: config.scopes,
            signInRedirectUri: config.signInRedirectUri,
            signOutRedirectUri: config.signOutRedirectUri,
            webDomain: config.webDomain,
            identityProvider: nil,
            idpIdentifier: nil,
            userPoolIdForEnablingASF: config.userPoolIdForEnablingASF
        )
        AWSCognitoAuth.registerCognitoAuth(with: cognitoConfiguration, forKey: "cognitoAuth")
        let auth = AWSCognitoAuth.init(forKey: "cognitoAuth")
        return DependencyProvider(auth: auth)
    }
}
