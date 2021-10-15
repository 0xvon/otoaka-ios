//
//  PostDetailViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/08/22.
//

import UIKit
import Endpoint
import Combine

class PostDetailViewModel {
    typealias Input = Post
    
    struct State {
        var postId: Post.ID
        var post: PostSummary?
    }
    
    enum Output {
        case didRefreshPost(PostSummary)
        case error(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    var cancellables: Set<AnyCancellable> = []

    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    
    private lazy var getPostAction = Action(GetPost.self, httpClient: apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(postId: input.id)
        
        let errors = Publishers.MergeMany(
            getPostAction.errors
        )
        
        Publishers.MergeMany(
            getPostAction.elements.map(Output.didRefreshPost).eraseToAnyPublisher(),
            errors.map(Output.error).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        getPostAction.elements
            .sink(receiveValue: { [unowned self] post in
                state.post = post
            })
            .store(in: &cancellables)
    }
    
    func inject(_ input: Input) {
        refresh()
    }
    
    func refresh() {
        let request = Empty()
        var uri = GetPost.URI()
        uri.postId = state.postId
        getPostAction.input((request: request, uri: uri))
    }
}
