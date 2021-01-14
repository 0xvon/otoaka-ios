import Networking
import Endpoint
import Combine

extension Action {
    convenience init<E: EndpointProtocol>(
        _ endpoint: E.Type, httpClient: HTTPClientProtocol,
        file: StaticString = #file, line: UInt = #line
    ) where Input == (request: E.Request, uri: E.URI), E.Response == Element {
        self.init(enabledIf: Just(true)) { (request, uri) -> AnyPublisher<Element, Error> in
            httpClient.request(endpoint, request: request, uri: uri, file: file, line: line)
        }
    }
}
