//
//  YouTubeDataAPIClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import Endpoint
import Foundation

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

public struct ChannelDetail: Codable {
    public var kind: String
    public var etag: String
    public var nextPageToken: String?
    public var prevPageToken: String?
    public var regionCode: String?
    public var pageInfo: PageInfo
    public var items: [ChannelItem]
    
    public struct PageInfo: Codable {
        public var totalResults: Int
        public var resultsPerPage: Int
    }
    
    public struct ChannelItem: Codable {
        public var kind: String
        public var etag: String
        public var id: ItemId
        public var snippet: ItemSnippet
        
        public struct ItemId: Codable {
            public var kind: String
            public var videoId: String
        }
        
        public struct ItemSnippet: Codable {
            public var publishedAt: Date
            public var channelId: String?
            public var title: String?
            public var description: String?
            public var thumbnails: Tumbnails
            public var channelTitle: String
            public var liveBroadcastContent: String?
            public var publishTime: Date?
                
            public struct Tumbnails: Codable {
                public var `default`: ThumbnailItem
                public var medium: ThumbnailItem
                public var high: ThumbnailItem
                
                public struct ThumbnailItem: Codable {
                    public var url: String
                    public var width: Int
                    public var height: Int
                }
            }
        }
    }
}
