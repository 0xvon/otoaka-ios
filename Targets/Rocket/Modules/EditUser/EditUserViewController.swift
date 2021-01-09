//
//  EditUserViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import UIKit
import KeyboardGuide

final class EditUserViewController: UIViewController, Instantiable {
    typealias Input = Void
    
    private lazy var verticalScrollView: UIScrollView = {
        let verticalScrollView = UIScrollView()
        verticalScrollView.translatesAutoresizingMaskIntoConstraints = false
        verticalScrollView.backgroundColor = .clear
        verticalScrollView.showsVerticalScrollIndicator = false
        return verticalScrollView
    }()
    private lazy var mainView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 48
        return stackView
    }()
    private lazy var displayNameInputView: TextFieldView = {
        let displayNameInputView = TextFieldView(input: (section: "表示名", text: nil, maxLength: 20))
        displayNameInputView.translatesAutoresizingMaskIntoConstraints = false
        return displayNameInputView
    }()
    private lazy var biographyInputView: InputTextView = {
        let biographyInputView = InputTextView(input: (section: "自己紹介文(任意)", text: nil, maxLength: 200))
        biographyInputView.translatesAutoresizingMaskIntoConstraints = false
        return biographyInputView
    }()
    private lazy var partInputView: TextFieldView = {
        let partInputView = TextFieldView(input: (section: "パート", text: nil, maxLength: 20))
        partInputView.translatesAutoresizingMaskIntoConstraints = false
        return partInputView
    }()
    private lazy var partPickerView: UIPickerView = {
        let partPickerView = UIPickerView()
        partPickerView.translatesAutoresizingMaskIntoConstraints = false
        partPickerView.dataSource = self
        partPickerView.delegate = self
        return partPickerView
    }()
    private var thumbnailInputView: UIView = {
        let thumbnailInputView = UIView()
        thumbnailInputView.translatesAutoresizingMaskIntoConstraints = false
        
        return thumbnailInputView
    }()
    private lazy var profileImageView: UIImageView = {
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 60
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        return profileImageView
    }()
    private lazy var changeProfileImageButton: UIButton = {
        let changeProfileImageButton = UIButton()
        changeProfileImageButton.translatesAutoresizingMaskIntoConstraints = false
        changeProfileImageButton.addTarget(
            self, action: #selector(selectProfileImage(_:)), for: .touchUpInside)
        return changeProfileImageButton
    }()
    private lazy var profileImageTitle: UILabel = {
        let profileImageTitle = UILabel()
        profileImageTitle.translatesAutoresizingMaskIntoConstraints = false
        profileImageTitle.text = "プロフィール画像"
        profileImageTitle.textAlignment = .center
        profileImageTitle.font = Brand.font(for: .medium)
        profileImageTitle.textColor = Brand.color(for: .text(.primary))
        return profileImageTitle
    }()
    private lazy var registerButton: PrimaryButton = {
        let registerButton = PrimaryButton(text: "ユーザー編集")
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        registerButton.layer.cornerRadius = 25
        registerButton.isEnabled = false
        return registerButton
    }()
    private lazy var activityIndicator: LoadingCollectionView = {
        let activityIndicator = LoadingCollectionView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.heightAnchor.constraint(equalToConstant: 40),
            activityIndicator.widthAnchor.constraint(equalToConstant: 40),
        ])
        return activityIndicator
    }()
    
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: EditUserViewModel
    var cancellables: Set<AnyCancellable> = []
    
    private var listener: () -> Void = {}
    func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = EditUserViewModel(dependencyProvider: dependencyProvider)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
        
        viewModel.viewDidLoad()
    }
    
    func update(user: User) {
        displayNameInputView.setText(text: user.name)
        biographyInputView.setText(text: user.biography ?? "")
        switch user.role {
        case .fan(_):
            break
        case .artist(let artist):
            partInputView.setText(text: artist.part)
        }
        if let thumbnailURL = user.thumbnailURL.flatMap(URL.init(string: )) {
            dependencyProvider.imagePipeline.loadImage(thumbnailURL, into: profileImageView)
        }
    }
    
    func bind() {
        registerButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: viewModel.didEditButtonTapped)
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didEditUser(_):
                self.listener()
                self.navigationController?.popViewController(animated: true)
            case .didGetUserInfo(let user):
                self.update(user: user)
            case .didInjectRole(let role):
                switch role {
                case .fan(_):
                    partInputView.isHidden = true
                case .artist(let artist):
                    partInputView.isHidden = false
                    partInputView.setText(text: artist.part)
                }
            case .updateSubmittableState(let state):
                switch state {
                case .completed:
                    self.registerButton.isEnabled = true
                    self.activityIndicator.stopAnimating()
                case .editting(let submittable):
                    self.registerButton.isEnabled = submittable
                case .loading:
                    self.registerButton.isEnabled = false
                    self.activityIndicator.startAnimating()
                }
            case .reportError(let error):
                self.showAlert(title: "エラー", message: error.localizedDescription)
            }
        }
        .store(in: &cancellables)
        
        displayNameInputView.listen {
            self.didInputValue()
        }
        
        biographyInputView.listen {
            self.didInputValue()
        }
        
        partInputView.listen {
            self.partInputView.setText(text: self.viewModel.state.socialInputs.parts[self.partPickerView.selectedRow(inComponent: 0)])
            self.didInputValue()
        }
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.title = "ユーザー編集"
        self.navigationItem.largeTitleDisplayMode = .never
        
        self.view.addSubview(verticalScrollView)
        NSLayoutConstraint.activate([
            verticalScrollView.topAnchor.constraint(equalTo: self.view.keyboardSafeArea.layoutGuide.topAnchor),
            verticalScrollView.bottomAnchor.constraint(equalTo: self.view.keyboardSafeArea.layoutGuide.bottomAnchor),
            verticalScrollView.rightAnchor.constraint(equalTo: self.view.keyboardSafeArea.layoutGuide.rightAnchor, constant: -16),
            verticalScrollView.leftAnchor.constraint(equalTo: self.view.keyboardSafeArea.layoutGuide.leftAnchor, constant: 16),
        ])
        
        verticalScrollView.addSubview(mainView)
        NSLayoutConstraint.activate([
            mainView.topAnchor.constraint(equalTo: verticalScrollView.topAnchor),
            mainView.bottomAnchor.constraint(equalTo: verticalScrollView.bottomAnchor),
            mainView.rightAnchor.constraint(equalTo: verticalScrollView.rightAnchor),
            mainView.leftAnchor.constraint(equalTo: verticalScrollView.leftAnchor),
            mainView.centerXAnchor.constraint(equalTo: verticalScrollView.centerXAnchor),
        ])
        
        let topSpacer = UIView()
        mainView.addArrangedSubview(topSpacer) // Spacer
        NSLayoutConstraint.activate([
            topSpacer.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        mainView.addArrangedSubview(displayNameInputView)
        NSLayoutConstraint.activate([
            displayNameInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(biographyInputView)
        NSLayoutConstraint.activate([
            biographyInputView.heightAnchor.constraint(equalToConstant: 200),
        ])
        
        mainView.addArrangedSubview(partInputView)
        partInputView.selectInputView(inputView: partPickerView)
        NSLayoutConstraint.activate([
            partInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(thumbnailInputView)
        NSLayoutConstraint.activate([
            thumbnailInputView.heightAnchor.constraint(equalToConstant: 150),
        ])
        
        thumbnailInputView.addSubview(profileImageView)
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            profileImageView.topAnchor.constraint(equalTo: thumbnailInputView.topAnchor),
            profileImageView.centerXAnchor.constraint(equalTo: thumbnailInputView.centerXAnchor),
        ])
        
        thumbnailInputView.addSubview(profileImageTitle)
        NSLayoutConstraint.activate([
            profileImageTitle.leftAnchor.constraint(equalTo: thumbnailInputView.leftAnchor),
            profileImageTitle.rightAnchor.constraint(equalTo: thumbnailInputView.rightAnchor),
            profileImageTitle.bottomAnchor.constraint(equalTo: thumbnailInputView.bottomAnchor),
        ])
        
        thumbnailInputView.addSubview(changeProfileImageButton)
        NSLayoutConstraint.activate([
            changeProfileImageButton.topAnchor.constraint(equalTo: thumbnailInputView.topAnchor),
            changeProfileImageButton.rightAnchor.constraint(
                equalTo: thumbnailInputView.rightAnchor),
            changeProfileImageButton.leftAnchor.constraint(equalTo: thumbnailInputView.leftAnchor),
            changeProfileImageButton.bottomAnchor.constraint(equalTo: thumbnailInputView.bottomAnchor),
        ])
        
        mainView.addArrangedSubview(registerButton)
        NSLayoutConstraint.activate([
            registerButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        let bottomSpacer = UIView()
        mainView.addArrangedSubview(bottomSpacer) // Spacer
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        displayNameInputView.focus()
    }

    private func didInputValue() {
        let displayName: String? = displayNameInputView.getText()
        let biography = biographyInputView.getText()
        
        viewModel.didUpdateInputItems(displayName: displayName, biography: biography)
    }

    @objc private func selectProfileImage(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }
}

extension EditUserViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        profileImageView.image = image
        viewModel.didUpdateArtwork(artwork: image)
        self.dismiss(animated: true, completion: nil)
    }
}

extension EditUserViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel.state.socialInputs.parts.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
        -> String?
    {
        return viewModel.state.socialInputs.parts[row]
    }
}
