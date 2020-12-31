//
//  LiveDetailViewModelTests.swift
//  RocketTests
//
//  Created by kateinoigakukun on 2020/12/31.
//

import XCTest
import StubKit
import Endpoint
@testable import Rocket

class MockHTTPClient: HTTPClientProtocol {
    func request<E>(_ endpoint: E.Type, request: E.Request, uri: E.URI, file: StaticString, line: UInt,
                    callback: @escaping ((Result<E.Response, Error>) -> Void)) where E : EndpointProtocol {
        callback(.success(try! Stub.make()))
    }
}

final class LiveDetailViewModelTests: XCTestCase {
    func testReserveAndRefundTicket() {
        let viewModel = try! ReserveTicketViewModel(live: Stub.make(), apiClient: MockHTTPClient())
        viewModel.viewDidLoad()
        viewModel.didGetLiveDetail(ticket: nil, participantsCount: 1)
        viewModel.didButtonTapped()
        viewModel.didButtonTapped()
    }
}
