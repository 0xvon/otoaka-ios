//
//  PaymentSocialTipViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/12/30.
//

import UIKit
import Endpoint
import Combine
import SwiftyStoreKit
import StoreKit

class PaymentSocialTipViewModel {
    typealias Input = SocialTipType
    struct State {
        var type: SocialTipType
        var tip: Int = 0
        var message: String? = "いつも素敵な音楽をありがとう！"
        var isRealMoney: Bool = true
        var products: [SKProduct] = []
    }
    
    enum PageState {
        case loading
        case editting(Bool)
    }
    
    enum Output {
        case didGetProducts([SKProduct])
        case didGetMyPoint(Int)
        case didSendSocialTip(SocialTip)
        case updateSubmittableState(PageState)
        case reportError(Error)
        case failedToPay(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    var cancellables: Set<AnyCancellable> = []
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    
    private lazy var sendTipAction = Action(SendSocialTip.self, httpClient: apiClient)
    private lazy var getMyPointAction = Action(GetMyPoint.self, httpClient: apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(type: input)
        
        Publishers.MergeMany(
            sendTipAction.elements.map(Output.didSendSocialTip).eraseToAnyPublisher(),
            getMyPointAction.elements.map(Output.didGetMyPoint).eraseToAnyPublisher(),
            sendTipAction.errors.map(Output.reportError).eraseToAnyPublisher(),
            getMyPointAction.errors.map(Output.reportError)
                .eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    func viewDidLoad() {
        getMyPoint()
        getProducts()
    }
    
    func didUpdateMessage(message: String?) {
        state.message = message
        didInputValue()
    }
    
    func didUpdateTip(tip: Int) {
        state.tip = tip
        didInputValue()
    }
    
    func didUpdatePaymentMethod(isRealMoney: Bool) {
        state.isRealMoney = isRealMoney
        didInputValue()
    }
    
    func didInputValue() {
        let submittable = state.message != nil && state.tip > 0
        outputSubject.send(.updateSubmittableState(.editting(submittable)))
    }
    
    func sendTipButtonTapped() {
        guard let message = state.message else { return }
        let request = SendSocialTip.Request(
            tip: state.tip,
            type: state.type,
            message: message,
            isRealMoney: state.isRealMoney
        )
        let uri = SendSocialTip.URI()
        sendTipAction.input((request: request, uri: uri))
    }
    
    func getMyPoint() {
        let uri = GetMyPoint.URI()
        getMyPointAction.input((request: Empty(), uri: uri))
    }
    
    func getProducts() {
        SwiftyStoreKit.retrieveProductsInfo([
            "1000_yen",
            "2000_yen",
        ]) { [unowned self] result in
            if let error = result.error {
                outputSubject.send(.reportError(error))
            } else {
                let products = Array(result.retrievedProducts)
                state.products = products
                outputSubject.send(.didGetProducts(products))
            }
        }
    }
    
    func purchase(_ product: SKProduct) {
        SwiftyStoreKit.purchaseProduct(product, quantity: 1, atomically: true) { [unowned self] result in
            switch result {
            case .success(_):
                sendTipButtonTapped()
            case .error(let error):
                outputSubject.send(.failedToPay(error))
            }
        }
        
    }
}
