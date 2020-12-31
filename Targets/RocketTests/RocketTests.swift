//
//  RocketTests.swift
//  RocketTests
//
//  Created by kateinoigakukun on 2020/10/16.
//

import StubKit
import Foundation
import Endpoint
@testable import Rocket

class MockHTTPClient: HTTPClientProtocol {
    func request<E>(_ endpoint: E.Type, request: E.Request, uri: E.URI, file: StaticString, line: UInt,
                    callback: @escaping ((Result<E.Response, Error>) -> Void)) where E : EndpointProtocol {
        callback(.success(try! Stub.make()))
    }
}

extension UUID: Stubbable {
    public static func stub() -> UUID {
        UUID()
    }
}
