//
//  WebAPIAdapter.swift
//  Networking
//
//  Created by kateinoigakukun on 2020/12/29.
//

import Foundation

public enum WebAPIError: Error, CustomStringConvertible {
    case nonHTTPURLResponse(URLResponse)
    case decodingError(error: Error, body: String?, httpURLResponse: HTTPURLResponse)
    case unacceptableStatusCode(statusCode: Int, body: String?, httpURLResponse: HTTPURLResponse)

    public var description: String {
        switch self {
        case .nonHTTPURLResponse(let urlResponse):
            return """
            nonHTTPURLResponse: \(urlResponse.description)
            """
        case let .decodingError(error, body, httpURLResponse):
            var content = """
            decodingError:
              error: \(error)\n
            """
            if let body = body {
                content += "  body:\n\(body)\n"
            }
            content += "  httpURLResponse: \(httpURLResponse)"
            return content
        case let .unacceptableStatusCode(statusCode, body, httpURLResponse):
            var content = """
            unacceptableStatusCode:
              statusCode: \(statusCode)\n
            """
            if let body = body {
                content += "  body:\n\(body)\n"
            }
            content += "  httpURLResponse: \(httpURLResponse)"
            return content
        }
    }
}

public class WebAPIAdapter: HTTPClientAdapter {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) {
        self.encoder = encoder
        self.decoder = decoder
    }

    public func beforeRequest<T>(urlRequest: URLRequest, requestBody: T, completion: (Result<URLRequest, Error>) -> Void) where T : Decodable, T : Encodable {
        var urlRequest = urlRequest
        let result = Result<URLRequest, Error> {
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            if urlRequest.httpMethod != "GET" {
                urlRequest.httpBody = try encoder.encode(requestBody)
            }
            return urlRequest
        }
        completion(result)
    }

    public func afterResponse<Response: Codable>(urlResponse: URLResponse, data: Data) throws -> Response {
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw WebAPIError.nonHTTPURLResponse(urlResponse)
        }
        if (200..<300).contains(httpResponse.statusCode) {
            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw WebAPIError.decodingError(
                    error: error, body: String(data: data, encoding: .utf8),
                    httpURLResponse: httpResponse
                )
            }
        } else {
            throw WebAPIError.unacceptableStatusCode(
                statusCode: httpResponse.statusCode, body: String(data: data, encoding: .utf8),
                httpURLResponse: httpResponse
            )
        }
    }
}
