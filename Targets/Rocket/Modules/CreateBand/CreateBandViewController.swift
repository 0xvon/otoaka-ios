//
//  CreateBandViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/01.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import UIKit

final class CreateBandViewController: UIViewController, Instantiable {
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
        let displayNameInputView = TextFieldView(input: (section: "バンド名", text: nil, maxLength: 20))
        displayNameInputView.translatesAutoresizingMaskIntoConstraints = false
        return displayNameInputView
    }()
    private lazy var englishNameInputView: TextFieldView = {
        let englishNameInputView = TextFieldView(input: (section: "English Name(optional)", text: nil, maxLength: 40))
        englishNameInputView.keyboardType(.alphabet)
        englishNameInputView.translatesAutoresizingMaskIntoConstraints = false
        return englishNameInputView
    }()
    private lazy var biographyInputView: InputTextView = {
        let biographyInputView = InputTextView(input: (section: "自己紹介文(任意)", text: nil, maxLength: 200))
        biographyInputView.translatesAutoresizingMaskIntoConstraints = false
        return biographyInputView
    }()
    private lazy var sinceInputView: TextFieldView = {
        let sinceInputView = TextFieldView(input: (section: "結成年(任意)", text: nil, maxLength: 20))
        sinceInputView.translatesAutoresizingMaskIntoConstraints = false
        return sinceInputView
    }()
    private lazy var sincePickerView: UIPickerView = {
        let sincePickerView = UIPickerView()
        sincePickerView.translatesAutoresizingMaskIntoConstraints = false
        sincePickerView.dataSource = self
        sincePickerView.delegate = self
        return sincePickerView
    }()
    private lazy var hometownInputView: TextFieldView = {
        let hometownInputView = TextFieldView(input: (section: "出身地(任意)", text: nil,  maxLength: 20))
        hometownInputView.translatesAutoresizingMaskIntoConstraints = false
        return hometownInputView
    }()
    private lazy var hometownPickerView: UIPickerView = {
        let hometownPickerView = UIPickerView()
        hometownPickerView.translatesAutoresizingMaskIntoConstraints = false
        hometownPickerView.dataSource = self
        hometownPickerView.delegate = self
        return hometownPickerView
    }()
    private lazy var youTubeIdInputView: TextFieldView = {
        let youTubeIdInputView = TextFieldView(input: (section: "YouTube Channel ID(任意)",text: nil,  maxLength: 40))
        youTubeIdInputView.translatesAutoresizingMaskIntoConstraints = false
        return youTubeIdInputView
    }()
    private lazy var twitterIdInputView: TextFieldView = {
        let twitterIdInputView = TextFieldView(input: (section: "Twitter ID(@を省略)(任意)", text: nil, maxLength: 20))
        twitterIdInputView.translatesAutoresizingMaskIntoConstraints = false
        return twitterIdInputView
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
        profileImageView.clipsToBounds = true
        profileImageView.image = UIImage(named: "human")
        profileImageView.contentMode = .scaleAspectFill
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
        let registerButton = PrimaryButton(text: "バンド作成")
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        registerButton.layer.cornerRadius = 25
        registerButton.isEnabled = false
        return registerButton
    }()
    
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: CreateBandViewModel
    var cancellables: Set<AnyCancellable> = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = CreateBandViewModel(dependencyProvider: dependencyProvider)

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
        registerButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: viewModel.didRegisterButtonTapped)
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didCreateGroup(_):
                self.dismiss(animated: true, completion: nil)
            case .didValidateYoutubeChannelId(let isValid):
                if !isValid {
                    self.showAlert(title: "YouTube Channel IDエラー", message: "入力された値が正しくありません")
                }
            case .updateSubmittableState(let isSubmittable):
                self.registerButton.isEnabled = isSubmittable
            case .reportError(let error):
                self.showAlert(title: "エラー", message: error.localizedDescription)
            }
        }
        .store(in: &cancellables)
        
        displayNameInputView.listen {
            self.didInputValue()
        }
        
        englishNameInputView.listen {
            self.didInputValue()
        }
        
        biographyInputView.listen {
            self.didInputValue()
        }
        
        sinceInputView.listen {
            self.sinceInputView.setText(text: self.viewModel.state.socialInputs.years[self.sincePickerView.selectedRow(inComponent: 0)])
            self.didInputValue()
        }
        
        hometownInputView.listen {
            self.hometownInputView.setText(text: self.viewModel.state.socialInputs.prefectures[self.hometownPickerView.selectedRow(inComponent: 0)])
            self.didInputValue()
        }
        
        youTubeIdInputView.listen {
            self.didInputValue()
        }
        
        twitterIdInputView.listen {
            self.didInputValue()
        }
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        self.view.addSubview(verticalScrollView)
        NSLayoutConstraint.activate([
            verticalScrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            verticalScrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            verticalScrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            verticalScrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
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
            topSpacer.heightAnchor.constraint(equalToConstant: 32),
        ])
        
        mainView.addArrangedSubview(displayNameInputView)
        NSLayoutConstraint.activate([
            displayNameInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(englishNameInputView)
        NSLayoutConstraint.activate([
            englishNameInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(biographyInputView)
        NSLayoutConstraint.activate([
            biographyInputView.heightAnchor.constraint(equalToConstant: 200),
        ])
        
        mainView.addArrangedSubview(sinceInputView)
        sinceInputView.selectInputView(inputView: sincePickerView)
        NSLayoutConstraint.activate([
            sinceInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(hometownInputView)
        hometownInputView.selectInputView(inputView: hometownPickerView)
        NSLayoutConstraint.activate([
            hometownInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(youTubeIdInputView)
        NSLayoutConstraint.activate([
            youTubeIdInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(twitterIdInputView)
        NSLayoutConstraint.activate([
            twitterIdInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
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
            bottomSpacer.heightAnchor.constraint(equalToConstant: 64),
        ])
    }
    
    private func didInputValue() {
        let groupName: String? = displayNameInputView.getText()
        let groupEnglishName: String? = englishNameInputView.getText()
        let biography: String? = biographyInputView.getText()
        let artworkImage: UIImage? = profileImageView.image
        let sinceInput = sinceInputView.getText()
        let since: Date? = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy"
            dateFormatter.locale = Locale(identifier: "ja_JP")
            guard let sinceInput = sinceInput else { return nil }
            return dateFormatter.date(from: sinceInput)
        }()
        let hometown = hometownInputView.getText()
        let youtubeChannelId = youTubeIdInputView.getText()
        let twitterId = twitterIdInputView.getText()
        
        viewModel.didUpdateInputItems(name: groupName, englishName: groupEnglishName, biography: biography, since: since, artwork: artworkImage, youtubeChannelId: youtubeChannelId, twitterId: twitterId, hometown: hometown)
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

extension CreateBandViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        profileImageView.image = image
        didInputValue()
        self.dismiss(animated: true, completion: nil)
    }
}

extension CreateBandViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
        -> String?
    {
        switch pickerView {
        case self.hometownPickerView:
            return viewModel.state.socialInputs.prefectures[row]
        case self.sincePickerView:
            return viewModel.state.socialInputs.years[row]
        default:
            return "yo"
        }
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case self.hometownPickerView:
            return viewModel.state.socialInputs.prefectures.count
        case self.sincePickerView:
            return viewModel.state.socialInputs.years.count
        default:
            return 1
        }
    }
}
