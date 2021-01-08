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
        var displayName: String?
        var biography: String?
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
        case didEditUser(User)
        case didGetUserInfo(User)
        case updateSubmittableState(PageState)
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
        self.state = State(role: dependencyProvider.user.role, socialInputs: try! dependencyProvider.masterService.blockingMasterData())
    }
    
    func viewDidLoad() {
        injectRole()
        getUserInfo()
    }
    
    func injectRole() {
        outputSubject.send(.didInjectRole(state.role))
    }
    
    func getUserInfo() {
        apiClient.request(GetUserInfo.self) { [unowned self] result in
            switch result {
            case .success(let user):
                outputSubject.send(.didGetUserInfo(user))
            case .failure(let error):
                outputSubject.send(.reportError(error))
            }
        }
    }
    
    func didUpdateInputItems(displayName: String?, biography: String?) {
        state.displayName = displayName
        state.biography = biography
        
        let isSubmittable = (displayName != nil)
        outputSubject.send(.updateSubmittableState(.editting(isSubmittable)))
    }
    
    func didUpdateArtwork(artwork: UIImage?) {
        self.state.profileImage = artwork
    }
    
    func didEditButtonTapped() {
        outputSubject.send(.updateSubmittableState(.loading))
        if let prifileImage = state.profileImage {
            self.dependencyProvider.s3Client.uploadImage(image: prifileImage) { [unowned self] result in
                switch result {
                case .success(let imageUrl):
                    editUser(imageUrl: imageUrl)
                case .failure(let error):
                    outputSubject.send(.updateSubmittableState(.completed))
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
        outputSubject.send(.updateSubmittableState(.completed))
        switch result {
        case .success(let user):
            outputSubject.send(.didEditUser(user))
        case .failure(let error):
            outputSubject.send(.reportError(error))
        }
    }
}
