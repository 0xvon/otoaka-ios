//
//  EditUserViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIComponent
import UIKit

class EditUserViewModel {
    struct State {
        var submittable: Bool
        var displayName: String?
        var biography: String?
        var role: RoleProperties
        var profileImage: UIImage?
        let socialInputs: SocialInputs
    }
    
    enum Output {
        case didEditUser(User)
        case updateSubmittableState(Bool)
        case didInjectRole(RoleProperties)
        case reportError(Error)
    }

    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        let user = dependencyProvider.user
        self.state = State(submittable: true, displayName: user.name, role: user.role, socialInputs: try! dependencyProvider.masterService.blockingMasterData())
    }
    
    func viewDidLoad() {
        injectRole()
    }
    
    func injectRole() {
        outputSubject.send(.didInjectRole(state.role))
    }
    
    func didUpdateInputItems(displayName: String?, biography: String?) {
        state.displayName = displayName
        state.biography = biography
        
        let isSubmittable = (displayName != nil)
        state.submittable = isSubmittable
        outputSubject.send(.updateSubmittableState(isSubmittable))
    }
    
    func didUpdateArtwork(artwork: UIImage?) {
        self.state.profileImage = artwork
    }
    
    func didEditButtonTapped() {
        outputSubject.send(.updateSubmittableState(false))
        if let prifileImage = state.profileImage {
            self.dependencyProvider.s3Client.uploadImage(image: state.profileImage) { [unowned self] result in
                switch result {
                case .success(let imageUrl):
                    editUser(imageUrl: imageUrl)
                case .failure(let error):
                    outputSubject.send(.updateSubmittableState(true))
                    outputSubject.send(.reportError(error))
                }
            }
        } else {
            editUser(imageUrl: dependencyProvider.user.thumbnailURL)
        }
    }
    
    private func editUser(imageUrl: String?) {
        guard let displayName = state.displayName else { return }
        let req = EditUserInfo.Request(
            name: displayName, biography: state.biography, thumbnailURL: imageUrl, role: state.role)
        apiClient.request(EditUserInfo.self, request: req) { [unowned self] result in
            updateState(with: result)
        }
    }
    
    private func updateState(with result: Result<User, Error>) {
        outputSubject.send(.updateSubmittableState(true))
        switch result {
        case .success(let user):
            outputSubject.send(.didEditUser(user))
        case .failure(let error):
            outputSubject.send(.reportError(error))
        }
    }
}
