//
//  UrlSchemeActionViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/12/09.
//

import Foundation
import Combine
import Endpoint

final class UrlSchemeActionViewModel {
    enum Output {
        case pushToUserDetail(UserDetailViewController.Input)
        case pushToLiveDetail(LiveDetailViewController.Input)
        case pushToGroupDetail(BandDetailViewController.Input)
        case pushToPostDetail(PostDetailViewController.Input)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var getUserAction = Action(GetUserByUsername.self, httpClient: apiClient)
    private lazy var getGroupAction = Action(GetGroup.self, httpClient: apiClient)
    private lazy var getLiveAction = Action(GetLive.self, httpClient: apiClient)
    private lazy var getPostAction = Action(GetPost.self, httpClient: apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        
        let errors = Publishers.MergeMany(
            getUserAction.errors,
            getGroupAction.errors,
            getLiveAction.errors,
            getPostAction.errors
        )
        .map(Output.reportError)
        .eraseToAnyPublisher()
        
        Publishers.MergeMany(
            getUserAction.elements.map(Output.pushToUserDetail).eraseToAnyPublisher(),
            getGroupAction.elements
                .map { .pushToGroupDetail($0.group) }
                .eraseToAnyPublisher(),
            getLiveAction.elements
                .map { .pushToLiveDetail($0.live) }
                .eraseToAnyPublisher(),
            getPostAction.elements
                .map { .pushToPostDetail($0.post) }
                .eraseToAnyPublisher(),
            errors
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    func action(url: URL) {
        // url like
        // band.rocketfor://ios/users/masatojames
        // or
        // https://rocketfor.band/users/masatojames
        do {
            let uri = try SchemeURI.decode(url: url)
            if let type = Host.withLabel(uri.type) {
                switch type {
                case .users:
                    let username = uri.id
                    getUserByUsername(username: username)
                case .groups:
                    guard let id = Group.ID.init(urlComponent: uri.id) else { return }
                    getGroup(id: id)
                case .lives:
                    guard let id = Live.ID.init(urlComponent: uri.id) else { return }
                    getLive(id: id)
                case .posts:
                    guard let id = Post.ID.init(urlComponent: uri.id) else { return }
                    getPost(id: id)
                }
            }
        } catch let e { outputSubject.send(.reportError(e)) }
    }
    
    enum Host: String, CaseIterable {
        case users, lives, groups, posts
        
        static func withLabel(_ label: String) -> Self? {
            return self.allCases.first(where: { $0.rawValue == label })
        }
    }
    
    public struct SchemeURI: CodableURL {
        @DynamicPath public var type: String
        @DynamicPath public var id: String
        public init() {}
    }
    
    private func getUserByUsername(username: String) {
        var uri = GetUserByUsername.URI()
        uri.username = username
        getUserAction.input((request: Empty(), uri: uri))
    }
    
    private func getGroup(id: Group.ID) {
        var uri = GetGroup.URI()
        uri.groupId = id
        getGroupAction.input((request: Empty(), uri: uri))
    }
    
    private func getLive(id: Live.ID) {
        var uri = GetLive.URI()
        uri.liveId = id
        getLiveAction.input((request: Empty(), uri: uri))
    }
    
    private func getPost(id: Post.ID) {
        var uri = GetPost.URI()
        uri.postId = id
        getPostAction.input((request: Empty(), uri: uri))
    }
    
}
