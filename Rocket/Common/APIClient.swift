//
//  APIClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/21.
//

import Endpoint
import Foundation

protocol APITokenProvider {
    func provideIdToken(_: @escaping (Result<String, Error>) -> Void)
}

class APIClient {
    private let baseURL: URL
    private let tokenProvider: APITokenProvider
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

    init(baseUrl: URL, tokenProvider: APITokenProvider, session: URLSession = .shared) {
        self.baseURL = baseUrl
        self.tokenProvider = tokenProvider
        self.session = session
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

        tokenProvider.provideIdToken { [unowned self] result in
            switch result {
            case .success(let idToken):
                self.request(
                    endpoint, request: request, url: url, idToken: idToken, callback: callback)
            case .failure(let error):
                callback(.failure(error))
            }
        }
    }

    private func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, url: URL, idToken: String,
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) {
        print(url)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = E.method.rawValue
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
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
