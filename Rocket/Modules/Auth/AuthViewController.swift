//
//  AuthViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/17.
//

import Foundation
import UIKit

class AuthViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    
    var viewModel: AuthViewModel! = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = AuthViewModel(outputHander: {output in
            print("hello")
            switch output {
            case .id(let endpoint):
                print(endpoint)
                self.label.text = "hello"
            }
        })
    }
}
