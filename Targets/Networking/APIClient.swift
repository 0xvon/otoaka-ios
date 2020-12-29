//
//  APIClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/21.
//

import Endpoint
import Foundation
import Combine

public protocol APITokenProvider {
    func provideIdToken(_: @escaping (Result<String, Error>) -> Void)
}

public enum APIError: Error {
    case invalidStatus(String)
}
