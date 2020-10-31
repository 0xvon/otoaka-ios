//
//  CreateUserViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/31.
//

import UIKit
import AWSCognitoAuth

final class CreateUserViewController: UIViewController, Instantiable {
    typealias Input = AWSCognitoAuthUserSession
    var input: Input!
    
    enum SectionType {
        case fan
        case band
    }
    
//    lazy var viewModel = AuthViewModel(
//        auth: dependencyProvider.auth,
//        apiEndpoint: dependencyProvider.apiEndpoint,
//        outputHander: { output in
//            switch output {
//            case .signin(let session, let isSignedup):
//                if isSignedup {
//                    let vc = HomeViewController(dependencyProvider: self.dependencyProvider, input: ())
//                    self.navigationController?.pushViewController(vc, animated: true)
//                } else {
//                    print("hello")
//                }
//            case .error(let error):
//                print(error)
//            }
//        }
//    )
    
    @IBOutlet weak var setProfileView: UIView!
    @IBOutlet weak var createUserButtonView: Button!
    @IBOutlet weak var fanSection: UIView!
    @IBOutlet weak var bandSection: UIView!
    @IBOutlet weak var profileInputView: UIView!
    
    private var nameInputView: TextFieldView!
    private var artistNameInputView: TextFieldView!
    private var partInputView: TextFieldView!
    private var fanInputs: UIView!
    private var bandInputs: UIView!
    private var sectionType: SectionType = .fan
    
    var dependencyProvider: DependencyProvider
    
    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input
        
        super.init(nibName: nil, bundle: nil)
        
//        viewModel.signin()
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
        
        let fanImageView = UIImageView()
        fanImageView.translatesAutoresizingMaskIntoConstraints = false
        fanImageView.image = UIImage(named: "selectedGuitarIcon")
        fanSection.addSubview(fanImageView)
        
        let fanTitleLabel = UILabel()
        fanTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        fanTitleLabel.text = "ファン"
        fanTitleLabel.font = style.font.regular.get()
        fanTitleLabel.textColor = style.color.main.get()
        fanSection.addSubview(fanTitleLabel)
        
        let fanSectionButton = UIButton()
        fanSectionButton.translatesAutoresizingMaskIntoConstraints = false
        fanSectionButton.translatesAutoresizingMaskIntoConstraints = false
        fanSectionButton.addTarget(self, action: #selector(fanSectionButtonTapped(_:)), for: .touchUpInside)
        fanSection.addSubview(fanSectionButton)
        
        let bandImageView = UIImageView()
        bandImageView.translatesAutoresizingMaskIntoConstraints = false
        bandImageView.image = UIImage(named: "selectedMusicIcon")
        bandSection.addSubview(bandImageView)
        
        let bandTitleLabel = UILabel()
        bandTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        bandTitleLabel.text = "バンド"
        bandTitleLabel.font = style.font.regular.get()
        bandTitleLabel.textColor = style.color.main.get()
        bandSection.addSubview(bandTitleLabel)
        
        let bandSectionButton = UIButton()
        bandSectionButton.translatesAutoresizingMaskIntoConstraints = false
        bandSectionButton.addTarget(self, action: #selector(bandSectionButtonTapped(_:)), for: .touchUpInside)
        bandSection.addSubview(bandSectionButton)
        
        fanInputs = UIView()
        fanInputs.backgroundColor = style.color.background.get()
        fanInputs.translatesAutoresizingMaskIntoConstraints = false
        profileInputView.addSubview(fanInputs)
        
        nameInputView = TextFieldView(input: "表示名")
        nameInputView.translatesAutoresizingMaskIntoConstraints = false
        fanInputs.addSubview(nameInputView)
        
        bandInputs = UIView()
        bandInputs.backgroundColor = style.color.background.get()
        bandInputs.translatesAutoresizingMaskIntoConstraints = false
        profileInputView.addSubview(bandInputs)
        
        artistNameInputView = TextFieldView(input: "表示名")
        artistNameInputView.translatesAutoresizingMaskIntoConstraints = false
        bandInputs.addSubview(artistNameInputView)
        
        partInputView = TextFieldView(input: "パート")
        partInputView.translatesAutoresizingMaskIntoConstraints = false
        bandInputs.addSubview(partInputView)
        
        sectionChanged(section: sectionType)
        
        let constraints = [
            fanImageView.widthAnchor.constraint(equalToConstant: 40),
            fanImageView.heightAnchor.constraint(equalToConstant: 40),
            fanImageView.centerXAnchor.constraint(equalTo: fanSection.centerXAnchor),
            fanImageView.topAnchor.constraint(equalTo: fanSection.topAnchor, constant: 32),
            
            fanTitleLabel.topAnchor.constraint(equalTo: fanImageView.bottomAnchor, constant: 4),
            fanTitleLabel.centerXAnchor.constraint(equalTo: fanImageView.centerXAnchor),
            
            fanSectionButton.topAnchor.constraint(equalTo: fanSection.topAnchor),
            fanSectionButton.bottomAnchor.constraint(equalTo: fanSection.bottomAnchor),
            fanSectionButton.rightAnchor.constraint(equalTo: fanSection.rightAnchor),
            fanSectionButton.leftAnchor.constraint(equalTo: fanSection.leftAnchor),
            
            bandImageView.widthAnchor.constraint(equalToConstant: 40),
            bandImageView.heightAnchor.constraint(equalToConstant: 40),
            bandImageView.centerXAnchor.constraint(equalTo: bandSection.centerXAnchor),
            bandImageView.topAnchor.constraint(equalTo: bandSection.topAnchor, constant: 32),
            
            bandTitleLabel.topAnchor.constraint(equalTo: bandImageView.bottomAnchor, constant: 4),
            bandTitleLabel.centerXAnchor.constraint(equalTo: bandImageView.centerXAnchor),
            
            bandSectionButton.topAnchor.constraint(equalTo: bandSection.topAnchor),
            bandSectionButton.bottomAnchor.constraint(equalTo: bandSection.bottomAnchor),
            bandSectionButton.rightAnchor.constraint(equalTo: bandSection.rightAnchor),
            bandSectionButton.leftAnchor.constraint(equalTo: bandSection.leftAnchor),
            
            fanInputs.topAnchor.constraint(equalTo: profileInputView.topAnchor),
            fanInputs.bottomAnchor.constraint(equalTo: profileInputView.bottomAnchor),
            fanInputs.rightAnchor.constraint(equalTo: profileInputView.rightAnchor),
            fanInputs.leftAnchor.constraint(equalTo: profileInputView.leftAnchor),
            
            nameInputView.topAnchor.constraint(equalTo: fanInputs.topAnchor, constant: 16),
            nameInputView.rightAnchor.constraint(equalTo: fanInputs.rightAnchor, constant: -16),
            nameInputView.leftAnchor.constraint(equalTo: fanInputs.leftAnchor, constant: 16),
            nameInputView.heightAnchor.constraint(equalToConstant: 50),
            
            bandInputs.topAnchor.constraint(equalTo: profileInputView.topAnchor),
            bandInputs.bottomAnchor.constraint(equalTo: profileInputView.bottomAnchor),
            bandInputs.rightAnchor.constraint(equalTo: profileInputView.rightAnchor),
            bandInputs.leftAnchor.constraint(equalTo: profileInputView.leftAnchor),
            
            artistNameInputView.topAnchor.constraint(equalTo: bandInputs.topAnchor, constant: 16),
            artistNameInputView.rightAnchor.constraint(equalTo: bandInputs.rightAnchor, constant: -16),
            artistNameInputView.leftAnchor.constraint(equalTo: bandInputs.leftAnchor, constant: 16),
            artistNameInputView.heightAnchor.constraint(equalToConstant: 50),
            
            partInputView.topAnchor.constraint(equalTo: artistNameInputView.bottomAnchor, constant: 32),
            partInputView.rightAnchor.constraint(equalTo: bandInputs.rightAnchor, constant: -16),
            partInputView.leftAnchor.constraint(equalTo: bandInputs.leftAnchor, constant: 16),
            partInputView.heightAnchor.constraint(equalToConstant: 50),
        ]
        NSLayoutConstraint.activate(constraints)
        
    }
    
    func sectionChanged(section: SectionType) {
        self.sectionType = section
        switch self.sectionType {
        case .fan:
            fanSection.layer.borderWidth = 1
            fanSection.layer.borderColor = style.color.main.get().cgColor
            bandSection.layer.borderWidth = 0
            profileInputView.bringSubviewToFront(fanInputs)
        case .band:
            bandSection.layer.borderWidth = 1
            bandSection.layer.borderColor = style.color.main.get().cgColor
            fanSection.layer.borderWidth = 0
            profileInputView.bringSubviewToFront(bandInputs)
        }
    }
    
    @objc private func fanSectionButtonTapped(_ sender: Any) {
        sectionChanged(section: .fan)
    }
    
    @objc private func bandSectionButtonTapped(_ sender: Any) {
        sectionChanged(section: .band)
    }
    
}
