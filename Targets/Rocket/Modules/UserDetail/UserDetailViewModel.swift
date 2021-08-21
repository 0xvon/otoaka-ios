//
//  UserDetailViewModel.swift
//  ImagePipeline
//
//  Created by Masato TSUTSUMI on 2021/02/28.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIComponent
import ImageViewer

class UserDetailViewModel {
    enum DisplayType {
        case account
        case user
    }
    enum SummaryRow {
        case post
        case group
        case live
    }
    struct State {
        var user: User
        var selfUser: User
        var userDetail: UserDetail?
        
        var displayType: DisplayType {
            return _displayType(isMe: user.id == selfUser.id)
        }
        
        fileprivate func _displayType(isMe: Bool) -> DisplayType {
            return isMe ? .account : .user
        }
    }
    
    enum Output {
        case didRefreshUserDetail(UserDetail)
        case followButtontapped
        case editProfileButtonTapped
        
        case openImage(GalleryItemsDataSource)
        case pushToUserList(UserListViewController.Input)
        case openURLInBrowser(URL)
        case pushToMessageRoom(MessageRoom)
        
        case reportError(Error)
    }
    
    var dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var getUserDetailAction = Action(GetUserDetail.self, httpClient: apiClient)
    private lazy var createMessageRoomAction = Action(CreateMessageRoom.self, httpClient: apiClient)
    
    init(dependencyProvider: LoggedInDependencyProvider, user: User) {
        self.dependencyProvider = dependencyProvider
        self.state = State(user: user, selfUser: dependencyProvider.user)
        
        let errors = Publishers.MergeMany(
            getUserDetailAction.errors,
            createMessageRoomAction.errors
        )
        
        Publishers.MergeMany(
            getUserDetailAction.elements.map(Output.didRefreshUserDetail).eraseToAnyPublisher(),
            createMessageRoomAction.elements.map(Output.pushToMessageRoom).eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        getUserDetailAction.elements
            .sink(receiveValue: { [unowned self] userDetail in
                state.userDetail = userDetail
            })
            .store(in: &cancellables)
    }
    
    func viewDidLoad() {
        refresh()
    }
    
    func refresh() {
        getUserDetail()
    }
    
    func headerEvent(output: UserDetailHeaderView.Output) {
        switch output {
        case .followersButtonTapped:
            outputSubject.send(.pushToUserList(.userFollowers(state.user.id)))
        case .followingUsersButtonTapped:
            outputSubject.send(.pushToUserList(.followingUsers(state.user.id)))
        case .followButtonTapped:
            outputSubject.send(.followButtontapped)
        case .editButtonTapped:
            outputSubject.send(.editProfileButtonTapped)
        }
    }
    
    private func getUserDetail() {
        var uri = GetUserDetail.URI()
        uri.userId = state.user.id
        getUserDetailAction.input((request: Empty(), uri: uri))
    }
    
    func createMessageRoom(partner: User) {
        let request = CreateMessageRoom.Request(members: [partner.id], name: partner.name)
        let uri = CreateMessageRoom.URI()
        createMessageRoomAction.input((request: request, uri: uri))
    }
    
    deinit {
        print("UserViewModel.deinit")
    }
}
