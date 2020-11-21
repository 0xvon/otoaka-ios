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
    let apiEndpoint: String
    let outputHandler: (Output) -> Void
    let idToken: String
    
    init(idToken: String, auth: AWSCognitoAuth, apiEndpoint: String,  outputHander: @escaping (Output) -> Void) {
        self.idToken = idToken
        self.auth = auth
        self.apiEndpoint = apiEndpoint
        self.outputHandler = outputHander
    }
    
    func requestRemortNotification() {
        self.outputHandler(.requestRemortNotification)
    }
    
    func registerPushNotification(deviceToken: String) {
        let registerDeviceTokenAPIClient = APIClient<RegisterDeviceToken>(baseUrl: self.apiEndpoint, idToken: self.idToken)
        let req: RegisterDeviceToken.Request = RegisterDeviceToken.Request(deviceToken: deviceToken)
        
        registerDeviceTokenAPIClient.request(req: req) { res in
            self.outputHandler(.registerIdToken)
        }
    }
}
