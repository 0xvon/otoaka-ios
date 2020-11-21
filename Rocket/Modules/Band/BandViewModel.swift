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
//        case getLives(String)
//        case getCharts(String)
//        case getBands(String)
        case registerDeviceToken
        case requestRemortNotification
    }
    
    let auth: AWSCognitoAuth
    let apiClient: APIClient
    let outputHandler: (Output) -> Void
    
    init(apiClient: APIClient, auth: AWSCognitoAuth, outputHander: @escaping (Output) -> Void) {
        self.apiClient = apiClient
        self.auth = auth
        self.outputHandler = outputHander
    }
    
    func requestRemortNotification() {
        self.outputHandler(.requestRemortNotification)
    }
    
    func registerPushNotification(deviceToken: String) {
        let req = RegisterDeviceToken.Request(deviceToken: deviceToken)

        // FIXME
        try! apiClient.request(RegisterDeviceToken.self, request: req) { result in
            switch result {
            case .success:
                self.outputHandler(.registerDeviceToken)
            case .failure(let error):
                // FIXME
                fatalError(String(describing: error))
            }
        }
    }
}
