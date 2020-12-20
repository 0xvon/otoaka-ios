//
//  BandViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import AWSCognitoAuth
import Endpoint
import UIKit

class BandViewModel {
    enum Output {
        case getGroupFeeds([ArtistFeed])
        case refreshGroupFeeds([ArtistFeed])
        case getLives([LiveFeed])
        case refreshLives([LiveFeed])
        case getCharts([ChannelDetail.ChannelItem])
        case getGroups([Group])
        case refreshGroups([Group])
        case reserveTicket(Ticket)
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let apiClient: APIClient
    let youTubeDataApiClient: YouTubeDataAPIClient
    let outputHandler: (Output) -> Void
    
    let groupPaginationRequest: PaginationRequest<GetAllGroups>
    let livePaginationRequest: PaginationRequest<GetUpcomingLives>
    let groupFeedsPaginationRequest: PaginationRequest<GetFollowingGroupFeeds>

    init(apiClient: APIClient, youTubeDataApiClient: YouTubeDataAPIClient, auth: AWSCognitoAuth, outputHander: @escaping (Output) -> Void) {
        self.apiClient = apiClient
        self.groupPaginationRequest = PaginationRequest<GetAllGroups>(apiClient: apiClient)
        self.groupFeedsPaginationRequest = PaginationRequest<GetFollowingGroupFeeds>(apiClient: apiClient)
        self.livePaginationRequest = PaginationRequest<GetUpcomingLives>(apiClient: apiClient)
        self.youTubeDataApiClient = youTubeDataApiClient
        self.auth = auth
        self.outputHandler = outputHander
        
        self.groupPaginationRequest.subscribe { result in
            switch result {
            case .initial(let res):
                self.outputHandler(.refreshGroups(res.items))
            case .next(let res):
                self.outputHandler(.getGroups(res.items))
            case .error(let err):
                self.outputHandler(.error(err))
            }
        }
        
        self.livePaginationRequest.subscribe { result in
            switch result {
            case .initial(let res):
                self.outputHandler(.refreshLives(res.items))
            case .next(let res):
                self.outputHandler(.getLives(res.items))
            case .error(let err):
                self.outputHandler(.error(err))
            }
        }
        
        self.groupFeedsPaginationRequest.subscribe { result in
            switch result {
            case .initial(let res):
                self.outputHandler(.refreshGroupFeeds(res.items))
            case .next(let res):
                self.outputHandler(.getGroupFeeds(res.items))
            case .error(let err):
                self.outputHandler(.error(err))
            }
        }
    }
    
    func getGroups() {
        groupPaginationRequest.next()
    }
    
    func refreshGroups() {
        groupPaginationRequest.next(isNext: false)
    }

    func getGroupFeeds() {
        groupFeedsPaginationRequest.next()
    }
    
    func refreshGroupFeeds() {
        groupFeedsPaginationRequest.next(isNext: false)
    }

    func getLives() {
        livePaginationRequest.next()
    }
    
    func refreshLives() {
        livePaginationRequest.next(isNext: false)
    }

    

    func getCharts() {
//        let request = Empty()
//        var uri = ListChannel.URI()
//        uri.key = youTubeDataApiClient.getApiKey()
//        uri.channelId = "UCxjXU89x6owat9dA8Z-bzdw"
//        uri.part = "snippet"
//        youTubeDataApiClient.request(ListChannel.self, request: request, uri: uri) { result in
//            switch result {
//            case .success(let res):
//                self.outputHandler(.getCharts(res.items))
//            case .failure(let error):
//                self.outputHandler(.error(error))
//            }
//        }
    }

    func reserveTicket(liveId: Live.ID) {
        let request = ReserveTicket.Request(liveId: liveId)
        apiClient.request(ReserveTicket.self, request: request) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.reserveTicket(res))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
}
