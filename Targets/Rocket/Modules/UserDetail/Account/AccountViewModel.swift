//
//  AccountViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/29.
//

import AWSCognitoAuth
import Endpoint
import UIKit
import Combine

class AccountViewModel {
    enum Output {
        case didGetRequestCount(Int)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var getPendingRequestCountAction = Action(GetPendingRequestCount.self, httpClient: self.apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        
        let errors = Publishers.MergeMany(
            getPendingRequestCountAction.errors
        )
        
        Publishers.MergeMany(
            getPendingRequestCountAction.elements.map { res in .didGetRequestCount(res.pendingRequestCount) }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    func viewDidLoad() {
        getPerformanceRequest()
    }
    
    func getPerformanceRequest() {
        let req = Empty()
        let uri = GetPendingRequestCount.URI()
        getPendingRequestCountAction.input((request: req, uri: uri))
    }
}
