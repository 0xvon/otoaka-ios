//
//  AuthViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/17.
//

import Foundation
import Endpoint

class AuthViewModel {
    enum Output {
        case id(Endpoint)
        case login
        case signin
    }
    
    let outputHandler: (Output) -> Void
    init(outputHander: @escaping (Output) -> Void) {
        self.outputHandler = outputHander
    }
    
    func fetchAccount() {
        let endpoint: Endpoint = Endpoint()
        outputHandler(.id(endpoint))
    }
    
    func login() {
        
    }
    
    func signin() {
        
    }
}
