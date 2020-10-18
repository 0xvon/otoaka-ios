//
//  ENV.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import Foundation

struct config: Config {
    
    static var poolId = "ap-northeast-1_nlfNXr0Al"
    
    static var appClientId = "5hf5eq8jshidut5qcfptd7mg0u"

    static var appClientSecret = "15dduv4ad7473l1nemcqefgrmnf2tlja5d7j8u9htf9b5glf9ia7"

    static var scopes = Set(["aws.cognito.signin.user.admin"])

    static var signInRedirectUri = "dev.wall-of-death.Rocket://users/cognito/signin"

    static var signOutRedirectUri = "dev.wall-of-death.Rocket://users/cognito/signout"

    static var webDomain = "https://rocket.auth.ap-northeast-1.amazoncognito.com"

    static var userPoolIdForEnablingASF = "ap-northeast-1_nlfNXr0Al"

}
