//
//  RequiredVersion.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/01/16.
//

import DomainEntity
import Foundation

public struct RequiredVersion: Codable {
    public let required_version: String
    public let type: String
    public let update_url: String
}
