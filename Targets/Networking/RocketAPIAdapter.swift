//
//  RocketAPIAdapter.swift
//  Networking
//
//  Created by kateinoigakukun on 2020/12/29.
//

import Foundation

public class RocketAPIAdapter: HTTPClientAdapter {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    internal lazy var webAPIAdapter = WebAPIAdapter(
        encoder: self.encoder, decoder: self.decoder
    )

    private let tokenProvider: APITokenProvider
    public init(tokenProvider: APITokenProvider) {
        self.tokenProvider = tokenProvider
    }

    public func beforeRequest<T>(urlRequest: URLRequest, requestBody: T, completion: @escaping (Result<URLRequest, Error>) -> Void) where T : Decodable, T : Encodable {
        tokenProvider.provideIdToken { [webAPIAdapter] result in

            let idToken: String
            switch result {
            case .success(let token):
                idToken = token
            case .failure(let error):
                completion(.failure(error))
                return
            }

            var urlRequest = urlRequest
            urlRequest.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            webAPIAdapter.beforeRequest(
                urlRequest: urlRequest, requestBody: requestBody, completion: completion
            )
        }

    }
    
    public func afterRequest<Response>(urlResponse: URLResponse, data: Data) throws -> Response where Response : Decodable, Response : Encodable {
        try webAPIAdapter.afterRequest(urlResponse: urlResponse, data: data)
    }
    
}
