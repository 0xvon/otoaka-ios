//
//  UserDetailViewModelTests.swift
//  RocketTests
//
//  Created by Masato TSUTSUMI on 2021/08/14.
//

import XCTest
import StubKit
import Endpoint
@testable import Rocket

final class UserDetailViewModelTests: XCTestCase {
    func testInitiateVc() {
        let window = UIWindow()
        let provider: LoggedInDependencyProvider = LoggedInDependencyProvider(
            provider: .makeStub(windowScene: window.windowScene!),
            user: try! Stub.make()
        )
        let user = try! Stub.make(Endpoint.User.self)
        var vc: UserDetailViewController? = UserDetailViewController(dependencyProvider: provider, input: user)
        vc?.loadView()
        vc?.viewDidLoad()
        vc?.viewWillAppear(true)
        vc = nil
        RunLoop.main.run(until: Date().addingTimeInterval(1.0))
        print("before exit")
    }
}
