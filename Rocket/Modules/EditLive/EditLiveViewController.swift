//
//  EditLiveViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Endpoint
import UIKit

final class EditLiveViewController: UIViewController, Instantiable {
    typealias Input = Live
    var dependencyProvider: LoggedInDependencyProvider!
    var input: Input!

    private var verticalScrollView: UIScrollView!
    private var mainView: UIView!
    private var mainViewHeightConstraint: NSLayoutConstraint!
    private var liveTitleInputView: TextFieldView!
    private var livehouseInputView: TextFieldView!
    private var livehousePickerView: UIPickerView!
//    private var partnerInputView: TextFieldView!
    private var openTimeInputView: UIDatePicker!
    private var startTimeInputView: UIDatePicker!
    private var endTimeInputView: UIDatePicker!
    private var thumbnailInputView: UIView!
    private var thumbnailImageView: UIImageView!
    private var createButton: Button!

    var livehouses: [String] = Components().livehouses

    var partnerGroups: [Endpoint.Group] = []
    var livehouse: String!
    var thumbnail: UIImage!
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM月dd日 HH:mm"
        return dateFormatter
    }()

    lazy var viewModel = EditLiveViewModel(
        apiClient: dependencyProvider.apiClient,
        live: self.input,
        s3Bucket: dependencyProvider.s3Bucket,
        user: dependencyProvider.user,
        outputHander: { output in
            switch output {
            case .editLive(let live):
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            case .getHostGroups(let groups):
                DispatchQueue.main.async {

                }
            case .error(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: error.localizedDescription)
                }
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
        self.title = "ライブ作成"

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
            constant: 1300
        )
        mainView.addConstraint(mainViewHeightConstraint)

        liveTitleInputView = TextFieldView(input: (section: "タイトル", text: input.title, maxLength: 32))
        liveTitleInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(liveTitleInputView)

        livehouseInputView = TextFieldView(input: (section: "会場", text: input.liveHouse,  maxLength: 40))
        livehouseInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(livehouseInputView)

        livehousePickerView = UIPickerView()
        livehousePickerView.translatesAutoresizingMaskIntoConstraints = false
        livehousePickerView.dataSource = self
        livehousePickerView.delegate = self
        livehouseInputView.selectInputView(inputView: livehousePickerView)

//        partnerInputView = TextFieldView(input: (placeholder: "対バン相手を追加する", maxLength: 20))
//        switch input.style {
//        case .battle(let performers):
//            let text = performers.map { $0.name }.joined(separator: ",")
//            partnerInputView.setText(text: text)
//        default:
//            partnerInputView.setText(text: input.hostGroup.name)
//        }
//        partnerInputView.translatesAutoresizingMaskIntoConstraints = false
//        mainView.addSubview(partnerInputView)
        
        let partnerInputButton = UIButton()
        partnerInputButton.translatesAutoresizingMaskIntoConstraints = false
        partnerInputButton.backgroundColor = .clear
        partnerInputButton.addTarget(self, action: #selector(addPartner(_:)), for: .touchUpInside)
        mainView.addSubview(partnerInputButton)
        

        openTimeInputView = UIDatePicker()
        openTimeInputView.date = input.openAt ?? Date()
        openTimeInputView.translatesAutoresizingMaskIntoConstraints = false
        openTimeInputView.date = input.openAt ?? Date()
        openTimeInputView.datePickerMode = .dateAndTime
        openTimeInputView.addTarget(
            self, action: #selector(openTimeChanged(_:)), for: .valueChanged)
        openTimeInputView.tintColor = style.color.main.get()
        openTimeInputView.backgroundColor = .clear
        mainView.addSubview(openTimeInputView)

        let openTimeLabel = UILabel()
        openTimeLabel.text = "開場時間"
        openTimeLabel.font = style.font.regular.get()
        openTimeLabel.textColor = style.color.main.get()
        openTimeLabel.textAlignment = .center
        openTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(openTimeLabel)

        startTimeInputView = UIDatePicker()
        startTimeInputView.date = input.openAt ?? Date()
        startTimeInputView.translatesAutoresizingMaskIntoConstraints = false
        startTimeInputView.date = input.startAt ?? Date()
        startTimeInputView.datePickerMode = .dateAndTime
        startTimeInputView.addTarget(
            self, action: #selector(startTimeChanged(_:)), for: .valueChanged)
        startTimeInputView.tintColor = style.color.main.get()
        startTimeInputView.backgroundColor = .clear
        mainView.addSubview(startTimeInputView)

        let startTimeLabel = UILabel()
        startTimeLabel.text = "開演時間"
        startTimeLabel.font = style.font.regular.get()
        startTimeLabel.textColor = style.color.main.get()
        startTimeLabel.textAlignment = .center
        startTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(startTimeLabel)

        endTimeInputView = UIDatePicker()
        endTimeInputView.date = input.endAt ?? Date()
        endTimeInputView.translatesAutoresizingMaskIntoConstraints = false
        endTimeInputView.date = input.endAt ?? Date()
        endTimeInputView.datePickerMode = .dateAndTime
        endTimeInputView.addTarget(self, action: #selector(endTimeChanged(_:)), for: .valueChanged)
        endTimeInputView.tintColor = style.color.main.get()
        endTimeInputView.backgroundColor = .clear
        mainView.addSubview(endTimeInputView)

        let endTimeLabel = UILabel()
        endTimeLabel.text = "終演時間"
        endTimeLabel.font = style.font.regular.get()
        endTimeLabel.textColor = style.color.main.get()
        endTimeLabel.textAlignment = .center
        endTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(endTimeLabel)
        
        restrictDatePickers()

        thumbnailInputView = UIView()
        thumbnailInputView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(thumbnailInputView)

        thumbnailImageView = UIImageView()
        thumbnailImageView.loadImageAsynchronously(url: input.artworkURL)
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        self.thumbnail = thumbnailImageView.image
        thumbnailImageView.layer.cornerRadius = 16
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.opacity = 0.6
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.backgroundColor = style.color.subBackground.get()
        thumbnailInputView.addSubview(thumbnailImageView)

        let changeThumbnailButton = UIButton()
        changeThumbnailButton.backgroundColor = .clear
        changeThumbnailButton.translatesAutoresizingMaskIntoConstraints = false
        changeThumbnailButton.layer.cornerRadius = 16
        changeThumbnailButton.addTarget(
            self, action: #selector(changeThumbnail(_:)), for: .touchUpInside)
        thumbnailInputView.addSubview(changeThumbnailButton)

        let thumbnailLabel = UILabel()
        thumbnailLabel.font = style.font.regular.get()
        thumbnailLabel.textColor = style.color.main.get()
        thumbnailLabel.textAlignment = .center
        thumbnailLabel.text = "サムネイル画像"
        thumbnailLabel.translatesAutoresizingMaskIntoConstraints = false
        thumbnailInputView.addSubview(thumbnailLabel)

        createButton = Button(input: (text: "ライブを編集", image: nil))
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.layer.cornerRadius = 18
        createButton.listen {
            self.createLive()
        }
        mainView.addSubview(createButton)

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

            liveTitleInputView.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 16),
            liveTitleInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            liveTitleInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            liveTitleInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),

            livehouseInputView.topAnchor.constraint(
                equalTo: liveTitleInputView.bottomAnchor, constant: 24),
            livehouseInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            livehouseInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            livehouseInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),

//            partnerInputView.topAnchor.constraint(
//                equalTo: livehouseInputView.bottomAnchor, constant: 24),
//            partnerInputView.rightAnchor.constraint(
//                equalTo: mainView.rightAnchor, constant: -16),
//            partnerInputView.leftAnchor.constraint(
//                equalTo: mainView.leftAnchor, constant: 16),
//            partnerInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
//
//            partnerInputButton.topAnchor.constraint(equalTo: partnerInputView.topAnchor),
//            partnerInputButton.bottomAnchor.constraint(equalTo: partnerInputView.bottomAnchor),
//            partnerInputButton.rightAnchor.constraint(equalTo: partnerInputView.rightAnchor),
//            partnerInputButton.leftAnchor.constraint(equalTo: partnerInputView.leftAnchor),

            openTimeLabel.topAnchor.constraint(
                equalTo: livehouseInputView.bottomAnchor, constant: 24),
            openTimeLabel.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            openTimeLabel.heightAnchor.constraint(equalToConstant: textFieldHeight),

            openTimeInputView.topAnchor.constraint(equalTo: openTimeLabel.topAnchor),
            openTimeInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            openTimeInputView.leftAnchor.constraint(
                equalTo: openTimeLabel.rightAnchor, constant: 16),
            openTimeInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),

            startTimeLabel.topAnchor.constraint(
                equalTo: openTimeInputView.bottomAnchor, constant: 24),
            startTimeLabel.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            startTimeLabel.heightAnchor.constraint(equalToConstant: textFieldHeight),

            startTimeInputView.topAnchor.constraint(equalTo: startTimeLabel.topAnchor),
            startTimeInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            startTimeInputView.leftAnchor.constraint(
                equalTo: startTimeLabel.rightAnchor, constant: 16),
            startTimeInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),

            endTimeLabel.topAnchor.constraint(equalTo: startTimeLabel.bottomAnchor, constant: 24),
            endTimeLabel.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            endTimeLabel.heightAnchor.constraint(equalToConstant: textFieldHeight),

            endTimeInputView.topAnchor.constraint(equalTo: endTimeLabel.topAnchor),
            endTimeInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            endTimeInputView.leftAnchor.constraint(equalTo: endTimeLabel.rightAnchor, constant: 16),
            endTimeInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),

            thumbnailInputView.topAnchor.constraint(
                equalTo: endTimeInputView.bottomAnchor, constant: 48),
            thumbnailInputView.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -16),
            thumbnailInputView.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 16),
            thumbnailInputView.heightAnchor.constraint(equalToConstant: 300),

            thumbnailImageView.topAnchor.constraint(equalTo: thumbnailInputView.topAnchor),
            thumbnailImageView.rightAnchor.constraint(equalTo: thumbnailInputView.rightAnchor),
            thumbnailImageView.leftAnchor.constraint(equalTo: thumbnailInputView.leftAnchor),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 250),

            changeThumbnailButton.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor),
            changeThumbnailButton.bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor),
            changeThumbnailButton.rightAnchor.constraint(equalTo: thumbnailImageView.rightAnchor),
            changeThumbnailButton.leftAnchor.constraint(equalTo: thumbnailImageView.leftAnchor),

            thumbnailLabel.bottomAnchor.constraint(equalTo: thumbnailInputView.bottomAnchor),
            thumbnailLabel.rightAnchor.constraint(equalTo: thumbnailInputView.rightAnchor),
            thumbnailLabel.leftAnchor.constraint(equalTo: thumbnailInputView.leftAnchor),
            thumbnailLabel.heightAnchor.constraint(equalToConstant: 50),

            createButton.topAnchor.constraint(
                equalTo: thumbnailInputView.bottomAnchor, constant: 54),
            createButton.widthAnchor.constraint(equalToConstant: 300),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            createButton.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        updatePickerComponents()
    }

    func updatePickerComponents() {
        viewModel.getMyGroups()
    }

    @objc private func addPartner(_ sender: Any) {
        let vc = SelectPerformersViewController(dependencyProvider: dependencyProvider, input: self.partnerGroups)
        vc.listen { groups in
            self.partnerGroups = groups
//            let text = groups.map { $0.name }.joined(separator: ",")
//            self.partnerInputView.setText(text: text)
        }
        present(vc, animated: true, completion: nil)
    }

    @objc private func changeThumbnail(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }

    @objc private func openTimeChanged(_ sender: Any) {
        restrictDatePickers()
    }

    @objc private func startTimeChanged(_ sender: Any) {
        restrictDatePickers()
    }

    @objc private func endTimeChanged(_ sender: Any) {
        restrictDatePickers()
    }
    
    private func restrictDatePickers() {
        openTimeInputView.minimumDate = Date()
        startTimeInputView.minimumDate = openTimeInputView.date
        endTimeInputView.minimumDate = startTimeInputView.date
    }

    func createLive() {
        guard let title: String = liveTitleInputView.getText() else { return }
        guard let livehouse = livehouseInputView.getText() else { return }
        viewModel.editLive(
            title: title, liveId: input.id, livehouse: livehouse, openAt: openTimeInputView.date,
            startAt: startTimeInputView.date, endAt: endTimeInputView.date, thumbnail: self.thumbnail)
    }
}

extension EditLiveViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        thumbnailImageView.image = image
        self.thumbnail = image
        self.dismiss(animated: true, completion: nil)
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
            return livehouses[row]
        default:
            return "yo"
        }
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case self.livehousePickerView:
            return livehouses.count
        default:
            return 1
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case self.livehousePickerView:
            self.livehouseInputView.setText(text: self.livehouses[row])
            self.livehouse = self.livehouses[row]
        default:
            print("hello")
        }
    }
}
