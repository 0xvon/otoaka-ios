//
//  EditAccountViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Endpoint
import UIKit

final class EditAccountViewController: UIViewController, Instantiable {
    typealias Input = Void
    var dependencyProvider: LoggedInDependencyProvider!
    var parts = Components().parts

    private var verticalScrollView: UIScrollView!
    private var mainView: UIView!
    private var mainViewHeightConstraint: NSLayoutConstraint!
    private var displayNameInputView: TextFieldView!
    private var biographyInputView: InputTextView!
    private var thumbnailInputView: UIView!
    private var profileImageView: UIImageView!
    private var partInputView: TextFieldView!
    private var updateButton: Button!

    lazy var viewModel = EditAccountViewModel(
        apiClient: dependencyProvider.apiClient,
        s3Bucket: dependencyProvider.s3Bucket,
        user: dependencyProvider.user,
        outputHander: { output in
            switch output {
            case .editAccount(let user):
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            case .error(let error):
                print(error)
            }
        }
    )

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider

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
        self.view.backgroundColor = style.color.background.get()

        verticalScrollView = UIScrollView()
        verticalScrollView.translatesAutoresizingMaskIntoConstraints = false
        verticalScrollView.backgroundColor = .clear
        verticalScrollView.showsVerticalScrollIndicator = false
        self.view.addSubview(verticalScrollView)

        mainView = UIView()
        mainView.translatesAutoresizingMaskIntoConstraints = false
        mainView.backgroundColor = style.color.background.get()
        verticalScrollView.addSubview(mainView)

        mainViewHeightConstraint = NSLayoutConstraint(
            item: mainView!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1,
            constant: 1000
        )
        mainView.addConstraint(mainViewHeightConstraint)

        displayNameInputView = TextFieldView(input: (placeholder: "表示名", maxLength: 20))
        displayNameInputView.translatesAutoresizingMaskIntoConstraints = false
        displayNameInputView.setText(text: dependencyProvider.user.name)
        mainView.addSubview(displayNameInputView)

        biographyInputView = InputTextView(input: (text: dependencyProvider.user.biography ?? "bio", maxLength: 200) )
        biographyInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(biographyInputView)

        setupPartInput()

        thumbnailInputView = UIView()
        thumbnailInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(thumbnailInputView)

        profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 60
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        if let thumbnail = dependencyProvider.user.thumbnailURL {
            profileImageView.loadImageAsynchronously(url: URL(string: thumbnail))
        }
        thumbnailInputView.addSubview(profileImageView)

        let changeProfileImageButton = UIButton()
        changeProfileImageButton.translatesAutoresizingMaskIntoConstraints = false
        changeProfileImageButton.addTarget(
            self, action: #selector(selectProfileImage(_:)), for: .touchUpInside)
        thumbnailInputView.addSubview(changeProfileImageButton)

        let profileImageTitle = UILabel()
        profileImageTitle.translatesAutoresizingMaskIntoConstraints = false
        profileImageTitle.text = "プロフィール画像"
        profileImageTitle.textAlignment = .center
        profileImageTitle.font = style.font.regular.get()
        profileImageTitle.textColor = style.color.main.get()
        thumbnailInputView.addSubview(profileImageTitle)

        updateButton = Button(input: (text: "プロフィール更新", image: nil))
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        updateButton.layer.cornerRadius = 25
        updateButton.listen {
            self.updateProfile()
        }
        mainView.addSubview(updateButton)

        let constraints: [NSLayoutConstraint] = [
            verticalScrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            verticalScrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            verticalScrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            verticalScrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor),

            mainView.topAnchor.constraint(equalTo: verticalScrollView.topAnchor),
            mainView.bottomAnchor.constraint(equalTo: verticalScrollView.bottomAnchor),
            mainView.rightAnchor.constraint(equalTo: verticalScrollView.rightAnchor),
            mainView.leftAnchor.constraint(equalTo: verticalScrollView.leftAnchor),
            mainView.centerXAnchor.constraint(equalTo: verticalScrollView.centerXAnchor),

            displayNameInputView.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 48),
            displayNameInputView.rightAnchor.constraint(
                equalTo: mainView.rightAnchor, constant: -16),
            displayNameInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            displayNameInputView.heightAnchor.constraint(equalToConstant: 50),

            biographyInputView.topAnchor.constraint(
                equalTo: displayNameInputView.bottomAnchor, constant: 32),
            biographyInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            biographyInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            biographyInputView.heightAnchor.constraint(equalToConstant: 200),

            thumbnailInputView.widthAnchor.constraint(equalToConstant: 120),
            thumbnailInputView.heightAnchor.constraint(equalToConstant: 150),
            thumbnailInputView.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
            thumbnailInputView.topAnchor.constraint(
                equalTo: (partInputView != nil)
                    ? partInputView.bottomAnchor : biographyInputView.bottomAnchor, constant: 48),

            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            profileImageView.topAnchor.constraint(equalTo: thumbnailInputView.topAnchor),
            profileImageView.rightAnchor.constraint(equalTo: thumbnailInputView.rightAnchor),
            profileImageView.leftAnchor.constraint(equalTo: thumbnailInputView.leftAnchor),

            changeProfileImageButton.widthAnchor.constraint(equalToConstant: 120),
            changeProfileImageButton.heightAnchor.constraint(equalToConstant: 120),
            changeProfileImageButton.topAnchor.constraint(equalTo: thumbnailInputView.topAnchor),
            changeProfileImageButton.rightAnchor.constraint(
                equalTo: thumbnailInputView.rightAnchor),
            changeProfileImageButton.leftAnchor.constraint(equalTo: thumbnailInputView.leftAnchor),

            profileImageTitle.leftAnchor.constraint(equalTo: thumbnailInputView.leftAnchor),
            profileImageTitle.rightAnchor.constraint(equalTo: thumbnailInputView.rightAnchor),
            profileImageTitle.bottomAnchor.constraint(equalTo: thumbnailInputView.bottomAnchor),

            updateButton.widthAnchor.constraint(equalToConstant: 300),
            updateButton.heightAnchor.constraint(equalToConstant: 50),
            updateButton.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
            updateButton.topAnchor.constraint(
                equalTo: thumbnailInputView.bottomAnchor, constant: 54),

        ]
        NSLayoutConstraint.activate(constraints)
    }

    func setupPartInput() {
        switch dependencyProvider.user.role {
        case .artist(let artist):
            partInputView = TextFieldView(input: (placeholder:"パート", maxLength: 20))
            partInputView.translatesAutoresizingMaskIntoConstraints = false
            partInputView.setText(text: artist.part)
            mainView.addSubview(partInputView)

            let partPicker = UIPickerView()
            partPicker.translatesAutoresizingMaskIntoConstraints = false
            partPicker.dataSource = self
            partPicker.delegate = self
            partInputView.selectInputView(inputView: partPicker)

            let constraints = [
                partInputView.topAnchor.constraint(
                    equalTo: biographyInputView.bottomAnchor, constant: 48),
                partInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
                partInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
                partInputView.heightAnchor.constraint(equalToConstant: 50),
            ]
            NSLayoutConstraint.activate(constraints)
        case .fan(_):
            partInputView = nil
        }
    }

    @objc private func selectProfileImage(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }

    private func updateProfile() {
        let displayName = displayNameInputView.getText() ?? ""
        let biography = biographyInputView.getText()
        let thumbnail = profileImageView.image
        switch dependencyProvider.user.role {
        case .artist(_):
            let part = partInputView.getText()!
            viewModel.editAccount(
                id: dependencyProvider.user.id, name: displayName, biography: biography,
                thumbnail: thumbnail, role: .artist(Artist(part: part)))
        case .fan(_):
            viewModel.editAccount(
                id: dependencyProvider.user.id, name: displayName, biography: biography,
                thumbnail: thumbnail, role: .fan(Fan()))
        }
    }
}

extension EditAccountViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        profileImageView.image = image
        self.dismiss(animated: true, completion: nil)
    }
}

extension EditAccountViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.parts.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
        -> String?
    {
        return self.parts[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let text = self.parts[row]
        partInputView.setText(text: text)
    }
}
