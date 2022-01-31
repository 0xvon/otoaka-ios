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
        var tip: Product = Product(id: "snack_600", price: 610)
        var message: String? = nil
        var isRealMoney: Bool = true
        var products: [SKProduct] = []
        var theme: String
        var themeItem: [String] = []
        var productItem: [Product] = [
            Product(id: "snack_600", price: 610),
            Product(id: "snack_1000", price: 1100),
            Product(id: "snack_2000", price: 2200),
            Product(id: "snack_10000", price: 10000),
        ]
    }
    
    struct Product {
        let id: String
        let price: Int
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
        let socialInputs = try! dependencyProvider.masterService.blockingMasterData()
        self.state = State(
            type: input,
            theme: socialInputs.socialTipThemes[0],
            themeItem: socialInputs.socialTipThemes
        )
        
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
    
    func didUpdateTheme(theme: String) {
        state.theme = theme
        didInputValue()
    }
    
    func didUpdateMessage(message: String?) {
        state.message = message
        didInputValue()
    }
    
    func didUpdateTip(tip: Int) {
        guard let product = state.productItem.filter({ $0.price == tip }).first else { return }
        state.tip = product
        didInputValue()
    }
    
    func didUpdatePaymentMethod(isRealMoney: Bool) {
        state.isRealMoney = isRealMoney
        didInputValue()
    }
    
    func didInputValue() {
        let submittable = state.message != nil
        outputSubject.send(.updateSubmittableState(.editting(submittable)))
    }
    
    func sendTipButtonTapped() {
        guard let message = state.message else { return }
        let request = SendSocialTip.Request(
            tip: state.tip.price,
            type: state.type,
            theme: state.theme,
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
        SwiftyStoreKit.retrieveProductsInfo(Set(state.productItem.map { $0.id })) { [unowned self] result in
            if let error = result.error {
                outputSubject.send(.reportError(error))
            } else {
                let products = Array(result.retrievedProducts).sorted {
                    $0.price.intValue < $1.price.intValue
                }
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
