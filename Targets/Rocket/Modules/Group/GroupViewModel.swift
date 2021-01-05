//
//  GroupViewModel.swift
//  Rocket
//
//  Created by kateinoigakukun on 2021/01/05.
//

import Foundation
import Combine
import Endpoint

final class GroupViewModel {

    enum Input {
        case updateSearchQuery(String?)
    }
    enum Output {
        case updateSearchResult(SearchResultViewController.Input)
        case reloadData
        case isRefreshing(Bool)
    }
    enum Scope: Int, CaseIterable {
        case all, following
        var description: String {
            switch self {
            case .all: return "すべて"
            case .following: return "フォロー中"
            }
        }
    }

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never>
    private var _groups = CurrentValueSubject<[Group], Never>([])
    var groups: [Group] { _groups.value }
    var scopes: [Scope] { Scope.allCases }

    let updateSearchQuery = PassthroughSubject<String?, Never>()
    let refresh = PassthroughSubject<Void, Never>()
    let updateScope = PassthroughSubject<Int, Never>()
    let willDisplayCell = PassthroughSubject<IndexPath, Never>()

    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: LoggedInDependencyProvider) {
        let getAllPagination = PaginationRequest<Endpoint.GetAllGroups>(apiClient: dependencyProvider.apiClient)
        let getFollowingPagination = PaginationRequest<Endpoint.FollowingGroups>(
            apiClient: dependencyProvider.apiClient,
            uri: {
                var uri = FollowingGroups.URI()
                uri.id = dependencyProvider.user.id
                return uri
            }()
        )

        let updateSearchResult = updateSearchQuery.map { queryText -> Output in
            guard let query = queryText, !query.isEmpty else {
                return .updateSearchResult(.none)
            }
            return .updateSearchResult(.group(query))
        }
        .eraseToAnyPublisher()

        let groups = getAllPagination.items()
            .merge(with: getFollowingPagination.items())
            .multicast(subject: self._groups)

        let isRefreshing = getAllPagination.isRefreshing
            .merge(with: getFollowingPagination.isRefreshing)
            .map(Output.isRefreshing)

        let reloadData = groups.map { _ in Output.reloadData }

        let scope = updateScope.map { Scope.allCases[$0] }.prepend(.all)
        

        refresh.prepend(()).combineLatest(scope) { $1 }
            .sink { scope in
                switch scope {
                case .all:
                    getAllPagination.refresh()
                case .following:
                    getFollowingPagination.refresh()
                }
            }.store(in: &cancellables)

        willDisplayCell.combineLatest(groups)
            .filter { indexPath, groups in indexPath.row + 25 > groups.count }
            .combineLatest(scope, { $1 })
            .sink { scope in
                switch scope {
                case .all:
                    getAllPagination.next()
                case .following:
                    getFollowingPagination.next()
                }
            }.store(in: &cancellables)

        groups.connect().store(in: &cancellables)
        self.output = updateSearchResult.merge(with: reloadData, isRefreshing).eraseToAnyPublisher()
    }
}
