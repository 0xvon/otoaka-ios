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
import CropViewController

final class EditUserViewController: UIViewController, Instantiable {
    typealias Input = Void
    
    private lazy var verticalScrollView: UIScrollView = {
        let verticalScrollView = UIScrollView()
        verticalScrollView.translatesAutoresizingMaskIntoConstraints = false
        verticalScrollView.backgroundColor = .clear
        verticalScrollView.showsVerticalScrollIndicator = false
        verticalScrollView.isScrollEnabled = true
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
        let biographyInputView = InputTextView(input: (section: "自己紹介文(任意)", text: nil, maxLength: 4000))
        biographyInputView.translatesAutoresizingMaskIntoConstraints = false
        return biographyInputView
    }()
    private lazy var sexInputView: TextFieldView = {
        let displayNameInputView = TextFieldView(input: (section: "性別(任意)", text: nil, maxLength: 20))
        displayNameInputView.translatesAutoresizingMaskIntoConstraints = false
        return displayNameInputView
    }()
    private lazy var sexPickerView: UIPickerView = {
        let picketView = UIPickerView()
        picketView.translatesAutoresizingMaskIntoConstraints = false
        picketView.dataSource = self
        picketView.delegate = self
        return picketView
    }()
    private lazy var ageInputView: TextFieldView = {
        let displayNameInputView = TextFieldView(input: (section: "年齢(任意)", text: nil, maxLength: 4))
        displayNameInputView.translatesAutoresizingMaskIntoConstraints = false
        return displayNameInputView
    }()
    private lazy var agePickerView: UIPickerView = {
        let picketView = UIPickerView()
        picketView.translatesAutoresizingMaskIntoConstraints = false
        picketView.dataSource = self
        picketView.delegate = self
        return picketView
    }()
    private lazy var liveStyleInputView: TextFieldView = {
        let displayNameInputView = TextFieldView(input: (section: "ライブの楽しみ方(任意)", text: nil, maxLength: 20))
        displayNameInputView.translatesAutoresizingMaskIntoConstraints = false
        return displayNameInputView
    }()
    private lazy var liveStylePickerView: UIPickerView = {
        let picketView = UIPickerView()
        picketView.translatesAutoresizingMaskIntoConstraints = false
        picketView.dataSource = self
        picketView.delegate = self
        return picketView
    }()
    private lazy var residenceInputView: TextFieldView = {
        let displayNameInputView = TextFieldView(input: (section: "都道府県(任意)", text: nil, maxLength: 20))
        displayNameInputView.translatesAutoresizingMaskIntoConstraints = false
        return displayNameInputView
    }()
    private lazy var residencePickerView: UIPickerView = {
        let picketView = UIPickerView()
        picketView.translatesAutoresizingMaskIntoConstraints = false
        picketView.dataSource = self
        picketView.delegate = self
        return picketView
    }()
//    private lazy var twitterUrlTextFieldView: TextFieldView = {
//        let twitterUrlTextFieldView = TextFieldView(input: (section: "Twitterリンク", text: nil, maxLength: 40))
//        twitterUrlTextFieldView.translatesAutoresizingMaskIntoConstraints = false
//        twitterUrlTextFieldView.keyboardType(.alphabet)
//        return twitterUrlTextFieldView
//    }()
//    private lazy var instagramUrlTextFieldView: TextFieldView = {
//        let instagramIdTextFieldView = TextFieldView(input: (section: "Instagramリンク", text: nil, maxLength: 40))
//        instagramIdTextFieldView.translatesAutoresizingMaskIntoConstraints = false
//        instagramIdTextFieldView.keyboardType(.alphabet)
//        return instagramIdTextFieldView
//    }()
//    private lazy var partInputView: TextFieldView = {
//        let partInputView = TextFieldView(input: (section: "パート", text: nil, maxLength: 20))
//        partInputView.translatesAutoresizingMaskIntoConstraints = false
//        return partInputView
//    }()
//    private lazy var partPickerView: UIPickerView = {
//        let partPickerView = UIPickerView()
//        partPickerView.translatesAutoresizingMaskIntoConstraints = false
//        partPickerView.dataSource = self
//        partPickerView.delegate = self
//        return partPickerView
//    }()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    func update(user: User) {
        displayNameInputView.setText(text: user.name)
        biographyInputView.setText(text: user.biography ?? "")
        sexInputView.setText(text: user.sex ?? "")
        ageInputView.setText(text: user.age.map { String($0) } ?? "")
        liveStyleInputView.setText(text: user.liveStyle ?? "")
        residenceInputView.setText(text: user.residence ?? "")
//        twitterUrlTextFieldView.setText(text: user.twitterUrl?.absoluteString ?? "https://twitter.com/")
//        instagramUrlTextFieldView.setText(text: user.instagramUrl?.absoluteString ?? "https://instagram.com/")
        switch user.role {
        case .fan(_):
            break
        case .artist(_):
//            partInputView.setText(text: artist.part)
        break
        }
        if let thumbnailURL = user.thumbnailURL.flatMap(URL.init(string:)) {
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
//            case .didInjectRole(let role):
//                switch role {
//                case .fan(_):
//                    partInputView.isHidden = true
//                case .artist(let artist):
//                    partInputView.isHidden = false
//                    partInputView.setText(text: artist.part)
//                }
            case .updateSubmittableState(let state):
                switch state {
                case .editting(let submittable):
                    self.registerButton.isEnabled = submittable
                    self.activityIndicator.stopAnimating()
                case .loading:
                    self.registerButton.isEnabled = false
                    self.activityIndicator.startAnimating()
                }
            case .reportError(let error):
                print(error)
                self.showAlert()
            }
        }
        .store(in: &cancellables)
        
        displayNameInputView.listen { [unowned self] in
            self.didInputValue()
        }
        
        biographyInputView.listen { [unowned self] in
            self.didInputValue()
        }
        
        sexInputView.listen { [unowned self] in
            sexInputView.setText(text: viewModel.state.socialInputs.sex[sexPickerView.selectedRow(inComponent: 0)])
            self.didInputValue()
        }
        
        ageInputView.listen { [unowned self] in
            ageInputView.setText(text: viewModel.state.socialInputs.age[agePickerView.selectedRow(inComponent: 0)])
            self.didInputValue()
        }
        
        liveStyleInputView.listen { [unowned self] in
            liveStyleInputView.setText(text: viewModel.state.socialInputs.howToEnjoyLives[liveStylePickerView.selectedRow(inComponent: 0)])
            self.didInputValue()
        }
        
        residenceInputView.listen { [unowned self] in
            residenceInputView.setText(text: viewModel.state.socialInputs.prefectures[residencePickerView.selectedRow(inComponent: 0)])
            self.didInputValue()
        }
        
//        twitterUrlTextFieldView.listen { [unowned self] in
//            self.didInputValue()
//        }
//
//        instagramUrlTextFieldView.listen { [unowned self] in
//            self.didInputValue()
//        }
        
//        partInputView.listen {
//            self.partInputView.setText(text: self.viewModel.state.socialInputs.parts[self.partPickerView.selectedRow(inComponent: 0)])
//            self.didInputValue()
//        }
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
        
        mainView.addArrangedSubview(displayNameInputView)
        NSLayoutConstraint.activate([
            displayNameInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(biographyInputView)
        NSLayoutConstraint.activate([
            biographyInputView.heightAnchor.constraint(equalToConstant: 88),
        ])
        
        mainView.addArrangedSubview(sexInputView)
        sexInputView.selectInputView(inputView: sexPickerView)
        NSLayoutConstraint.activate([
            sexInputView.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        mainView.addArrangedSubview(ageInputView)
        ageInputView.selectInputView(inputView: agePickerView)
        NSLayoutConstraint.activate([
            ageInputView.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        mainView.addArrangedSubview(liveStyleInputView)
        liveStyleInputView.selectInputView(inputView: liveStylePickerView)
        NSLayoutConstraint.activate([
            liveStyleInputView.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        mainView.addArrangedSubview(residenceInputView)
        residenceInputView.selectInputView(inputView: residencePickerView)
        NSLayoutConstraint.activate([
            residenceInputView.heightAnchor.constraint(equalToConstant: 50),
        ])
        
//        mainView.addArrangedSubview(twitterUrlTextFieldView)
//        NSLayoutConstraint.activate([
//            twitterUrlTextFieldView.heightAnchor.constraint(equalToConstant: textFieldHeight),
//        ])
//
//        mainView.addArrangedSubview(instagramUrlTextFieldView)
//        NSLayoutConstraint.activate([
//            instagramUrlTextFieldView.heightAnchor.constraint(equalToConstant: textFieldHeight),
//        ])
        
//        mainView.addArrangedSubview(partInputView)
//        partInputView.selectInputView(inputView: partPickerView)
//        NSLayoutConstraint.activate([
//            partInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
//        ])
        
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
        let sex = sexInputView.getText()
        let age = ageInputView.getText()
        let liveStyle = liveStyleInputView.getText()
        let residence = residenceInputView.getText()
//        let twitterUrl = twitterUrlTextFieldView.getText()
//        let instagramUrl = instagramUrlTextFieldView.getText()
        
        viewModel.didUpdateInputItems(
            displayName: displayName,
            biography: biography,
            sex: sex,
            age: age,
            liveStyle: liveStyle,
            residence: residence,
            twitterUrl: nil,
            instagramUrl: nil
        )
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
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        
        let cropController = CropViewController(image: image)
        cropController.delegate = self
        cropController.customAspectRatio = profileImageView.frame.size
        cropController.aspectRatioPickerButtonHidden = true
        cropController.resetAspectRatioEnabled = false
        cropController.rotateButtonsHidden = true
        cropController.cropView.cropBoxResizeEnabled = false
        picker.dismiss(animated: true) {
            self.present(cropController, animated: true, completion: nil)
        }
    }
}

extension EditUserViewController: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        profileImageView.image = image
        viewModel.didUpdateArtwork(artwork: image)
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

extension EditUserViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case self.sexPickerView:
            return viewModel.state.socialInputs.sex.count
        case self.agePickerView:
            return viewModel.state.socialInputs.age.count
        case self.liveStylePickerView:
            return viewModel.state.socialInputs.howToEnjoyLives.count
        case self.residencePickerView:
            return viewModel.state.socialInputs.prefectures.count
        default: return 1
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
        -> String?
    {
        switch pickerView {
        case self.sexPickerView:
            return viewModel.state.socialInputs.sex[row]
        case self.agePickerView:
            return viewModel.state.socialInputs.age[row]
        case self.liveStylePickerView:
            return viewModel.state.socialInputs.howToEnjoyLives[row]
        case self.residencePickerView:
            return viewModel.state.socialInputs.prefectures[row]
        default: return "yo"
        }
    }
}
