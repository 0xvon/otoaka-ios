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
        //        case getContents(String)
        case getLives([Endpoint.LiveFeed])
        case getCharts([ChannelDetail.ChannelItem])
        case getBands([Group])
        case reserveTicket(Endpoint.Ticket)
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let apiClient: APIClient
    let youTubeDataApiClient: YouTubeDataAPIClient
    let outputHandler: (Output) -> Void

    init(apiClient: APIClient, youTubeDataApiClient: YouTubeDataAPIClient, auth: AWSCognitoAuth, outputHander: @escaping (Output) -> Void) {
        self.apiClient = apiClient
        self.youTubeDataApiClient = youTubeDataApiClient
        self.auth = auth
        self.outputHandler = outputHander
    }

    func getContents() {

    }

    func getLives() {
        var uri = GetUpcomingLives.URI()
        uri.page = 1
        uri.per = 1000
        let req = Empty()
        apiClient.request(GetUpcomingLives.self, request: req, uri: uri) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.getLives(res.items))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }

    func getGroups() {
        var uri = GetAllGroups.URI()
        uri.page = 1
        uri.per = 1000
        let req = Empty()
        apiClient.request(GetAllGroups.self, request: req, uri: uri) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.getBands(res.items))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
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
