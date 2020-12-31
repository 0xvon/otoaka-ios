import Endpoint
import Foundation
import Combine

public protocol HTTPClientAdapter {
    func beforeRequest<T: Codable>(
        urlRequest: URLRequest, requestBody: T, completion: @escaping (Result<URLRequest, Error>) -> Void
    )
    func afterResponse<Response: Codable>(urlResponse: URLResponse, data: Data) throws -> Response
}

public protocol HTTPClientInterceptor {
    func intercept(requestError: Error, urlRequest: URLRequest, adapter: HTTPClientAdapter)
    func intercept(responseError: Error, urlResponse: URLResponse?, adapter: HTTPClientAdapter)
}

public struct NopHTTPClientInterceptor: HTTPClientInterceptor {
    public init() {}
    public func intercept(requestError: Error, urlRequest: URLRequest, adapter: HTTPClientAdapter) {}
    public func intercept(responseError: Error, urlResponse: URLResponse?, adapter: HTTPClientAdapter) {}
}

public protocol HTTPClientProtocol {
    func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, uri: E.URI, file: StaticString, line: UInt,
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    )
}

extension HTTPClientProtocol {
    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, uri: E.URI = E.URI(), file: StaticString = #file, line: UInt = #line,
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) {
        self.request(endpoint, request: request, uri: uri, file: file, line: line, callback: callback)
    }

    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        uri: E.URI = E.URI(), file: StaticString = #file, line: UInt = #line,
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) where E.Request == Endpoint.Empty {
        request(E.self, request: Endpoint.Empty(), uri: uri, file: file, line: line, callback: callback)
    }
}

public class HTTPClient<Adapter: HTTPClientAdapter>: HTTPClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    let adapter: Adapter
    let interceptor: HTTPClientInterceptor

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

    public init(baseUrl: URL, adapter: Adapter,
                interceptor: HTTPClientInterceptor = NopHTTPClientInterceptor(),
                session: URLSession = .shared) {
        self.baseURL = baseUrl
        self.adapter = adapter
        self.interceptor = interceptor
        self.session = session
    }

    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, uri: E.URI = E.URI(), file: StaticString = #file, line: UInt = #line,
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) {
        let url: URL
        do {
            url = try uri.encode(baseURL: baseURL)
        } catch {
            callback(.failure(error))
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = E.method.rawValue
        adapter.beforeRequest(urlRequest: urlRequest, requestBody: request) { [unowned self] result in
            switch result {
            case .success(let urlRequest):
                self.request(
                    endpoint, urlRequest: urlRequest, file: file, line: line, callback: callback)
            case .failure(let error):
                interceptor.intercept(
                    requestError: error, urlRequest: urlRequest, adapter: self.adapter
                )
                callback(.failure(error))
            }
        }
    }

    private func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        urlRequest: URLRequest, file: StaticString, line: UInt,
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) {
        let task = session.dataTask(with: urlRequest) { [adapter, interceptor] (data, urlResponse, error) in
            let result: Result<E.Response, Error>
            defer {
                switch result {
                case .failure(let error):
                    interceptor.intercept(responseError: error, urlResponse: urlResponse, adapter: adapter)
                default: break
                }
            }
            if let error = error {
                result = .failure(error)
                return
            }
            guard let data = data, let urlResponse = urlResponse else {
                fatalError("URLSession.dataTask should provide either response or error")
            }
            result = Result<E.Response, Error> {
                try adapter.afterResponse(urlResponse: urlResponse, data: data)
            }
            callback(result)
        }
        task.resume()
    }
}

// MARK: - Combine Extensions
extension HTTPClientProtocol {
    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        uri: E.URI = E.URI(), file: StaticString = #file, line: UInt = #line
    ) -> Future<E.Response, Error>
    where E.Request == Endpoint.Empty {
        request(endpoint, request: Endpoint.Empty(), uri: uri, file: file, line: line)
    }

    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, uri: E.URI = E.URI(), file: StaticString = #file, line: UInt = #line
    ) -> Future<E.Response, Error> {
        return Future { promise in
            self.request(endpoint, request: request, uri: uri, file: file, line: line, callback: promise)
        }
    }
}
