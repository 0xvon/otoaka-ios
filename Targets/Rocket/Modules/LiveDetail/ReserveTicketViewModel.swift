//
//  TicketViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/30.
//

import Combine
import Endpoint
import Foundation

class ReserveTicketViewModel {
    struct State {
        let live: Live
        var hasTicket: Bool {
            guard let ticket = ticket else { return false }
            return ticket.status == .reserved
        }
        var ticket: Ticket?
        var participantsCount: Int?
    }

    enum Output {
        case updateIsButtonEnabled(Bool)
        case updateHasTicket(String)
        case updateParticipantsCount(Int)
        case reportError(Error)
    }

    private var state: State

    private let apiClient: APIClient
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    init(live: Live, apiClient: APIClient) {
        self.apiClient = apiClient
        self.state = State(live: live)
    }

    func viewDidLoad() {
        outputSubject.send(.updateIsButtonEnabled(false))
    }

    func didGetLiveDetail(ticket: Ticket?, participantsCount: Int) {
        state.ticket = ticket
        state.participantsCount = participantsCount
        outputSubject.send(.updateIsButtonEnabled(true))
        outputSubject.send(.updateHasTicket(state.hasTicket ? "予約済" : "￥\(state.live.price)"))
        outputSubject.send(.updateParticipantsCount(participantsCount))
    }

    func didButtonTapped() {
        let hasTicket = state.hasTicket
        outputSubject.send(.updateIsButtonEnabled(false))
        if hasTicket {
            guard let ticket = state.ticket else {
                preconditionFailure("Button shouldn't be enabled before got ticket")
            }
            let req = RefundTicket.Request(ticketId: ticket.id)
            apiClient.request(RefundTicket.self, request: req) { [unowned self] in
                self.updateState(with: $0.map { _ in nil })
            }
        } else {
            let req = ReserveTicket.Request(liveId: state.live.id)
            apiClient.request(ReserveTicket.self, request: req) { [unowned self] in
                self.updateState(with: $0.map { $0 })
            }
        }
    }

    private func updateState(with result: Result<Ticket?, Error>) {
        guard let count = state.participantsCount else {
            preconditionFailure("Button shouldn't be enabled before got followersCount")
        }
        outputSubject.send(.updateIsButtonEnabled(true))
        switch result {
        case .success(let ticket):
            let didReserve = ticket != nil
            state.ticket = ticket
            let newCount = count + (didReserve ? 1 : -1)
            state.participantsCount = newCount
            outputSubject.send(.updateParticipantsCount(newCount))
            outputSubject.send(.updateHasTicket(didReserve ? "予約済" : "￥\(state.live.price)"))
        case .failure(let error):
            outputSubject.send(.reportError(error))
        }
    }
}
