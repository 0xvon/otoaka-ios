//
//  InvitationViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/01.
//

import AWSCognitoAuth
import Endpoint
import UIKit

final class InvitationViewController: UIViewController, Instantiable {

    typealias Input = Void

    lazy var viewModel = InvitationViewModel(
        apiClient: dependencyProvider.apiClient,
        s3Client: dependencyProvider.s3Client,
        outputHander: { output in
            switch output {
            case .joinGroup:
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            case .error(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: error.localizedDescription)
                }
            }
        }
    )

    var dependencyProvider: LoggedInDependencyProvider
    var input: Input!
    @IBOutlet weak var invitationView: TextFieldView!
    @IBOutlet weak var registerButtonView: PrimaryButton!
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var createBandButton: UIButton!

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
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
        self.view.backgroundColor = Brand.color(for: .background(.primary))

        switch dependencyProvider.user.role {
        case .fan(_):
            orLabel.isHidden = true
            createBandButton.isHidden = true
        case .artist(_):
            orLabel.font = Brand.font(for: .small)
            orLabel.textColor = Brand.color(for: .text(.primary))
            createBandButton.setTitleColor(Brand.color(for: .text(.toggle)), for: .normal)
            createBandButton.addTarget(self, action: #selector(createBand(_:)), for: .touchUpInside)
        }

        invitationView.inject(input: (section: "招待コード", text: nil, maxLength: 60))
        registerButtonView.setTitle("登録", for: .normal)
        registerButtonView.listen {
            self.register()
        }

        let skipButton = UIButton()
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.setTitle("skip", for: .normal)
        skipButton.titleLabel?.font = Brand.font(for: .medium)
        skipButton.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        skipButton.addTarget(self, action: #selector(skip(_:)), for: .touchUpInside)
        self.view.addSubview(skipButton)

        let constraints = [
            skipButton.bottomAnchor.constraint(
                equalTo: self.invitationView.topAnchor, constant: -16),
            skipButton.rightAnchor.constraint(equalTo: self.invitationView.rightAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    @objc private func createBand(_ sender: Any) {
        let vc = CreateBandViewController(
            dependencyProvider: self.dependencyProvider, input: self.input)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func skip(_ sender: Any) {
        self.dismiss(animated: true)
    }

    private func register() {
        let invitationCode = invitationView.getText()

        switch dependencyProvider.user.role {
        case .artist(_):
            viewModel.joinGroup(invitationCode: invitationCode)
        case .fan(_):
            viewModel.enterInvitationCode(invitationCode: invitationCode)
        }
    }
}
