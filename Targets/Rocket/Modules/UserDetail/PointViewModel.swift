//
//  PointViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/12/30.
//

import Combine
import Endpoint
import Foundation
import UIComponent

class PointViewModel {
    enum Output {
        case addPoint(Point)
        case usePoint(Point)
        case reportError(Error)
    }
    
    var dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var addPointActon = Action(AddPoint.self, httpClient: apiClient)
    private lazy var usePointAction = Action(UsePoint.self, httpClient: apiClient)
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        
        let errors = Publishers.MergeMany(
            addPointActon.errors,
            usePointAction.errors
        )
        
        Publishers.MergeMany(
            addPointActon.elements.map(Output.addPoint).eraseToAnyPublisher(),
            usePointAction.elements.map(Output.usePoint).eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send(_:))
        .store(in: &cancellables)
    }
    
    func addPoint(point: Int) {
        let request = AddPoint.Request(point: point, expiredAt: nil)
        let uri = AddPoint.URI()
        addPointActon.input((request: request, uri: uri))
    }
    
    func usePoint(point: Int) {
        let request = UsePoint.Request(point: point)
        let uri = UsePoint.URI()
        usePointAction.input((request: request, uri: uri))
    }
}
