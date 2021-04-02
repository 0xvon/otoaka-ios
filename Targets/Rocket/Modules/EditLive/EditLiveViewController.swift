//
//  EditLiveViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import InternalDomain
import UIKit
import CropViewController

final class EditLiveViewController: UIViewController, Instantiable {
    typealias Input = Live

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
    private lazy var liveTitleInputView: TextFieldView = {
        let liveTitleInputView = TextFieldView(input: (section: "タイトル", text: nil, maxLength: 32))
        liveTitleInputView.translatesAutoresizingMaskIntoConstraints = false
        return liveTitleInputView
    }()
    private lazy var livehouseInputView: TextFieldView = {
        let livehouseInputView = TextFieldView(input: (section: "会場", text: nil, maxLength: 40))
        livehouseInputView.translatesAutoresizingMaskIntoConstraints = false
        return livehouseInputView
    }()
    private lazy var livehousePickerView: UIPickerView = {
        let livehousePickerView = UIPickerView()
        livehousePickerView.translatesAutoresizingMaskIntoConstraints = false
        livehousePickerView.dataSource = self
        livehousePickerView.delegate = self
        return livehousePickerView
    }()
    private lazy var openTimeInputView: DateInputView = {
        let dateInputView = DateInputView(section: "オープン時間")
        dateInputView.translatesAutoresizingMaskIntoConstraints = false
        return dateInputView
    }()
    private lazy var startTimeInputView: DateInputView = {
        let dateInputView = DateInputView(section: "スタート時間")
        dateInputView.translatesAutoresizingMaskIntoConstraints = false
        return dateInputView
    }()
    private lazy var endTimeInputView: DateInputView = {
        let dateInputView = DateInputView(section: "クローズ時間")
        dateInputView.translatesAutoresizingMaskIntoConstraints = false
        return dateInputView
    }()
    private var thumbnailInputView: UIView = {
        let thumbnailInputView = UIView()
        thumbnailInputView.translatesAutoresizingMaskIntoConstraints = false
        
        return thumbnailInputView
    }()
    private lazy var profileImageView: UIImageView = {
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 16
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
        profileImageTitle.text = "サムネイル画像"
        profileImageTitle.textAlignment = .center
        profileImageTitle.font = Brand.font(for: .medium)
        profileImageTitle.textColor = Brand.color(for: .text(.primary))
        return profileImageTitle
    }()
    private lazy var editButton: PrimaryButton = {
        let registerButton = PrimaryButton(text: "ライブ編集")
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        registerButton.layer.cornerRadius = 25
        registerButton.isEnabled = false
        return registerButton
    }()
    private lazy var activityIndicator: LoadingCollectionView = {
        let activityIndicator = LoadingCollectionView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: EditLiveViewModel
    var cancellables: Set<AnyCancellable> = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = EditLiveViewModel(dependencyProvider: dependencyProvider, live: input)

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
    
    func bind() {
        editButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: viewModel.didEditButtonTapped)
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didInject:
                liveTitleInputView.setText(text: viewModel.state.title ?? "")
                livehouseInputView.setText(text: viewModel.state.livehouse ?? "")
                if let liveArtworkURL = viewModel.state.live.artworkURL {
                    dependencyProvider.imagePipeline.loadImage(liveArtworkURL, into: profileImageView)
                } else {
                    profileImageView.image = nil
                }
            case .didEditLive(_):
                self.navigationController?.popViewController(animated: true)
            case .didUpdateDatePickers(let pickerType):
                openTimeInputView.date = viewModel.state.openAt
                startTimeInputView.date = viewModel.state.startAt
                endTimeInputView.date = viewModel.state.endAt
                switch pickerType {
                case .openAt(let openAt):
                    startTimeInputView.maximumDate = openAt
                    endTimeInputView.maximumDate = openAt
                case .startAt(let startAt):
                    endTimeInputView.maximumDate = startAt
                default:
                    break
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
            case .reportError(let error):
                print(error)
                self.showAlert()
            }
        }
        .store(in: &cancellables)
        
        liveTitleInputView.listen { [unowned self] in
            didInputValue()
        }
        
        livehouseInputView.listen { [unowned self] in
            livehouseInputView.setText(text: self.viewModel.state.socialInputs.livehouses[self.livehousePickerView.selectedRow(inComponent: 0)])
            didInputValue()
        }
        
        openTimeInputView.listen { [unowned self] in
            viewModel.didUpdateDatePicker(pickerType: .openAt(openTimeInputView.date))
        }
        
        startTimeInputView.listen { [unowned self] in
            viewModel.didUpdateDatePicker(pickerType: .startAt(startTimeInputView.date))
        }
        
        endTimeInputView.listen { [unowned self] in
            viewModel.didUpdateDatePicker(pickerType: .endAt(endTimeInputView.date))
        }
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.title = "ライブ編集"
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
        
        mainView.addArrangedSubview(liveTitleInputView)
        NSLayoutConstraint.activate([
            liveTitleInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(livehouseInputView)
        livehouseInputView.selectInputView(inputView: livehousePickerView)
        NSLayoutConstraint.activate([
            livehouseInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(openTimeInputView)
        NSLayoutConstraint.activate([
            openTimeInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(startTimeInputView)
        NSLayoutConstraint.activate([
            startTimeInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(endTimeInputView)
        NSLayoutConstraint.activate([
            endTimeInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(thumbnailInputView)
        NSLayoutConstraint.activate([
            thumbnailInputView.heightAnchor.constraint(equalToConstant: 200),
        ])
        
        thumbnailInputView.addSubview(profileImageView)
        NSLayoutConstraint.activate([
            profileImageView.heightAnchor.constraint(equalToConstant: 180),
            profileImageView.topAnchor.constraint(equalTo: thumbnailInputView.topAnchor),
            profileImageView.rightAnchor.constraint(equalTo: thumbnailInputView.rightAnchor),
            profileImageView.leftAnchor.constraint(equalTo: thumbnailInputView.leftAnchor),
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
        
        liveTitleInputView.focus()
    }
    
    private func didInputValue() {
        let title = liveTitleInputView.getText()
        let livehouse = livehouseInputView.getText()
        
        viewModel.didUpdateInputItems(title: title, livehouse: livehouse)
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

extension EditLiveViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

extension EditLiveViewController: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        profileImageView.image = image
        viewModel.didUpdateArtwork(thumbnail: image)
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

extension EditLiveViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
        -> String?
    {
        switch pickerView {
        case self.livehousePickerView:
            return viewModel.state.socialInputs.livehouses[row]
        default:
            return "yo"
        }
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case self.livehousePickerView:
            return viewModel.state.socialInputs.livehouses.count
        default:
            return 1
        }
    }
}
