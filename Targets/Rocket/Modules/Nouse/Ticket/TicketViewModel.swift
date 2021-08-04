//
//  TicketViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import UIKit
import Endpoint

class TicketViewModel {
    enum Output {
        case getMyTickets([LiveFeed])
        case refreshMyTickets([LiveFeed])
        case error(Error)
    }

    let apiClient: APIClient
    let user: User
    let outputHandler: (Output) -> Void
    
    let ticketsPaginationRequest: PaginationRequest<GetMyTickets>

    init(
        apiClient: APIClient, user: User,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.user = user
        self.outputHandler = outputHander
        self.ticketsPaginationRequest = PaginationRequest<GetMyTickets>(apiClient: apiClient)
        
        self.ticketsPaginationRequest.subscribe { result in
            switch result {
            case .initial(let res):
                self.outputHandler(.refreshMyTickets(res.items))
            case .next(let res):
                self.outputHandler(.getMyTickets(res.items))
            case .error(let err):
                self.outputHandler(.error(err))
            }
        }
    }
    
    func getMyTickets() {
        ticketsPaginationRequest.next()
    }
    
    func refreshMyTickets() {
        ticketsPaginationRequest.refresh()
    }
}
