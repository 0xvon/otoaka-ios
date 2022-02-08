//
//  RegistrationViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/17.
//

import Auth0
import SafariServices
import UIKit
import Combine

final class RegistrationViewController: UIViewController, Instantiable {
    typealias SignedUpHandler = () -> Void
    typealias Input = SignedUpHandler

    lazy var viewModel = RegistrationViewModel(
        auth: dependencyProvider.auth,
        apiClient: dependencyProvider.apiClient
    )

    @IBOutlet weak var backgroundImageView: UIImageView! {
        didSet {
            backgroundImageView.layer.opacity = 0.8
            backgroundImageView.image = UIImage(named: "dpf")
            backgroundImageView.contentMode = .scaleAspectFill
        }
    }
    private lazy var appLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "AppLogo")
        return imageView
    }()
    private lazy var descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textColor = Brand.color(for: .text(.primary))
        textView.font = Brand.font(for: .mediumStrong)
        textView.text = "あなたのライブ体験を最大化するアプリ"
        textView.backgroundColor = .clear
        textView.textAlignment = .center
        return textView
    }()
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        
        stackView.addArrangedSubview(googleButtonView)
        NSLayoutConstraint.activate([
            googleButtonView.heightAnchor.constraint(equalToConstant: 54),
        ])
        stackView.addArrangedSubview(fbButtonView)
        NSLayoutConstraint.activate([
            fbButtonView.heightAnchor.constraint(equalToConstant: 54),
        ])
        stackView.addArrangedSubview(twitterButtonView)
        NSLayoutConstraint.activate([
            twitterButtonView.heightAnchor.constraint(equalToConstant: 54),
        ])
        stackView.addArrangedSubview(appleButtonView)
        NSLayoutConstraint.activate([
            appleButtonView.heightAnchor.constraint(equalToConstant: 54),
        ])
        stackView.addArrangedSubview(termsOfServiceButton)
        NSLayoutConstraint.activate([
            termsOfServiceButton.heightAnchor.constraint(equalToConstant: 20),
        ])
        return stackView
    }()
    private lazy var googleButtonView: Button = {
        let button = Button(text: "")
        button.layer.cornerRadius = 27
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Googleでログイン", for: .normal)
        button.background(Brand.color(for: .brand(.google)))
        return button
    }()
    private lazy var fbButtonView: Button = {
        let button = Button(text: "")
        button.layer.cornerRadius = 27
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Facebookでログイン", for: .normal)
        button.background(Brand.color(for: .brand(.facebook)))
        return button
    }()
    private lazy var twitterButtonView: Button = {
        let button = Button(text: "")
        button.layer.cornerRadius = 27
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Twitterでログイン", for: .normal)
        button.background(Brand.color(for: .brand(.twitter)))
        return button
    }()
    private lazy var appleButtonView: Button = {
        let button = Button(text: "")
        button.layer.cornerRadius = 27
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Appleでログイン", for: .normal)
        button.setTitleColor(Brand.color(for: .brand(.apple)), for: .normal)
        button.setImage(UIImage(systemName: "applelogo")?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        return button
    }()
    private lazy var termsOfServiceButton: UIButton = {
        let button = UIButton()
        button.setTitle("利用規約", for: .normal)
        button.titleLabel?.font = Brand.font(for: .mediumStrong)
        button.setTitleColor(Brand.color(for: .brand(.light)), for: .normal)
        button.addTarget(self, action: #selector(tosTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var dependencyProvider: DependencyProvider
    var signedUpHandler: SignedUpHandler
    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: DependencyProvider, input: @escaping Input) {
        self.dependencyProvider = dependencyProvider
        self.signedUpHandler = input
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        setup()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
        
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.barTintColor = .clear
        self.navigationController?.navigationBar.backgroundColor = .clear
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func bind() {
        googleButtonView.listen { [unowned self] in
            loginButtonTapped("google-oauth2")
        }
        
        fbButtonView.listen { [unowned self] in
            loginButtonTapped("facebook")
        }
        
        twitterButtonView.listen { [unowned self] in
            loginButtonTapped("twitter")
        }
        
        appleButtonView.listen { [unowned self] in
            loginButtonTapped("apple")
        }

        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .signupStatus(let isSignedup):
                if isSignedup {
                    self.signedUpHandler()
                    self.dismiss(animated: true)
                } else {
                    viewModel.signup()
                }
            case .error(let error):
                print(error)
                self.showAlert()
            case .didCreateUser(_):
                self.dismiss(animated: true, completion: nil)
            }
        }.store(in: &cancellables)
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        
        view.addSubview(appLogoImageView)
        NSLayoutConstraint.activate([
            appLogoImageView.widthAnchor.constraint(equalToConstant: 300),
            appLogoImageView.heightAnchor.constraint(equalToConstant: 40),
            appLogoImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 64),
            appLogoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        view.addSubview(descriptionTextView)
        NSLayoutConstraint.activate([
            descriptionTextView.topAnchor.constraint(equalTo: appLogoImageView.bottomAnchor, constant: 16),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 60),
            descriptionTextView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
            descriptionTextView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
        ])
        
        view.addSubview(buttonStackView)
        NSLayoutConstraint.activate([
            buttonStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -64),
            buttonStackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            buttonStackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
        ])
    }
    
    @objc private func loginButtonTapped(_ connection: String) {
        dependencyProvider.auth
            // allowed values: apple, twitter, facebook, google-oauth2
            .connection(connection)
            .start { [unowned self] result in
                switch result {
                case .success(let credentials):
                    _ = dependencyProvider.credentialsManager.store(credentials: credentials)
                    viewModel.getSignupStatus()
                case .failure(let error):
                    print(String(describing: error))
                }
            }
    }
    
    @objc private func tosTapped() {
        guard let url = URL(string: "https://www.notion.so/masatojames/57b1f47c538443249baf1db83abdc462") else { return }
        let safari = SFSafariViewController(url: url)
        safari.dismissButtonStyle = .close
        present(safari, animated: true, completion: nil)
    }
}
