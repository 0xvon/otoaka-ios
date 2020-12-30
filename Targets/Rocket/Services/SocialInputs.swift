//
//  Inputs.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/30.
//

import DomainEntity
import Foundation

public struct SocialInputs: Codable {
    public let prefectures: [String]
    public let parts: [String]
    public let years: [String]
    public let liveStyles: [String]
    public let livehouses: [String]
}