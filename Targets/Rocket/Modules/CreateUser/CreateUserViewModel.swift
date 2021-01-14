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

    init(
        dependencyProvider: DependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(role: .fan(Fan()), socialInputs: try! dependencyProvider.masterService.blockingMasterData())
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
        guard let displayName = state.displayName else { return }
        self.dependencyProvider.s3Client.uploadImage(image: state.profileImage) { [weak self] result in
            switch result {
            case .success(let imageUrl):
                guard let state = self?.state else { return }
                let req = Signup.Request(
                    name: displayName, biography: nil, thumbnailURL: imageUrl, role: state.role)
                self?.apiClient.request(Signup.self, request: req) { [weak self] result in
                    self?.updateState(with: result)
                }
            case .failure(let error):
                self?.outputSubject.send(.updateSubmittableState(.completed))
                self?.outputSubject.send(.reportError(error))
            }
        }
    }
    
    private func updateState(with result: Result<User, Error>) {
        outputSubject.send(.updateSubmittableState(.completed))
        switch result {
        case .success(let user):
            outputSubject.send(.didCreateUser(user))
        case .failure(let error):
            outputSubject.send(.reportError(error))
        }
    }
}
