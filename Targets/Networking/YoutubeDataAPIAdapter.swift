//
//  YoutubeDataAPIAdapter.swift
//  Networking
//
//  Created by kateinoigakukun on 2020/12/30.
//

import Foundation

public class YoutubeDataAPIAdapter: HTTPClientAdapter {
    enum Error: Swift.Error {
        case missingURL
    }
    internal let webAPIAdapter = WebAPIAdapter()

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
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + [URLQueryItem(name: "key", value: apiKey)]
        urlRequest.url = urlComponents.url
        webAPIAdapter.beforeRequest(urlRequest: urlRequest, requestBody: requestBody, completion: completion)
    }
    
    public func afterResponse<Response>(urlResponse: URLResponse, data: Data) throws -> Response where Response : Decodable, Response : Encodable {
        try webAPIAdapter.afterResponse(urlResponse: urlResponse, data: data)
    }
    
}
