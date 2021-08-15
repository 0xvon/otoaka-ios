//
//  PostListViewControllerTests.swift
//  RocketTests
//
//  Created by Masato TSUTSUMI on 2021/08/14.
//

import XCTest
import StubKit
import Endpoint
@testable import Rocket

class PostListViewControllerTests: XCTestCase {

    func testAllocatePaginationRequest() {
        let window = UIWindow()
        let provider: LoggedInDependencyProvider = LoggedInDependencyProvider(
            provider: .makeStub(windowScene: window.windowScene!),
            user: try! Stub.make()
        )
        let user = try! Stub.make(Endpoint.User.self)
        var vc: PostListViewController? = PostListViewController(dependencyProvider: provider, input: .userPost(user))
        vc?.viewDidLoad()
        vc?.viewWillAppear(true)
        vc = nil
    }

}
