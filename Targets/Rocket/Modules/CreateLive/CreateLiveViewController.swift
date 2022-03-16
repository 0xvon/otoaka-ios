//
//  CreateLiveViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/01/08.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import UIKit
import KeyboardGuide
import CropViewController
import TagListView

final class CreateLiveViewController: UIViewController, Instantiable {
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
    private lazy var titleInputView: TextFieldView = {
        let displayNameInputView = TextFieldView(input: (section: "公演名", text: nil, maxLength: 40))
        displayNameInputView.translatesAutoresizingMaskIntoConstraints = false
        return displayNameInputView
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
        let inputView = TextFieldView(input: (section: "会場", text: nil, maxLength: 20))
        inputView.translatesAutoresizingMaskIntoConstraints = false
        return inputView
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
    private lazy var registerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(Brand.color(for: .brand(.primary)), for: .normal)
        button.setTitleColor(Brand.color(for: .background(.light)), for: .disabled)
        button.setTitleColor(Brand.color(for: .brand(.primary)), for: .highlighted)
        button.setTitle("作成", for: .normal)
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
    let viewModel: CreateLiveViewModel
    var cancellables: Set<AnyCancellable> = []
    
    private var listener: () -> Void = {}
    func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = CreateLiveViewModel(dependencyProvider: dependencyProvider)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
        updatePerformerTag()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    func bind() {
        registerButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: { [viewModel] in viewModel.didRegisterButtonTapped() } )
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didCreateLive(_):
                navigationController?.popViewController(animated: true)
            case .updateSubmittableState(let state):
                switch state {
                case .editting(let submittable):
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: registerButton)
                    self.registerButton.isEnabled = submittable
                    updatePerformerTag()
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
        
        titleInputView.listen { [unowned self] in
            self.didInputValue()
        }
        
        liveStyleInputView.listen { [unowned self] in
            liveStyleInputView.setText(text: viewModel.state.socialInputs.liveStyles[liveStylePickerView.selectedRow(inComponent: 0)])
            didInputValue()
        }
        
        livehouseInputView.listen { [ unowned self] in
            self.didInputValue()
        }
        
        dateInputView.listen { [unowned self] in
//            sexInputView.setText(text: viewModel.state.socialInputs.sex[sexPickerView.selectedRow(inComponent: 0)])
            self.didInputValue()
        }
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.title = "ライブ作成"
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
        
        mainView.addArrangedSubview(titleInputView)
        NSLayoutConstraint.activate([
            titleInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
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
        
        let bottomSpacer = UIView()
        mainView.addArrangedSubview(bottomSpacer) // Spacer
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        titleInputView.focus()
    }

    private func didInputValue() {
        let title = titleInputView.getText()
        let style = liveStyleInputView.getText()
        let livehouse =  livehouseInputView.getText()
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

extension CreateLiveViewController: TagListViewDelegate {
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

extension CreateLiveViewController: UIPickerViewDelegate, UIPickerViewDataSource {
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
