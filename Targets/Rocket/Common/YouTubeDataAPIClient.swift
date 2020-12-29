//
//  YouTubeDataAPIClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import Endpoint
import Foundation
import InternalDomain

class YouTubeDataAPIClient {
    private let baseURL: URL
    private let apiKey: String
    private let session: URLSession
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

    init(baseUrl: URL, apiKey: String, session: URLSession = .shared) {
        self.baseURL = baseUrl
        self.apiKey = apiKey
        self.session = session
    }
    
    public func getApiKey() -> String {
        return self.apiKey
    }

    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        uri: E.URI = E.URI(),
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) where E.Request == Empty {
        request(E.self, request: Empty(), uri: uri, callback: callback)
    }

    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, uri: E.URI = E.URI(),
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) {
        let url: URL
        do {
            url = try uri.encode(baseURL: baseURL)
        } catch {
            callback(.failure(error))
            return
        }
        
        self.request(
            endpoint, request: request, url: url, callback: callback)
    }

    private func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, url: URL,
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) {
        print(url)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = E.method.rawValue
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if E.method != .get {
            urlRequest.httpBody = try! encoder.encode(request)
        }

        let task = session.dataTask(with: urlRequest) { [decoder] (data, response, error) in
            if let error = error {
                callback(.failure(error))
                return
            }
            guard let data = data else {
                fatalError("URLSession.dataTask should provide either response or error")
            }

            do {

                if let httpResponse = response as? HTTPURLResponse {
                    if (200...299).contains(httpResponse.statusCode) {
                        let response: E.Response = try decoder.decode(E.Response.self, from: data)
                        callback(.success(response))
                    } else {
                        print(httpResponse.statusCode)
                        let errorMessage = try decoder.decode(String.self, from: data)
                        callback(
                            .failure(
                                APIError.invalidStatus(
                                    "status: \(httpResponse.statusCode), message: \(errorMessage)"))
                        )
                        print()
                    }
                }
            } catch let error {
                callback(.failure(error))
                return
            }
        }
        task.resume()
    }
}

public struct ListChannel: EndpointProtocol {
    public typealias Request = Empty
    public typealias Response = ChannelDetail
    public struct URI: CodableURL {
        @StaticPath("youtube", "v3", "search") public var prefix: Void
        @Query public var channelId: String
        @Query public var part: String
        @Query public var key: String
        @Query public var maxResults: Int?
        @Query public var order: String?
        public init() {}
    }
    public static let method: HTTPMethod = .get
}
