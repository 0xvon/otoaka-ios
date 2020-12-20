//
//  EditGroupViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Endpoint
import UIKit

final class EditBandViewController: UIViewController, Instantiable {
    typealias Input = Group
    var input: Input
    var dependencyProvider: LoggedInDependencyProvider!
    var years = Components().years
    var hometowns = Components().prefectures
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        return dateFormatter
    }()

    private var verticalScrollView: UIScrollView!
    private var mainView: UIView!
    private var mainViewHeightConstraint: NSLayoutConstraint!
    private var displayNameInputView: TextFieldView!
    private var englishNameInputView: TextFieldView!
    private var biographyInputView: InputTextView!
    private var sinceInputView: TextFieldView!
    private var sincePickerView: UIPickerView!
    private var hometownInputView: TextFieldView!
    private var hometownPickerView: UIPickerView!
    private var youTubeIdInputView: TextFieldView!
    private var twitterIdInputView: TextFieldView!
    private var thumbnailInputView: UIView!
    private var profileImageView: UIImageView!
    private var updateButton: Button!

    lazy var viewModel = EditBandViewModel(
        apiClient: dependencyProvider.apiClient,
        s3Bucket: dependencyProvider.s3Bucket,
        user: dependencyProvider.user,
        outputHander: { output in
            switch output {
            case .editGroup(let group):
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            case .error(let error):
                print(error)
            }
        }
    )

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input

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
            constant: 1200
        )
        mainView.addConstraint(mainViewHeightConstraint)

        displayNameInputView = TextFieldView(input: (placeholder:"バンド名", maxLength: 20))
        displayNameInputView.translatesAutoresizingMaskIntoConstraints = false
        displayNameInputView.setText(text: input.name)
        mainView.addSubview(displayNameInputView)

        englishNameInputView = TextFieldView(input: (placeholder:"English Name", maxLength: 40))
        englishNameInputView.keyboardType(true)
        englishNameInputView.translatesAutoresizingMaskIntoConstraints = false
        englishNameInputView.setText(text: input.name)
        mainView.addSubview(englishNameInputView)

        biographyInputView = InputTextView(input: (text: input.biography ?? "bio", maxLength: 200))
        biographyInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(biographyInputView)

        sinceInputView = TextFieldView(input: (placeholder: "結成年", maxLength: 20))
        sinceInputView.translatesAutoresizingMaskIntoConstraints = false
        sinceInputView.setText(text: dateFormatter.string(from: input.since ?? Date()))
        mainView.addSubview(sinceInputView)

        sincePickerView = UIPickerView()
        sincePickerView.translatesAutoresizingMaskIntoConstraints = false
        sincePickerView.dataSource = self
        sincePickerView.delegate = self
        sinceInputView.selectInputView(inputView: sincePickerView)

        hometownInputView = TextFieldView(input: (placeholder: "出身地", maxLength: 20))
        hometownInputView.setText(text: input.hometown!)
        hometownInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(hometownInputView)

        hometownPickerView = UIPickerView()
        hometownPickerView.translatesAutoresizingMaskIntoConstraints = false
        hometownPickerView.dataSource = self
        hometownPickerView.delegate = self
        hometownInputView.selectInputView(inputView: hometownPickerView)
    
        youTubeIdInputView = TextFieldView(input: (placeholder: "YouTube Channel ID(スキップ可)", maxLength: 40))
        youTubeIdInputView.translatesAutoresizingMaskIntoConstraints = false
        youTubeIdInputView.setText(text: input.youtubeChannelId ?? "")
        mainView.addSubview(youTubeIdInputView)
        
        twitterIdInputView = TextFieldView(input: (placeholder: "Twitter ID(@を省略して入力してください)", maxLength: 20))
        twitterIdInputView.translatesAutoresizingMaskIntoConstraints = false
        twitterIdInputView.setText(text: input.twitterId ?? "")
        mainView.addSubview(twitterIdInputView)

        thumbnailInputView = UIView()
        thumbnailInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(thumbnailInputView)

        profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 60
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        if let thumbnail = input.artworkURL {
            profileImageView.loadImageAsynchronously(url: thumbnail)
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

        updateButton = Button(input: (text: "バンド更新", image: nil))
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

            englishNameInputView.topAnchor.constraint(
                equalTo: displayNameInputView.bottomAnchor, constant: 48),
            englishNameInputView.rightAnchor.constraint(
                equalTo: mainView.rightAnchor, constant: -16),
            englishNameInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            englishNameInputView.heightAnchor.constraint(equalToConstant: 50),

            biographyInputView.topAnchor.constraint(
                equalTo: englishNameInputView.bottomAnchor, constant: 48),
            biographyInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            biographyInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            biographyInputView.heightAnchor.constraint(equalToConstant: 200),

            sinceInputView.topAnchor.constraint(
                equalTo: biographyInputView.bottomAnchor, constant: 48),
            sinceInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            sinceInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            sinceInputView.heightAnchor.constraint(equalToConstant: 50),

            hometownInputView.topAnchor.constraint(
                equalTo: sinceInputView.bottomAnchor, constant: 48),
            hometownInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            hometownInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            hometownInputView.heightAnchor.constraint(equalToConstant: 50),
            
            youTubeIdInputView.topAnchor.constraint(
                equalTo: hometownInputView.bottomAnchor, constant: 48),
            youTubeIdInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            youTubeIdInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            youTubeIdInputView.heightAnchor.constraint(equalToConstant: 50),
            
            twitterIdInputView.topAnchor.constraint(
                equalTo: youTubeIdInputView.bottomAnchor, constant: 48),
            twitterIdInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            twitterIdInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            twitterIdInputView.heightAnchor.constraint(equalToConstant: 50),

            thumbnailInputView.widthAnchor.constraint(equalToConstant: 120),
            thumbnailInputView.heightAnchor.constraint(equalToConstant: 150),
            thumbnailInputView.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
            thumbnailInputView.topAnchor.constraint(
                equalTo: twitterIdInputView.bottomAnchor, constant: 48),

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
        let englishName = englishNameInputView.getText() ?? ""
        let biography = biographyInputView.getText()
        let thumbnail = profileImageView.image
        let hometown = hometownInputView.getText()
        let since = dateFormatter.date(from: sinceInputView.getText()!)
        let youtubeChannelId = youTubeIdInputView.getText()
        let twitterId = twitterIdInputView.getText()

        viewModel.editGroup(
            id: input.id, name: displayName, englishName: englishName, biography: biography,
            since: since,
            thumbnail: thumbnail, youtubeChannelId: youtubeChannelId, twitterId: twitterId, hometown: hometown)
    }
}

extension EditBandViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

extension EditBandViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case self.sincePickerView:
            return self.years.count
        case self.hometownPickerView:
            return self.hometowns.count
        default:
            return 1
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
        -> String?
    {
        switch pickerView {
        case self.sincePickerView:
            return self.years[row]
        case self.hometownPickerView:
            return self.hometowns[row]
        default:
            return "aaa"
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case self.sincePickerView:
            sinceInputView.setText(text: self.years[row])
        case self.hometownPickerView:
            hometownInputView.setText(text: self.hometowns[row])
        default:
            print("yo")
        }
    }
}
