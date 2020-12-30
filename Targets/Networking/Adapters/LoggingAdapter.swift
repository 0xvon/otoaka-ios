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

public final class LoggingInterceptor: HTTPClientInterceptor {
    internal let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func intercept(requestError: Error, urlRequest: URLRequest, adapter: HTTPClientAdapter) {
        logger.log(
            """
            \(Date()) [\(type(of: adapter))] [ ERROR ]: Request Error:
            \(urlRequest.url?.absoluteString ?? "url is not set"):
            \(requestError)
            """
        )

    }

    public func intercept(responseError: Error, urlResponse: URLResponse?, adapter: HTTPClientAdapter) {
        logger.log(
            """
            \(Date()) [\(type(of: adapter))] [ ERROR ]: Response Error:
            \(urlResponse?.url?.absoluteString ?? "url is not set"):
            \(responseError)
            """
        )
    }
}

public class ConsoleLogger: Logger {
    public init() {}
    public func log(_ message: String) {
        print(message)
    }
}
