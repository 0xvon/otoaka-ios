//
//  CreateUserViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/31.
//

import AWSCognitoAuth
import UIKit

final class CreateUserViewController: UIViewController, Instantiable {
    typealias Input = Void
    var dependencyProvider: DependencyProvider
    var input: Input!

    enum SectionType {
        case fan
        case artist
    }

    lazy var viewModel = CreateUserViewModel(
        apiClient: dependencyProvider.apiClient,
        s3Bucket: dependencyProvider.s3Bucket,
        outputHander: { output in
            switch output {
            case .fan(let user):
                DispatchQueue.main.async {
                    let provider = LoggedInDependencyProvider(
                        provider: self.dependencyProvider, user: user)
                    let vc = InvitationViewController(dependencyProvider: provider, input: ())
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            case .artist(let user):
                DispatchQueue.main.async {
                    let provider = LoggedInDependencyProvider(
                        provider: self.dependencyProvider, user: user)
                    let vc = InvitationViewController(dependencyProvider: provider, input: ())
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            case .error(let error):
                print(error)
            }
        }
    )

    @IBOutlet weak var setProfileView: UIView!
    @IBOutlet weak var createUserButtonView: Button!
    @IBOutlet weak var fanSection: UIView!
    @IBOutlet weak var bandSection: UIView!
    @IBOutlet weak var profileInputView: UIView!

    private var nameInputView: TextFieldView!
    private var artistNameInputView: TextFieldView!
    private var partInputView: TextFieldView!
    private var fanInputs: UIView!
    private var partPicker: UIPickerView!
    private var bandInputs: UIView!
    private var profileImageView: UIImageView!
    private var sectionType: SectionType = .fan
    private let parts = Components().parts

    init(dependencyProvider: DependencyProvider, input: Input) {
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
        fanSectionButton.addTarget(
            self, action: #selector(fanSectionButtonTapped(_:)), for: .touchUpInside)
        fanSection.addSubview(fanSectionButton)

        let bandImageView = UIImageView()
        bandImageView.translatesAutoresizingMaskIntoConstraints = false
        bandImageView.image = UIImage(named: "selectedMusicIcon")
        bandSection.addSubview(bandImageView)

        let bandTitleLabel = UILabel()
        bandTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        bandTitleLabel.text = "メンバー"
        bandTitleLabel.font = style.font.regular.get()
        bandTitleLabel.textColor = style.color.main.get()
        bandSection.addSubview(bandTitleLabel)

        let bandSectionButton = UIButton()
        bandSectionButton.translatesAutoresizingMaskIntoConstraints = false
        bandSectionButton.addTarget(
            self, action: #selector(bandSectionButtonTapped(_:)), for: .touchUpInside)
        bandSection.addSubview(bandSectionButton)

        fanInputs = UIView()
        fanInputs.backgroundColor = style.color.background.get()
        fanInputs.translatesAutoresizingMaskIntoConstraints = false
        profileInputView.addSubview(fanInputs)

        nameInputView = TextFieldView(input: (placeholder: "表示名", maxLength: 20))
        nameInputView.translatesAutoresizingMaskIntoConstraints = false
        fanInputs.addSubview(nameInputView)

        bandInputs = UIView()
        bandInputs.backgroundColor = style.color.background.get()
        bandInputs.translatesAutoresizingMaskIntoConstraints = false
        profileInputView.addSubview(bandInputs)

        artistNameInputView = TextFieldView(input: (placeholder: "表示名", maxLength: 20))
        artistNameInputView.translatesAutoresizingMaskIntoConstraints = false
        bandInputs.addSubview(artistNameInputView)

        partInputView = TextFieldView(input: (placeholder: "パート", maxLength: 20))
        partInputView.setText(text: parts[0])
        partInputView.translatesAutoresizingMaskIntoConstraints = false
        bandInputs.addSubview(partInputView)

        partPicker = UIPickerView()
        partPicker.translatesAutoresizingMaskIntoConstraints = false
        partPicker.dataSource = self
        partPicker.delegate = self

        partInputView.selectInputView(inputView: partPicker)

        sectionChanged(section: sectionType)

        profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 60
        profileImageView.clipsToBounds = true
        profileImageView.image = UIImage(named: "band")
        setProfileView.addSubview(profileImageView)

        let changeProfileImageButton = UIButton()
        changeProfileImageButton.translatesAutoresizingMaskIntoConstraints = false
        changeProfileImageButton.addTarget(
            self, action: #selector(selectProfileImage(_:)), for: .touchUpInside)
        setProfileView.addSubview(changeProfileImageButton)

        let profileImageTitle = UILabel()
        profileImageTitle.translatesAutoresizingMaskIntoConstraints = false
        profileImageTitle.text = "プロフィール画像"
        profileImageTitle.textAlignment = .center
        profileImageTitle.font = style.font.regular.get()
        profileImageTitle.textColor = style.color.main.get()
        setProfileView.addSubview(profileImageTitle)

        createUserButtonView.inject(input: (text: "ユーザ作成", image: nil))
        createUserButtonView.listen {
            self.createUser()
        }

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
            artistNameInputView.rightAnchor.constraint(
                equalTo: bandInputs.rightAnchor, constant: -16),
            artistNameInputView.leftAnchor.constraint(equalTo: bandInputs.leftAnchor, constant: 16),
            artistNameInputView.heightAnchor.constraint(equalToConstant: 50),

            partInputView.topAnchor.constraint(
                equalTo: artistNameInputView.bottomAnchor, constant: 32),
            partInputView.rightAnchor.constraint(equalTo: bandInputs.rightAnchor, constant: -16),
            partInputView.leftAnchor.constraint(equalTo: bandInputs.leftAnchor, constant: 16),
            partInputView.heightAnchor.constraint(equalToConstant: 50),

            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            profileImageView.topAnchor.constraint(equalTo: setProfileView.topAnchor),
            profileImageView.rightAnchor.constraint(equalTo: setProfileView.rightAnchor),
            profileImageView.leftAnchor.constraint(equalTo: setProfileView.leftAnchor),

            changeProfileImageButton.widthAnchor.constraint(equalToConstant: 120),
            changeProfileImageButton.heightAnchor.constraint(equalToConstant: 120),
            changeProfileImageButton.topAnchor.constraint(equalTo: setProfileView.topAnchor),
            changeProfileImageButton.rightAnchor.constraint(equalTo: setProfileView.rightAnchor),
            changeProfileImageButton.leftAnchor.constraint(equalTo: setProfileView.leftAnchor),

            profileImageTitle.leftAnchor.constraint(equalTo: setProfileView.leftAnchor),
            profileImageTitle.rightAnchor.constraint(equalTo: setProfileView.rightAnchor),
            profileImageTitle.bottomAnchor.constraint(equalTo: setProfileView.bottomAnchor),
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
        case .artist:
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
        sectionChanged(section: .artist)
    }

    @objc private func selectProfileImage(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }

    private func createUser() {
        switch self.sectionType {
        case .fan:
            let name = nameInputView.getText() ?? ""
            let thumbnail = profileImageView.image
            viewModel.signupAsFan(name: name, thumbnail: thumbnail)
        case .artist:
            let name = artistNameInputView.getText() ?? ""
            let thumbnail = profileImageView.image
            let part = partInputView.getText() ?? ""
            viewModel.signupAsArtist(name: name, thumbnail: thumbnail, part: part)
        }
    }
}

extension CreateUserViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
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

extension CreateUserViewController: UIPickerViewDelegate, UIPickerViewDataSource {
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
