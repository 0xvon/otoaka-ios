//
//  CreateBandViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/01.
//

import Endpoint
import Foundation
import UIKit

final class CreateBandViewController: UIViewController, Instantiable {
    typealias Input = Void

    lazy var viewModel = CreateBandViewModel(
        apiClient: dependencyProvider.apiClient,
        s3Bucket: dependencyProvider.s3Bucket,
        outputHander: { output in
            switch output {
            case .create(let group):
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            case .error(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: error.localizedDescription)
                }
            }
        }
    )

    var dependencyProvider: LoggedInDependencyProvider
    var input: Input!
    let hometowns = Components().prefectures
    let years = Components().years

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
    private var registerButton: PrimaryButton!

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
        self.navigationController?.setNavigationBarHidden(false, animated: true)

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
            constant: 1500
        )
        mainView.addConstraint(mainViewHeightConstraint)

        displayNameInputView = TextFieldView(input: (section: "バンド名", text: nil, maxLength: 20))
        displayNameInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(displayNameInputView)

        englishNameInputView = TextFieldView(input: (section: "English Name", text: nil, maxLength: 40))
        englishNameInputView.keyboardType(.alphabet)
        englishNameInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(englishNameInputView)

        biographyInputView = InputTextView(input: (section: "bio", text: nil, maxLength: 200))
        biographyInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(biographyInputView)

        sinceInputView = TextFieldView(input: (section: "結成年", text: nil, maxLength: 20))
        sinceInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(sinceInputView)

        sincePickerView = UIPickerView()
        sincePickerView.translatesAutoresizingMaskIntoConstraints = false
        sincePickerView.dataSource = self
        sincePickerView.delegate = self
        sinceInputView.selectInputView(inputView: sincePickerView)

        hometownInputView = TextFieldView(input: (section: "出身地", text: nil,  maxLength: 20))
        hometownInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(hometownInputView)

        hometownPickerView = UIPickerView()
        hometownPickerView.translatesAutoresizingMaskIntoConstraints = false
        hometownPickerView.dataSource = self
        hometownPickerView.delegate = self
        hometownInputView.selectInputView(inputView: hometownPickerView)
    
        youTubeIdInputView = TextFieldView(input: (section: "YouTube Channel ID(スキップ可)",text: nil,  maxLength: 40))
        youTubeIdInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(youTubeIdInputView)
        
        twitterIdInputView = TextFieldView(input: (section: "Twitter ID(@を省略して入力してください)", text: nil, maxLength: 20))
        twitterIdInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(twitterIdInputView)

        thumbnailInputView = UIView()
        thumbnailInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(thumbnailInputView)

        profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 60
        profileImageView.clipsToBounds = true
        profileImageView.image = UIImage(named: "band")
        profileImageView.contentMode = .scaleAspectFill
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

        registerButton = PrimaryButton(text: "バンド作成")
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        registerButton.layer.cornerRadius = 25
        registerButton.listen {
            self.register()
        }
        mainView.addSubview(registerButton)

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
            displayNameInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),

            englishNameInputView.topAnchor.constraint(
                equalTo: displayNameInputView.bottomAnchor, constant: 48),
            englishNameInputView.rightAnchor.constraint(
                equalTo: mainView.rightAnchor, constant: -16),
            englishNameInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            englishNameInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),

            biographyInputView.topAnchor.constraint(
                equalTo: englishNameInputView.bottomAnchor, constant: 48),
            biographyInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            biographyInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            biographyInputView.heightAnchor.constraint(equalToConstant: 200),

            sinceInputView.topAnchor.constraint(
                equalTo: biographyInputView.bottomAnchor, constant: 48),
            sinceInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            sinceInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            sinceInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),

            hometownInputView.topAnchor.constraint(
                equalTo: sinceInputView.bottomAnchor, constant: 48),
            hometownInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            hometownInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            hometownInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
            
            youTubeIdInputView.topAnchor.constraint(
                equalTo: hometownInputView.bottomAnchor, constant: 48),
            youTubeIdInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            youTubeIdInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            youTubeIdInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
            
            twitterIdInputView.topAnchor.constraint(
                equalTo: youTubeIdInputView.bottomAnchor, constant: 48),
            twitterIdInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            twitterIdInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            twitterIdInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),

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

            registerButton.widthAnchor.constraint(equalToConstant: 300),
            registerButton.heightAnchor.constraint(equalToConstant: 50),
            registerButton.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
            registerButton.topAnchor.constraint(
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

    private func register() {
        guard let groupName = displayNameInputView.getText() else { return }
        guard let groupEnglishName = englishNameInputView.getText() else { return }
        let biography = biographyInputView.getText()
        let artworkImage = profileImageView.image
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        guard let sinceInput = sinceInputView.getText() else { return }
        let since: Date? = dateFormatter.date(from: sinceInput)
        let hometown = hometownInputView.getText()
        let youtubeChannelId = youTubeIdInputView.getText()
        let twitterId = twitterIdInputView.getText()

        viewModel.create(
            name: groupName,
            englishName: groupEnglishName,
            biography: biography,
            since: since,
            artwork: artworkImage,
            youtubeChannelId: youtubeChannelId,
            twitterId: twitterId,
            hometown: hometown
        )
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
            return hometowns[row]
        case self.sincePickerView:
            return years[row]
        default:
            return "yo"
        }
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case self.hometownPickerView:
            return hometowns.count
        case self.sincePickerView:
            return years.count
        default:
            return 1
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case self.hometownPickerView:
            let text = hometowns[row]
            hometownInputView.setText(text: text)
        case self.sincePickerView:
            let text = years[row]
            sinceInputView.setText(text: text)
        default:
            print("hello")
        }
    }
}
