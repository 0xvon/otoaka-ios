//
//  EditGroupViewController.swift
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

final class EditBandViewController: UIViewController, Instantiable {
    typealias Input = Group
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
        let biographyInputView = InputTextView(input: (section: "自己紹介文(任意)(4000文字以内)", text: nil, maxLength: 4000))
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
    private lazy var editButton: PrimaryButton = {
        let registerButton = PrimaryButton(text: "バンド編集")
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        registerButton.layer.cornerRadius = 25
        registerButton.isEnabled = true
        return registerButton
    }()
    private lazy var deleteBandButton: PrimaryButton = {
        let deleteButton = PrimaryButton(text: "バンド削除")
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.layer.cornerRadius = 25
        deleteButton.changeButtonStyle(.delete)
        deleteButton.addTarget(self, action: #selector(deleteBandButtonTapped), for: .touchUpInside)
        deleteButton.isEnabled = true
        return deleteButton
    }()
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        return dateFormatter
    }()
    private lazy var activityIndicator: LoadingCollectionView = {
        let activityIndicator = LoadingCollectionView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: EditBandViewModel
    var cancellables: Set<AnyCancellable> = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = EditBandViewModel(dependencyProvider: dependencyProvider, group: input)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
        update()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    func bind() {
        editButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: viewModel.didEditButtonTapped)
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didEditGroup(_):
                self.navigationController?.popViewController(animated: true)
            case .didValidateYoutubeChannelId(let isValid):
                if !isValid {
                    self.showAlert(message: "入力された値が正しくありません。確認してください。")
                }
            case .updateSubmittableState(let state):
                switch state {
                case .editting(let submittable):
                    self.activityIndicator.stopAnimating()
                    self.editButton.isEnabled = submittable
                case .loading:
                    self.editButton.isEnabled = false
                    self.activityIndicator.startAnimating()
                }
            case .deleteGroup:
                guard let vcCount = navigationController?.viewControllers.count else { return }
                navigationController?.popToViewController((navigationController?.viewControllers[vcCount - 3])!, animated: true)
            case .reportError(let error):
                print(error)
                self.showAlert()
            }
        }
        .store(in: &cancellables)
        
        displayNameInputView.listen { [unowned self] in
            self.didInputValue()
        }
        
        englishNameInputView.listen { [unowned self] in
            self.didInputValue()
        }
        
        biographyInputView.listen { [unowned self] in
            self.didInputValue()
        }
        
        sinceInputView.listen { [unowned self] in
            self.sinceInputView.setText(text: self.viewModel.state.socialInputs.years[self.sincePickerView.selectedRow(inComponent: 0)])
            self.didInputValue()
        }
        
        hometownInputView.listen { [unowned self] in
            self.hometownInputView.setText(text: self.viewModel.state.socialInputs.prefectures[self.hometownPickerView.selectedRow(inComponent: 0)])
            self.didInputValue()
        }
        
        youTubeIdInputView.listen { [unowned self] in
            self.didInputValue()
        }
        
        twitterIdInputView.listen { [unowned self] in
            self.didInputValue()
        }
    }
    
    private func update() {
        let group = viewModel.state.group
        displayNameInputView.setText(text: group.name)
        englishNameInputView.setText(text: group.englishName ?? "")
        biographyInputView.setText(text: group.biography ?? "")
        let since: String? = {
            if let since = group.since {
                return dateFormatter.string(from: since)
            } else {
                return nil
            }
        }()
        sinceInputView.setText(text: since ?? "")
        hometownInputView.setText(text: group.hometown ?? "")
        youTubeIdInputView.setText(text: group.youtubeChannelId ?? "")
        twitterIdInputView.setText(text: group.twitterId ?? "")
        if let artworkURL = group.artworkURL {
            dependencyProvider.imagePipeline.loadImage(artworkURL, into: profileImageView)
        } else {
            // TODO: Set profile image placeholder
        }
    }
    

    private func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.title = "バンド編集"
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
        
        mainView.addArrangedSubview(editButton)
        NSLayoutConstraint.activate([
            editButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        mainView.addArrangedSubview(deleteBandButton)
        NSLayoutConstraint.activate([
            deleteBandButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        let bottomSpacer = UIView()
        mainView.addArrangedSubview(bottomSpacer) // Spacer
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 16),
        ])
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.heightAnchor.constraint(equalToConstant: 40),
            activityIndicator.widthAnchor.constraint(equalToConstant: 40),
        ])
        
        displayNameInputView.focus()
    }
    
    private func didInputValue() {
        let groupName: String? = displayNameInputView.getText()
        let groupEnglishName: String? = englishNameInputView.getText()
        let biography: String? = biographyInputView.getText()
        let sinceInput = sinceInputView.getText()
        let since: Date? = {
            guard let sinceInput = sinceInput else { return nil }
            return dateFormatter.date(from: sinceInput)
        }()
        let hometown = hometownInputView.getText()
        let youtubeChannelId = youTubeIdInputView.getText()
        let twitterId = twitterIdInputView.getText()
        
        viewModel.didUpdateInputItems(name: groupName, englishName: groupEnglishName, biography: biography, since: since, youtubeChannelId: youtubeChannelId, twitterId: twitterId, hometown: hometown)
    }

    @objc private func selectProfileImage(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    @objc private func deleteBandButtonTapped() {
        let alertController = UIAlertController(
            title: "本当に削除しますか？", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        let acceptAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.default,
            handler: { [unowned self] action in
                viewModel.deleteGroup()
            })
        let cancelAction = UIAlertAction(
            title: "キャンセル", style: UIAlertAction.Style.cancel,
            handler: { action in })
        alertController.addAction(acceptAction)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
        self.present(alertController, animated: true, completion: nil)
    }
}

extension EditBandViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

extension EditBandViewController: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        profileImageView.image = image
        viewModel.didUpdateArtwork(artwork: image)
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

extension EditBandViewController: UIPickerViewDelegate, UIPickerViewDataSource {
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
