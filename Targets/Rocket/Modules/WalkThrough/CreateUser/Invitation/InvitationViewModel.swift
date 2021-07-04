//
//  InvitationViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/01.
//

import Endpoint
import Foundation
import Combine

class InvitationViewModel {

    enum Output {
        case didJoinGroup
        case reportError(Error)
    }

    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var joinGroupAction = Action(JoinGroup.self, httpClient: self.apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        
        let errors = Publishers.MergeMany(
            joinGroupAction.errors
        )
        
        Publishers.MergeMany(
            joinGroupAction.elements.map { _ in .didJoinGroup }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }

    func joinGroup(invitationCode: String?) {
        if let invitationCode = invitationCode {
            let req = JoinGroup.Request(invitationId: invitationCode)
            joinGroupAction.input((request: req, uri: JoinGroup.URI()))
        }
    }

    func enterInvitationCode(invitationCode: String?) {

    }
}
