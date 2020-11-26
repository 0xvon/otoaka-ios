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
                print(error)
            }
        }
    )

    var dependencyProvider: LoggedInDependencyProvider
    var input: Input!
    let hometowns = Components().prefectures
    let years = Components().years

    @IBOutlet weak var groupNameInputView: TextFieldView!
    @IBOutlet weak var groupEnglishNameInputView: TextFieldView!
    @IBOutlet weak var biographyInputView: InputTextView!
    @IBOutlet weak var sinceInputView: TextFieldView!
    @IBOutlet weak var hometownInputView: TextFieldView!
    @IBOutlet weak var artworkInputView: UIView!
    @IBOutlet weak var registerButton: Button!

    private var profileImageView: UIImageView!
    private var hometownPicker: UIPickerView!
    private var yearPicker: UIPickerView!

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

        groupNameInputView.inject(input: (placeholder: "バンド名", maxLength: 20))
        groupEnglishNameInputView.inject(input: (placeholder: "English Name", maxLength: 40))
        sinceInputView.inject(input: (placeholder: "結成年", maxLength: 12))
        yearPicker = UIPickerView()
        yearPicker.translatesAutoresizingMaskIntoConstraints = false
        yearPicker.dataSource = self
        yearPicker.delegate = self
        sinceInputView.selectInputView(inputView: yearPicker)
        hometownInputView.inject(input: (placeholder: "出身地", maxLength: 12))
        hometownPicker = UIPickerView()
        hometownPicker.translatesAutoresizingMaskIntoConstraints = false
        hometownPicker.dataSource = self
        hometownPicker.delegate = self
        hometownInputView.selectInputView(inputView: hometownPicker)

        profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 60
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.image = UIImage(named: "band")
        artworkInputView.addSubview(profileImageView)

        biographyInputView.inject(input: (text: "bio", maxLength: 200))

        let changeProfileImageButton = UIButton()
        changeProfileImageButton.translatesAutoresizingMaskIntoConstraints = false
        changeProfileImageButton.addTarget(
            self, action: #selector(selectProfileImage(_:)), for: .touchUpInside)
        artworkInputView.addSubview(changeProfileImageButton)

        let profileImageTitle = UILabel()
        profileImageTitle.translatesAutoresizingMaskIntoConstraints = false
        profileImageTitle.text = "プロフィール画像"
        profileImageTitle.textAlignment = .center
        profileImageTitle.font = style.font.regular.get()
        profileImageTitle.textColor = style.color.main.get()
        artworkInputView.addSubview(profileImageTitle)

        registerButton.inject(input: (text: "バンドを作成", image: nil))
        registerButton.listen {
            self.register()
        }

        let constraints = [
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            profileImageView.topAnchor.constraint(equalTo: artworkInputView.topAnchor),
            profileImageView.rightAnchor.constraint(equalTo: artworkInputView.rightAnchor),
            profileImageView.leftAnchor.constraint(equalTo: artworkInputView.leftAnchor),

            changeProfileImageButton.widthAnchor.constraint(equalToConstant: 120),
            changeProfileImageButton.heightAnchor.constraint(equalToConstant: 120),
            changeProfileImageButton.topAnchor.constraint(equalTo: artworkInputView.topAnchor),
            changeProfileImageButton.rightAnchor.constraint(equalTo: artworkInputView.rightAnchor),
            changeProfileImageButton.leftAnchor.constraint(equalTo: artworkInputView.leftAnchor),

            profileImageTitle.leftAnchor.constraint(equalTo: artworkInputView.leftAnchor),
            profileImageTitle.rightAnchor.constraint(equalTo: artworkInputView.rightAnchor),
            profileImageTitle.bottomAnchor.constraint(equalTo: artworkInputView.bottomAnchor),
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
        guard let groupName = groupNameInputView.getText() else { return }
        guard let groupEnglishName = groupEnglishNameInputView.getText() else { return }
        let biography = biographyInputView.getText()
        let artworkImage = profileImageView.image
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        guard let sinceInput = sinceInputView.getText() else { return }
        let since: Date? = dateFormatter.date(from: sinceInput)
        let hometown = hometownInputView.getText()

        viewModel.create(
            name: groupName,
            englishName: groupEnglishName,
            biography: biography,
            since: since,
            artwork: artworkImage,
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
        case self.hometownPicker:
            return hometowns[row]
        case self.yearPicker:
            return years[row]
        default:
            return "yo"
        }
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case self.hometownPicker:
            return hometowns.count
        case self.yearPicker:
            return years.count
        default:
            return 1
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case self.hometownPicker:
            let text = hometowns[row]
            hometownInputView.setText(text: text)
        case self.yearPicker:
            let text = years[row]
            sinceInputView.setText(text: text)
        default:
            print("hello")
        }
    }
}
