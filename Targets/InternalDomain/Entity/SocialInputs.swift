//
//  Inputs.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/30.
//

import DomainEntity
import Foundation

public struct SocialInputs: Codable {
    let prefectures: [String]
    let parts: [String]
    let years: [String]
    let liveStyles: [String]
    let livehouses: [String]
}
