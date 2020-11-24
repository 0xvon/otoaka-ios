//
//  BandViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import UIKit
import AWSCognitoAuth
import Endpoint

class BandViewModel {
    enum Output {
//        case getContents(String)
        case getLives([Endpoint.Live])
//        case getCharts(String)
        case getBands([Group])
        case reserveTicket(Endpoint.Ticket)
        case error(Error)
    }
    
    let auth: AWSCognitoAuth
    let apiClient: APIClient
    let outputHandler: (Output) -> Void
    
    init(apiClient: APIClient, auth: AWSCognitoAuth, outputHander: @escaping (Output) -> Void) {
        self.apiClient = apiClient
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
        
        do {
            try apiClient.request(GetUpcomingLives.self, request: req, uri: uri) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.getLives(res.items))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        } catch let error {
            self.outputHandler(.error(error))
        }
    }
    
    func getGroups() {
        var uri = GetAllGroups.URI()
        uri.page = 1
        uri.per = 1000
        let req = Empty()
        
        do {
            try apiClient.request(GetAllGroups.self, request: req, uri: uri) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.getBands(res.items))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        } catch let error {
            self.outputHandler(.error(error))
        }
    }
    
    func getCharts() {
        
    }
    
    func reserveTicket(liveId: Live.ID) {
        let request = ReserveTicket.Request(liveId: liveId)
        
        do {
            try apiClient.request(ReserveTicket.self, request: request) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.reserveTicket(res))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        } catch let error {
            self.outputHandler(.error(error))
        }
    }
}
