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
        var instagramUrl: URL?
        var twitterUrl: URL?
        let socialInputs: SocialInputs
    }
    
    enum PageState {
        case loading
        case editting(Bool)
    }
    
    enum Output {
        case didEditUser(User)
        case didGetUserInfo(User)
        case updateSubmittableState(PageState)
//        case didInjectRole(RoleProperties)
        case reportError(Error)
    }

    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var getUserInfoAction = Action(GetUserInfo.self, httpClient: self.apiClient)
    private lazy var editUserAction = Action(EditUserInfo.self, httpClient: self.apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(role: dependencyProvider.user.role, socialInputs: try! dependencyProvider.masterService.blockingMasterData())
        
        let errors = Publishers.MergeMany(
            getUserInfoAction.errors,
            editUserAction.errors
        )
        
        Publishers.MergeMany(
            getUserInfoAction.elements.map(Output.didGetUserInfo).eraseToAnyPublisher(),
            editUserAction.elements.map(Output.didEditUser).eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        editUserAction.elements
            .sink(receiveValue: { [unowned self] _ in
                outputSubject.send(.updateSubmittableState(.editting(true)))
            })
            .store(in: &cancellables)
    }
    
    func viewDidLoad() {
//        injectRole()
        getUserInfo()
    }
    
//    func injectRole() {
//        outputSubject.send(.didInjectRole(state.role))
//    }
    
    func getUserInfo() {
        getUserInfoAction.input((request: Empty(), uri: GetUserInfo.URI()))
    }
    
    func didUpdateInputItems(displayName: String?, biography: String?, twitterUrl: String?, instagramUrl: String?) {
        state.displayName = displayName
        state.biography = biography
        state.twitterUrl = validateSnsUrl(baseUrl: "https://twitter.com/", text: twitterUrl)
        state.instagramUrl = validateSnsUrl(baseUrl: "https://instagram.com/", text: instagramUrl)
        
        let isSubmittable = (displayName != nil)
        outputSubject.send(.updateSubmittableState(.editting(isSubmittable)))
    }
    
    func validateSnsUrl(baseUrl: String, text: String?) -> URL? {
        guard let text = text, text.contains(baseUrl), text != baseUrl else { return nil }
        return URL(string: text)
    }
    
    func didUpdateArtwork(artwork: UIImage?) {
        self.state.profileImage = artwork
    }
    
    func didEditButtonTapped() {
        outputSubject.send(.updateSubmittableState(.loading))
        if let prifileImage = state.profileImage {
            self.dependencyProvider.s3Client.uploadImage(image: prifileImage) { [weak self] result in
                switch result {
                case .success(let imageUrl):
                    self?.editUser(imageUrl: imageUrl)
                case .failure(let error):
                    self?.outputSubject.send(.updateSubmittableState(.editting(true)))
                    self?.outputSubject.send(.reportError(error))
                }
            }
        } else {
            editUser(imageUrl: dependencyProvider.user.thumbnailURL)
        }
    }
    
    private func editUser(imageUrl: String?) {
        guard let displayName = state.displayName else { return }
        let req = EditUserInfo.Request(
            name: displayName, biography: state.biography, thumbnailURL: imageUrl, role: state.role, twitterUrl: state.twitterUrl, instagramUrl: state.instagramUrl)
        editUserAction.input((request: req, uri: EditUserInfo.URI()))
    }
}
