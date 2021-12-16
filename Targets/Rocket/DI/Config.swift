//
//  Config.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import Foundation

protocol Config {
    static var auth0ClientUrl: String { get }
    static var cognitoIdentityPoolId: String { get }

    static var apiEndpoint: String { get }
    static var s3Bucket: String { get }
    static var youTubeApiKey: String { get }
    static var appleMusicDeveloperToken: String { get }
    static var musixmatchApiKey: String { get }
}
