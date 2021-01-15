//
//  CreateUserViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/31.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIComponent
import UIKit

class CreateUserViewModel {
    struct State {
        var displayName: String?
        var role: RoleProperties
        var profileImage: UIImage?
        let socialInputs: SocialInputs
    }
    
    enum PageState {
        case loading
        case completed
        case editting(Bool)
    }
    
    enum Output {
        case didCreateUser(User)
        case switchUserRole(RoleProperties)
        case updateSubmittableState(PageState)
        case reportError(Error)
    }

    let dependencyProvider: DependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var createUserAction = Action(Signup.self, httpClient: self.apiClient)

    init(
        dependencyProvider: DependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(role: .fan(Fan()), socialInputs: try! dependencyProvider.masterService.blockingMasterData())
        
        let errors = Publishers.MergeMany(
            createUserAction.errors
        )
        
        Publishers.MergeMany(
            createUserAction.elements.map(Output.didCreateUser).eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        createUserAction.elements
            .sink(receiveValue: { [unowned self] _ in
                outputSubject.send(.updateSubmittableState(.completed))
            })
            .store(in: &cancellables)
    }
    
    func viewDidLoad() {
        outputSubject.send(.switchUserRole(state.role))
    }
    
    func switchRole(role: RoleProperties) {
        self.state.role = role
        outputSubject.send(.switchUserRole(role))
    }
    
    func didUpdateInputItems(displayName: String?, role: String?) {
        state.displayName = displayName
        switch state.role {
        case .fan(_):
            state.role = .fan(Fan())
        case .artist(_):
            guard let role = role else { return }
            state.role = .artist(Artist(part: role))
        }
        
        let isSubmittable = (displayName != nil)
        outputSubject.send(.updateSubmittableState(.editting(isSubmittable)))
    }
    
    func didUpdateArtwork(artwork: UIImage?) {
        self.state.profileImage = artwork
    }

    func didSignupButtonTapped() {
        outputSubject.send(.updateSubmittableState(.loading))
        self.dependencyProvider.s3Client.uploadImage(image: state.profileImage) { [weak self] result in
            switch result {
            case .success(let imageUrl):
                self?.signup(imageUrl: imageUrl)
            case .failure(let error):
                self?.outputSubject.send(.updateSubmittableState(.completed))
                self?.outputSubject.send(.reportError(error))
            }
        }
    }
    
    private func signup(imageUrl: String) {
        guard let displayName = state.displayName else { return }
        let req = Signup.Request(
            name: displayName, biography: nil, thumbnailURL: imageUrl, role: state.role)
        createUserAction.input((request: req, uri: Signup.URI()))
    }
}
