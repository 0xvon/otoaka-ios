//
//  LoggingAdapter.swift
//  Networking
//
//  Created by kateinoigakukun on 2020/12/30.
//

import Foundation

public protocol Logger {
    func log(_ message: String)
}

public final class LoggingAdapter: HTTPClientAdapter {
    internal let adapter: HTTPClientAdapter
    internal let logger: Logger

    public init(adapter: HTTPClientAdapter, logger: Logger) {
        self.adapter = adapter
        self.logger = logger
    }

    var logPrefix: String {
        "\(Date()) [\(type(of: adapter))]"
    }
    public func beforeRequest<T>(
        urlRequest: URLRequest, requestBody: T,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) where T: Decodable, T: Encodable {
        let prefix = logPrefix
        adapter.beforeRequest(
            urlRequest: urlRequest, requestBody: requestBody,
            completion: { [logger] result in
                guard case .failure(let error) = result else {
                    completion(result)
                    return
                }
                logger.log(
                    "\(prefix) [ ERROR ]: Request Error: \(urlRequest.url?.absoluteString ?? "url is not set") \(error)"
                )
            }
        )
    }

    public func afterRequest<Response>(urlResponse: URLResponse, data: Data) throws -> Response
    where Response: Decodable, Response: Encodable {
        do {
            return try adapter.afterRequest(urlResponse: urlResponse, data: data)
        } catch {
            logger.log(
                "\(Date()) [\(type(of: adapter))] [ ERROR ]: Response Error: \(urlResponse.url?.absoluteString ?? "url is not set") \(error)"
            )
            throw error
        }
    }

}

public class ConsoleLogger: Logger {
    public init() {}
    public func log(_ message: String) {
        print(message)
    }
}
