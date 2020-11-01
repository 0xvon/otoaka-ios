//
//  InvitationViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/01.
//

import UIKit
import Endpoint
import AWSCognitoAuth

final class InvitationViewController: UIViewController, Instantiable {
    
    typealias Input = (
        session: AWSCognitoAuthUserSession,
        user: User
    )
    var dependencyProvider: DependencyProvider
    var input: Input!
    @IBOutlet weak var invitationView: TextFieldView!
    @IBOutlet weak var registerButtonView: Button!
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var createBandButton: UIButton!
    
    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        self.view.backgroundColor = style.color.background.get()
        
        switch input.user.role {
        case .fan(_):
            orLabel.isHidden = true
            createBandButton.isHidden = true
        case .artist(_):
            orLabel.font = style.font.small.get()
            orLabel.textColor = style.color.main.get()
            createBandButton.setTitleColor(style.color.sub.get(), for: .normal)
            createBandButton.addTarget(self, action: #selector(createBand(_:)), for: .touchUpInside)
        }
        
        invitationView.inject(input: "招待コード")
        registerButtonView.inject(input: (text: "登録", image: nil))
        registerButtonView.listen {
            self.register()
        }
    }
    
    @objc private func createBand(_ sender: Any) {
        print("create band")
    }
    
    private func register() {
        print("register")
    }
}
