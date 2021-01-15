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
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var reserveTicketAction = Action(ReserveTicket.self, httpClient: self.apiClient)
    private lazy var refundTicketAction = Action(RefundTicket.self, httpClient: self.apiClient)

    init(live: Live, apiClient: APIClient) {
        self.apiClient = apiClient
        self.state = State(live: live)
        
        let errors = Publishers.MergeMany(
            reserveTicketAction.errors,
            refundTicketAction.errors
        )
        
        Publishers.MergeMany(
            reserveTicketAction.elements.map { ticket in
                .updateHasTicket("予約済")
            }.eraseToAnyPublisher(),
            refundTicketAction.elements.map { ticket in
                .updateHasTicket("￥\(ticket.live.price)")
            }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        reserveTicketAction.elements
            .sink(receiveValue: { [unowned self] ticket in
                guard let count = state.participantsCount else {
                    preconditionFailure("Button shouldn't be enabled before got followersCount")
                }
                state.ticket = ticket
                let newCount = count + 1
                state.participantsCount = newCount
                outputSubject.send(.updateParticipantsCount(newCount))
                outputSubject.send(.updateIsButtonEnabled(true))
            })
            .store(in: &cancellables)
        
        refundTicketAction.elements
            .sink(receiveValue: { [unowned self] ticket in
                guard let count = state.participantsCount else {
                    preconditionFailure("Button shouldn't be enabled before got followersCount")
                }
                state.ticket = ticket
                let newCount = count - 1
                state.participantsCount = newCount
                outputSubject.send(.updateParticipantsCount(newCount))
                outputSubject.send(.updateIsButtonEnabled(true))
            })
            .store(in: &cancellables)
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
            refundTicketAction.input((request: req, uri: RefundTicket.URI()))
        } else {
            let req = ReserveTicket.Request(liveId: state.live.id)
            reserveTicketAction.input((request: req, uri: ReserveTicket.URI()))
        }
    }
}
