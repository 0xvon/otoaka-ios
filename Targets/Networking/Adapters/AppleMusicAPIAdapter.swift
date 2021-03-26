//
//  AppleMusicAPIAdapter.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/24.
//

import Foundation

public class AppleMusicAPIAdapter: HTTPClientAdapter {
    enum Error: Swift.Error {
        case missingURL
        case someError
    }
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
    
    private let developerToken: String
    public init(developerToken: String) {
        self.developerToken = developerToken
    }
    
    public func beforeRequest<T>(urlRequest: URLRequest, requestBody: T, completion: @escaping (Result<URLRequest, Swift.Error>) -> Void) where T : Decodable, T : Encodable {
        var urlRequest = urlRequest
        urlRequest.addValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
        webAPIAdapter.beforeRequest(urlRequest: urlRequest, requestBody: requestBody, completion: completion)
    }
    
    public func afterResponse<Response>(urlResponse: URLResponse, data: Data) throws -> Response where Response : Decodable, Response : Encodable {
        try webAPIAdapter.afterResponse(urlResponse: urlResponse, data: data)
    }
    
}
