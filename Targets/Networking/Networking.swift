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
        request: E.Request, uri: E.URI, file: StaticString, line: UInt
    ) -> AnyPublisher<E.Response, Error>

    func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, uri: E.URI, file: StaticString, line: UInt,
        callback: @escaping ((Result<E.Response, Error>) -> Void))
}

extension HTTPClientProtocol {
    @available(*, deprecated)
    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, uri: E.URI = E.URI(), file: StaticString = #file, line: UInt = #line,
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) {
        self.request(endpoint, request: request, uri: uri, file: file, line: line, callback: callback)
    }

    @available(*, deprecated)
    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        uri: E.URI = E.URI(), file: StaticString = #file, line: UInt = #line,
        callback: @escaping ((Result<E.Response, Error>) -> Void)
    ) where E.Request == Endpoint.Empty {
        self.request(endpoint, request: Endpoint.Empty(), uri: uri, file: file, line: line, callback: callback)
    }

    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, uri: E.URI = E.URI(), file: StaticString = #file, line: UInt = #line
    ) -> AnyPublisher<E.Response, Error> {
        self.request(endpoint, request: request, uri: uri, file: file, line: line)
    }

    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        uri: E.URI = E.URI(), file: StaticString = #file, line: UInt = #line
    ) -> AnyPublisher<E.Response, Error> where E.Request == Endpoint.Empty {
        request(E.self, request: Endpoint.Empty(), uri: uri, file: file, line: line)
    }
}

public class HTTPClient<Adapter: HTTPClientAdapter>: HTTPClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    let adapter: Adapter
    let interceptor: HTTPClientInterceptor

    private var tasks: [AnyCancellable] = []

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
        callback: @escaping ((Result<E.Response, Error>) -> Void)) {
        self.request(endpoint, request: request, uri: uri, file: file, line: line)
            .sink(
                receiveCompletion: {
                    switch $0 {
                    case .failure(let error):
                        callback(.failure(error))
                    case .finished: break
                    }
                },
                receiveValue: {
                    callback(.success($0))
                }
            )
            .store(in: &tasks)
    }

    public func request<E: EndpointProtocol>(
        _ endpoint: E.Type,
        request: E.Request, uri: E.URI = E.URI(), file: StaticString = #file, line: UInt = #line
    ) -> AnyPublisher<E.Response, Error> {
        let url: URL
        do {
            url = try uri.encode(baseURL: baseURL)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = E.method.rawValue
        let beforeRequest = Future<URLRequest, Error> { [adapter] promise in
            adapter.beforeRequest(urlRequest: urlRequest, requestBody: request, completion: promise)
        }
        return beforeRequest
            .handleEvents(receiveCompletion: { [interceptor, adapter] in
                switch $0 {
                case .failure(let error):
                    interceptor.intercept(
                        requestError: error, urlRequest: urlRequest, adapter: adapter
                    )
                case .finished: break
                }
            })
            .flatMap { [session, interceptor, adapter] urlRequest in
                session.dataTaskPublisher(for: urlRequest)
                    .tryMap {  (data, urlResponse) -> E.Response in
                        let result = Result<E.Response, Error> {
                            try adapter.afterResponse(urlResponse: urlResponse, data: data)
                        }
                        switch result {
                        case .failure(let error):
                            interceptor.intercept(responseError: error, urlResponse: urlResponse, adapter: adapter)
                        default: break
                        }
                        return try result.get()
                    }
            }
            .eraseToAnyPublisher()
    }
}
