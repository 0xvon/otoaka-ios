//
//  RocketTests.swift
//  RocketTests
//
//  Created by kateinoigakukun on 2020/10/16.
//

import StubKit
import Foundation
@testable import Rocket

extension UUID: Stubbable {
    public static func stub() -> UUID {
        UUID()
    }
}
