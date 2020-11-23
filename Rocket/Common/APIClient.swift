//
//  APIClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/21.
//

import Endpoint
import Foundation

class APIClient {
    private let baseURL: URL
    private var idToken: String?
    private let session: URLSession
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = JSONDecoder()
    
    init(baseUrl: URL, idToken: String?, session: URLSession = .shared) {
        self.baseURL = baseUrl
        self.idToken = idToken
        self.session = session
    }

    func login(with idToken: String) throws {
        self.idToken = idToken
        do {
            try KeyChainClient().save(key: "ID_TOKEN", value: idToken)
        }
    }
    
    func isLoggedIn() -> Bool {
        return self.idToken != nil
    }

    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        uri: E.URI = E.URI(),
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) throws where E.Request == Empty {
        try request(E.self, request: Empty(), uri: uri, callback: callback)
    }

    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, uri: E.URI = E.URI(),
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) throws {
        let url = try uri.encode(baseURL: baseURL)
        print(url)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = E.method.rawValue
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let idToken = idToken {
            urlRequest.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
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
                        let errorMessage = try decoder.decode(String.self, from: data)
                        callback(.failure(APIError.invalidStatus("status: \(httpResponse.statusCode), message: \(errorMessage)")))
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
