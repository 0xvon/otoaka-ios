//
//  InvitationViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/01.
//

import AWSCognitoAuth
import Endpoint
import UIKit
import Combine

final class InvitationViewController: UIViewController, Instantiable {

    typealias Input = Void

    var dependencyProvider: LoggedInDependencyProvider
    let viewModel: InvitationViewModel
    var cancellables: Set<AnyCancellable> = []
    
    var input: Input!
    @IBOutlet weak var invitationView: TextFieldView!
    @IBOutlet weak var registerButtonView: PrimaryButton!
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var createBandButton: UIButton!

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input
        self.viewModel = InvitationViewModel(dependencyProvider: dependencyProvider)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
    }
    
    func bind() {
        registerButtonView.controlEventPublisher(for: .touchUpInside)
            .map { _ in self.invitationView.getText() }
            .sink(receiveValue: viewModel.joinGroup)
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didJoinGroup:
                self.dismiss(animated: true, completion: nil)
                self.navigationController?.popViewController(animated: true)
            case .reportError(let error):
                self.showAlert(title: "エラー", message: String(describing: error))
            }
        }.store(in: &cancellables)
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.title = "招待コード入力"

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
}
