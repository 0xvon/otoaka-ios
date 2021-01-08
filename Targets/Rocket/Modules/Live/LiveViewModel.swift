//
//  LiveViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import Foundation
import Combine
import Endpoint

final class LiveViewModel {
    
    enum Input {
        case UpdateSearchQuery(String?)
    }
    
    enum Output {
        case updateSearchResult(SearchResultViewController.Input)
        case reloadData
        case isRefreshing(Bool)
        case reportError(Error)
    }
    
    enum Scope: Int, CaseIterable {
        case all, reserved
        var description: String {
            switch self {
            case .all: return "すべて"
            case .reserved: return "予約済み"
            }
        }
    }
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never>
    private var _lives = CurrentValueSubject<[Live], Never>([])
    var lives: [Live] { _lives.value }
    var scopes: [Scope] { Scope.allCases }
    
    let updateSearchQuery = PassthroughSubject<String?, Never>()
    let refresh = PassthroughSubject<Void, Never>()
    let updateScope = PassthroughSubject<Int, Never>()
    let willDisplayCell = PassthroughSubject<IndexPath, Never>()
    
    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: LoggedInDependencyProvider) {
        let getAllPagination = PaginationRequest<Endpoint.GetUpcomingLives>(apiClient: dependencyProvider.apiClient)
        let getReservedPagination = PaginationRequest<Endpoint.GetMyTickets>(apiClient: dependencyProvider.apiClient)
        
        let updateSearchResult = updateSearchQuery.map { queryText -> Output in
            guard let query = queryText, !query.isEmpty else {
                return .updateSearchResult(.none)
            }
            return .updateSearchResult(.live(query))
        }
        .eraseToAnyPublisher()
        
        let lives = getAllPagination.items().map { $0.map { $0.live } }
            .merge(with: getReservedPagination.items().map { $0.filter { $0.status == .reserved }.map { $0.live } })
            .multicast(subject: self._lives)
        
        let isRefreshing = getAllPagination.isRefreshing
            .merge(with: getReservedPagination.isRefreshing)
            .map(Output.isRefreshing)
        
        let reloadData = lives.map { _ in Output.reloadData }
        
        let scope = updateScope.map { Scope.allCases[$0] }.prepend(.all)
        
        refresh.prepend(()).combineLatest(scope) { $1 }
            .sink { scope in
                switch scope {
                case .all:
                    getAllPagination.refresh()
                case .reserved:
                    getReservedPagination.refresh()
                }
            }.store(in: &cancellables)
        
        willDisplayCell.combineLatest(lives)
            .filter { indexPath, lives in indexPath.row + 25 > lives.count }
            .combineLatest(scope, { $1 })
            .sink { scope in
                switch scope {
                case .all:
                    getAllPagination.next()
                case .reserved:
                    getReservedPagination.next()
                }
            }.store(in: &cancellables)
        
        lives.connect().store(in: &cancellables)
        self.output = updateSearchResult.merge(with: reloadData, isRefreshing).eraseToAnyPublisher()
    }
}
