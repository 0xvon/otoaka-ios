//
//  MusixmatchAPIAdapter.swift
//  Networking
//
//  Created by Masato TSUTSUMI on 2021/04/07.
//

import Foundation

public class MusixmatchAPIAdapter: HTTPClientAdapter {
    enum Error: Swift.Error {
        case missingURL
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

    private let apiKey: String
    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func beforeRequest<T>(urlRequest: URLRequest, requestBody: T, completion: @escaping (Result<URLRequest, Swift.Error>) -> Void) where T : Decodable, T : Encodable {
        var urlRequest = urlRequest
        guard let url = urlRequest.url,
              var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            completion(.failure(Error.missingURL))
            return
        }
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + [URLQueryItem(name: "apikey", value: apiKey)]
        urlRequest.url = urlComponents.url
        webAPIAdapter.beforeRequest(urlRequest: urlRequest, requestBody: requestBody, completion: completion)
    }
    
    public func afterResponse<Response>(urlResponse: URLResponse, data: Data) throws -> Response where Response : Decodable, Response : Encodable {
        try webAPIAdapter.afterResponse(urlResponse: urlResponse, data: data)
    }
    
}
