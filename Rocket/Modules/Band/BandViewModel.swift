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
        
    }
    
    func getCharts() {
        
    }
    
    func getBands() {
        
    }
}
