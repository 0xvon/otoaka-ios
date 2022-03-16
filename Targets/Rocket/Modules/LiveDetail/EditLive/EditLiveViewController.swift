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
import TagListView

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
    private lazy var liveStyleInputView: TextFieldView = {
        let inputView = TextFieldView(input: (section: "形式", text: nil, maxLength: 32))
        inputView.translatesAutoresizingMaskIntoConstraints = false
        return inputView
    }()
    private lazy var liveStylePickerView: UIPickerView = {
        let sincePickerView = UIPickerView()
        sincePickerView.translatesAutoresizingMaskIntoConstraints = false
        sincePickerView.dataSource = self
        sincePickerView.delegate = self
        return sincePickerView
    }()
    private lazy var livehouseInputView: TextFieldView = {
        let livehouseInputView = TextFieldView(input: (section: "会場", text: nil, maxLength: 40))
        livehouseInputView.translatesAutoresizingMaskIntoConstraints = false
        return livehouseInputView
    }()
    private lazy var dateInputView: TextFieldView = {
        let displayNameInputView = TextFieldView(input: (section: "公演日", text: nil, maxLength: 20))
        displayNameInputView.translatesAutoresizingMaskIntoConstraints = false
        return displayNameInputView
    }()
    private lazy var datePickerView: UIDatePicker = {
        let datePicker = UIDatePicker()
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerMode = .date
        
        datePicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        
        return datePicker
    }()
    private lazy var performersWrapper: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        
        view.addSubview(performersTitle)
        NSLayoutConstraint.activate([
            performersTitle.heightAnchor.constraint(equalToConstant: 24),
            performersTitle.leftAnchor.constraint(equalTo: view.leftAnchor),
            performersTitle.topAnchor.constraint(equalTo: view.topAnchor),
            performersTitle.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        view.addSubview(performersListView)
        NSLayoutConstraint.activate([
            performersListView.topAnchor.constraint(equalTo: performersTitle.bottomAnchor, constant: 8),
            performersListView.leftAnchor.constraint(equalTo: performersTitle.leftAnchor),
            performersListView.rightAnchor.constraint(equalTo: performersTitle.rightAnchor),
            performersListView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        return view
    }()
    private lazy var performersTitle: UILabel = {
        let section = UILabel()
        section.translatesAutoresizingMaskIntoConstraints = false
        section.text = "出演者"
        section.font = Brand.font(for: .medium)
        section.textColor = Brand.color(for: .brand(.primary))
        return section
    }()
    private lazy var performersListView: TagListView = {
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
                liveStyleInputView.setText(text: viewModel.state.style.rawValue)
                livehouseInputView.setText(text: viewModel.state.livehouse ?? "")
                dateInputView.setText(text: viewModel.state.date ?? "")
                updatePerformerTag()
            case .didEditLive(_):
                self.navigationController?.popViewController(animated: true)
            case .updateSubmittableState(let state):
                switch state {
                case .editting(let submittable):
                    self.activityIndicator.stopAnimating()
                    self.editButton.isEnabled = submittable
                    updatePerformerTag()
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
        
        liveStyleInputView.listen { [unowned self] in
            liveStyleInputView.setText(text: viewModel.state.socialInputs.liveStyles[liveStylePickerView.selectedRow(inComponent: 0)])
            didInputValue()
        }
        
        livehouseInputView.listen { [unowned self] in
            didInputValue()
        }
        
        dateInputView.listen { [unowned self] in
            self.didInputValue()
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
        
        mainView.addArrangedSubview(liveStyleInputView)
        liveStyleInputView.selectInputView(inputView: liveStylePickerView)
        NSLayoutConstraint.activate([
            liveStyleInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(livehouseInputView)
        NSLayoutConstraint.activate([
            livehouseInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(dateInputView)
        dateInputView.selectInputView(inputView: datePickerView)
        NSLayoutConstraint.activate([
            dateInputView.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        mainView.addArrangedSubview(performersWrapper)
        
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
        let style = liveStyleInputView.getText()
        let livehouse = livehouseInputView.getText()
        let date = dateInputView.getText()
        
        viewModel.didUpdateInputItems(title: title, style: style, livehouse: livehouse, date: date)
    }
    
    private func updatePerformerTag() {
        performersListView.removeAllTags()
        performersListView.addTags(viewModel.state.performers.map { $0.name + " ✗" })
        
        let plusTag = performersListView.addTag("追加＋")
        plusTag.borderColor = Brand.color(for: .background(.light))
        plusTag.textColor = Brand.color(for: .background(.light))
        plusTag.borderWidth = 1
        plusTag.tagBackgroundColor = .clear
    }
    
    @objc private func datePickerValueChanged() {
        let date = datePickerView.date.toFormatString(format: "yyyyMMdd")
        dateInputView.setText(text: date)
        didInputValue()
    }
}

extension EditLiveViewController: TagListViewDelegate {
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

extension EditLiveViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return viewModel.state.socialInputs.liveStyles[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel.state.socialInputs.liveStyles.count
    }
}
