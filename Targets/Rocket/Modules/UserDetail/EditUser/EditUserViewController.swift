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
import TagListView

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
    private lazy var usernameInputView: TextFieldView = {
        let inputView = TextFieldView(input: (section: "ユーザーネーム", text: nil, maxLength: 12))
        inputView.translatesAutoresizingMaskIntoConstraints = false
        return inputView
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
        let displayNameInputView = TextFieldView(input: (section: "称号(任意)", text: nil, maxLength: 20))
        displayNameInputView.translatesAutoresizingMaskIntoConstraints = false
        return displayNameInputView
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
//    private lazy var registerButton: PrimaryButton = {
//        let registerButton = PrimaryButton(text: "ユーザー編集")
//        registerButton.translatesAutoresizingMaskIntoConstraints = false
//        registerButton.layer.cornerRadius = 25
//        registerButton.isEnabled = false
//        return registerButton
//    }()
    private lazy var recentlyFollowingWrapper: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        
        view.addSubview(recentlyFollowingTitle)
        NSLayoutConstraint.activate([
            recentlyFollowingTitle.heightAnchor.constraint(equalToConstant: 24),
            recentlyFollowingTitle.leftAnchor.constraint(equalTo: view.leftAnchor),
            recentlyFollowingTitle.topAnchor.constraint(equalTo: view.topAnchor),
            recentlyFollowingTitle.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        view.addSubview(recentlyFollowingListView)
        NSLayoutConstraint.activate([
            recentlyFollowingListView.topAnchor.constraint(equalTo: recentlyFollowingTitle.bottomAnchor, constant: 8),
            recentlyFollowingListView.leftAnchor.constraint(equalTo: recentlyFollowingTitle.leftAnchor),
            recentlyFollowingListView.rightAnchor.constraint(equalTo: recentlyFollowingTitle.rightAnchor),
            recentlyFollowingListView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        return view
    }()
    private lazy var recentlyFollowingTitle: UILabel = {
        let section = UILabel()
        section.translatesAutoresizingMaskIntoConstraints = false
        section.text = "最近好きなアーティスト"
        section.font = Brand.font(for: .medium)
        section.textColor = Brand.color(for: .brand(.primary))
        return section
    }()
    private lazy var recentlyFollowingListView: TagListView = {
        let content = TagListView()
        content.delegate = self
        content.translatesAutoresizingMaskIntoConstraints = false
        content.alignment = .left
        content.cornerRadius = 16
        content.paddingY = 8
        content.paddingX = 12
        content.marginX = 8
        content.marginY = 8
        content.removeIconLineColor = Brand.color(for: .text(.primary))
        content.textFont = Brand.font(for: .medium)
        content.tagBackgroundColor = .clear
        content.borderColor = Brand.color(for: .brand(.primary))
        content.borderWidth = 1
        content.textColor = Brand.color(for: .brand(.primary))
        return content
    }()
    private lazy var registerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(Brand.color(for: .brand(.primary)), for: .normal)
        button.setTitleColor(Brand.color(for: .background(.light)), for: .disabled)
        button.setTitleColor(Brand.color(for: .brand(.primary)), for: .highlighted)
        button.setTitle("更新", for: .normal)
        button.titleLabel?.font = Brand.font(for: .mediumStrong)
        return button
    }()
    private lazy var activityIndicator: LoadingCollectionView = {
        let activityIndicator = LoadingCollectionView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
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
        usernameInputView.setText(text: user.username ?? "")
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
            case .didGetRecentlyFollowing(let groups):
                recentlyFollowingListView.removeAllTags()
                recentlyFollowingListView.addTags(groups.map { $0.name + " ✗" })
                
                let plusTag = recentlyFollowingListView.addTag("追加＋")
                plusTag.borderColor = Brand.color(for: .background(.light))
                plusTag.textColor = Brand.color(for: .background(.light))
                plusTag.borderWidth = 1
                plusTag.tagBackgroundColor = .clear
            case .didUpdateUsername:
                viewModel.uploadProfileImage()
            case .usernameAlreadyExists:
                showAlert(title: "ユーザーネームは使えません", message: "ユーザーネームが既に使われています")
                self.registerButton.isEnabled = true
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: registerButton)
                self.activityIndicator.stopAnimating()
            case .invalidUsername:
                showAlert(title: "ユーザーネームは使えません", message: "ユーザーネームに使用できない文字(0-9, a-z, A-Z, ._以外の文字)が含まれています")
                self.registerButton.isEnabled = true
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: registerButton)
                self.activityIndicator.stopAnimating()
            case .updateSubmittableState(let state):
                switch state {
                case .editting(let submittable):
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: registerButton)
                    self.registerButton.isEnabled = submittable
                    self.activityIndicator.stopAnimating()
                case .loading:
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
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
        
        usernameInputView.listen { [ unowned self] in
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: registerButton)
        registerButton.isEnabled = false
        
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
        
        mainView.addArrangedSubview(usernameInputView)
        NSLayoutConstraint.activate([
            usernameInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
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
        NSLayoutConstraint.activate([
            liveStyleInputView.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        mainView.addArrangedSubview(residenceInputView)
        residenceInputView.selectInputView(inputView: residencePickerView)
        NSLayoutConstraint.activate([
            residenceInputView.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        mainView.addArrangedSubview(recentlyFollowingWrapper)
        
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
        
//        mainView.addArrangedSubview(registerButton)
//        NSLayoutConstraint.activate([
//            registerButton.heightAnchor.constraint(equalToConstant: 50),
//        ])
        
        let bottomSpacer = UIView()
        mainView.addArrangedSubview(bottomSpacer) // Spacer
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        displayNameInputView.focus()
    }

    private func didInputValue() {
        let displayName = displayNameInputView.getText()
        let username = usernameInputView.getText()
        let sex = sexInputView.getText()
        let age = ageInputView.getText()
        let liveStyle = liveStyleInputView.getText()
        let residence = residenceInputView.getText()
//        let twitterUrl = twitterUrlTextFieldView.getText()
//        let instagramUrl = instagramUrlTextFieldView.getText()
        
        viewModel.didUpdateInputItems(
            displayName: displayName,
            username: username,
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

extension EditUserViewController: TagListViewDelegate {
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        if title == "追加＋" {
            let vc = SelectGroupViewController(dependencyProvider: dependencyProvider)
            self.navigationController?.pushViewController(vc, animated: true)
            vc.listen { [unowned self] group in
                viewModel.addGroup(group.group)
            }
        } else {
            viewModel.removeGroup(title)
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
        case self.residencePickerView:
            return viewModel.state.socialInputs.prefectures[row]
        default: return "yo"
        }
    }
}
