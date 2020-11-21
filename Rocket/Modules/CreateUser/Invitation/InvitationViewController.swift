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
        idToken: String,
        user: User
    )
    
    lazy var viewModel = InvitationViewModel(
        idToken: self.input.idToken,
        apiEndpoint: dependencyProvider.apiEndpoint,
        s3Bucket: dependencyProvider.s3Bucket,
        outputHander: { output in
            switch output {
            case .joinGroup:
                DispatchQueue.main.async {
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                    let vc = HomeViewController(dependencyProvider: self.dependencyProvider, input: self.input)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            case .error(let error):
                print(error)
            }
        }
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
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
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
        
        let skipButton = UIButton()
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.setTitle("skip", for: .normal)
        skipButton.titleLabel?.font = style.font.regular.get()
        skipButton.setTitleColor(style.color.main.get(), for: .normal)
        skipButton.addTarget(self, action: #selector(skip(_:)), for: .touchUpInside)
        self.view.addSubview(skipButton)
        
        let constraints = [
            skipButton.bottomAnchor.constraint(equalTo: self.invitationView.topAnchor, constant: -16),
            skipButton.rightAnchor.constraint(equalTo: self.invitationView.rightAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc private func createBand(_ sender: Any) {
        let vc = CreateBandViewController(dependencyProvider: self.dependencyProvider, input: self.input)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func skip(_ sender: Any) {
        let vc = HomeViewController(dependencyProvider: self.dependencyProvider, input: (idToken: self.input.idToken, user: self.input.user))
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func register() {
        let invitationCode = invitationView.getText()
        
        switch input.user.role {
        case .artist(_):
            viewModel.joinGroup(invitationCode: invitationCode)
        case .fan(_):
            viewModel.enterInvitationCode(invitationCode: invitationCode)
        }
    }
}
