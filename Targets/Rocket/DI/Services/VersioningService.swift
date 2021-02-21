import Combine
import Foundation
import Endpoint
import Networking

struct VersioningAPIRequest: EndpointProtocol {
    typealias Request = Endpoint.Empty
    typealias Response = RequiredVersion
    struct URI: CodableURL {}
    static let method: HTTPMethod = .get
}

public final class VersioningSerivice {
    private let httpClient: HTTPClient<WebAPIAdapter>
    init(httpClient: HTTPClient<WebAPIAdapter>) {
        self.httpClient = httpClient
    }
    public func fetchMasterData() -> AnyPublisher<RequiredVersion, Error> {
        httpClient.request(VersioningAPIRequest.self)
    }

    private var cancellables: [AnyCancellable] = []
    @available(*, deprecated)
    public func blockingMasterData() throws -> RequiredVersion {
        URLCache.shared.removeAllCachedResponses()
        
        var result: Result<RequiredVersion, Error>!
        let semaphore = DispatchSemaphore(value: 0)
        fetchMasterData().sink(receiveCompletion: {
            switch $0 {
            case .failure(let error):
                result = .failure(error)
            case .finished: break
            }
            semaphore.signal()
        }, receiveValue: {
            result = .success($0)
        })
        .store(in: &cancellables)
        semaphore.wait()
        return try result.get()
    }
}
