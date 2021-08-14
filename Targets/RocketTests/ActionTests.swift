//
//  ActionTests.swift
//  RocketTests
//
//  Created by Masato TSUTSUMI on 2021/08/14.
//

import XCTest
import Endpoint
@testable import Rocket
import StubKit
import Combine

class ActionTests: XCTestCase {

    func testNoLeak() {
        let window = UIWindow()
        let provider: LoggedInDependencyProvider = LoggedInDependencyProvider(
            provider: .makeStub(windowScene: window.windowScene!),
            user: try! Stub.make()
        )
        var viewModel: UserDetailViewModel? = UserDetailViewModel(dependencyProvider: provider, user: try! Stub.make())
        var cancellables: Set<AnyCancellable> = []
        viewModel?.viewDidLoad()
        viewModel?.output.sink(receiveValue: { output in
            print(output)
        }).store(in: &cancellables)

        viewModel = nil
    }
    
}
