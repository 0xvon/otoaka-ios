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
        var submittable: Bool
        var displayName: String?
        var role: RoleProperties
        var profileImage: UIImage?
        let socialInputs: SocialInputs
    }
    
    enum Output {
        case didCreateUser(User)
        case switchUserRole(RoleProperties)
        case updateSubmittableState(Bool)
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
        self.state = State(submittable: false, role: .fan(Fan()), socialInputs: try! dependencyProvider.masterService.blockingMasterData())
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
        state.submittable = isSubmittable
        outputSubject.send(.updateSubmittableState(isSubmittable))
    }
    
    func didUpdateArtwork(artwork: UIImage?) {
        self.state.profileImage = artwork
    }

    func didSignupButtonTapped() {
        outputSubject.send(.updateSubmittableState(false))
        guard let displayName = state.displayName else { return }
        self.dependencyProvider.s3Client.uploadImage(image: state.profileImage) { [unowned self] result in
            switch result {
            case .success(let imageUrl):
                let req = Signup.Request(
                    name: displayName, biography: nil, thumbnailURL: imageUrl, role: state.role)
                apiClient.request(Signup.self, request: req) { [unowned self] result in
                    updateState(with: result)
                }
            case .failure(let error):
                outputSubject.send(.updateSubmittableState(true))
                outputSubject.send(.reportError(error))
            }
        }
    }
    
    private func updateState(with result: Result<User, Error>) {
        outputSubject.send(.updateSubmittableState(true))
        switch result {
        case .success(let user):
            outputSubject.send(.didCreateUser(user))
        case .failure(let error):
            outputSubject.send(.reportError(error))
        }
    }
}
