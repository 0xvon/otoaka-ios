//
//  PaymentSocialTipViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/12/30.
//

import Combine
import UIKit
import UIComponent
import Endpoint
import KeyboardGuide
import UITextView_Placeholder
import TagListView
import SCLAlertView
import StoreKit
import Instructions

final class PaymentSocialTipViewController: UIViewController, Instantiable {
    typealias Input = PaymentSocialTipViewModel.Input
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    private lazy var banner: BannerCellContent = {
        let content = BannerCellContent()
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()
    private lazy var scrollStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = Brand.color(for: .background(.primary))
        stackView.axis = .vertical
        stackView.spacing = 16
        
        stackView.addArrangedSubview(textView)
        NSLayoutConstraint.activate([
            textView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            textView.heightAnchor.constraint(equalToConstant: 120),
        ])
        
        stackView.addArrangedSubview(templateMessageList)
        NSLayoutConstraint.activate([
            templateMessageList.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(tipLabel)
        NSLayoutConstraint.activate([
            tipLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            tipLabel.heightAnchor.constraint(equalToConstant: 60),
        ])
        
        stackView.addArrangedSubview(templateTipList)
        NSLayoutConstraint.activate([
            templateTipList.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(pointStackView)
        NSLayoutConstraint.activate([
            pointStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            pointStackView.heightAnchor.constraint(equalToConstant: 40),
        ])
        
        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(bottomSpacer)
        NSLayoutConstraint.activate([
            bottomSpacer.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            bottomSpacer.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        return stackView
    }()
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = ""
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.placeholder = "応援メッセージを贈ろう"
        textView.text = "いつも素敵な音楽をありがとう！"
        textView.placeholderTextView.textAlignment = .left
        textView.placeholderColor = Brand.color(for: .background(.secondary))
        textView.font = Brand.font(for: .mediumStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .left
        textView.layer.cornerRadius = 16
        textView.layer.borderColor = Brand.color(for: .brand(.primary)).cgColor
        textView.layer.borderWidth = 2
        textView.returnKeyType = .done
        return textView
    }()
    private lazy var templateMessageList: TagListView = {
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
    private lazy var tipLabel: TextFieldView = {
        let view = TextFieldView(input: (
            section: "金額",
            text: "0",
            maxLength: 5
        ))
        view.isUserInteractionEnabled = false
        view.keyboardType(.numberPad)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var templateTipList: TagListView = {
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
    private lazy var pointStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        
        stackView.addArrangedSubview(pointLabel)
        stackView.addArrangedSubview(switchButton)
        return stackView
    }()
    private lazy var pointLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var switchButton: UISwitch = {
        let switchButton = UISwitch()
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.onTintColor = Brand.color(for: .brand(.primary))
        return switchButton
    }()
    private lazy var registerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(Brand.color(for: .brand(.primary)), for: .normal)
        button.setTitleColor(Brand.color(for: .background(.secondary)), for: .disabled)
        button.setTitleColor(Brand.color(for: .brand(.primary)), for: .highlighted)
        button.setTitle("送る", for: .normal)
        button.titleLabel?.font = Brand.font(for: .mediumStrong)
        button.isEnabled = true
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
    
    private let coachMarksController = CoachMarksController()
    private lazy var coachSteps: [CoachStep] = [
        CoachStep(view: textView, hint: "snackするときにcardも送ることができるよ！", next: "ok"),
        CoachStep(view: templateTipList, hint: "snackの金額はここから選択してね！", next: "ok"),
        CoachStep(view: switchButton, hint: "snackは自分のポイントかApple Payから送ることができるよ！ポイントはアプリの色んなところで貯められるよ！", next: "ok"),
        CoachStep(view: registerButton, hint: "snackとcardを設定したら送ろう！", next: "ok"),
    ]
    
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: PaymentSocialTipViewModel
    let pointViewModel: PointViewModel
    var cancellables: Set<AnyCancellable> = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = PaymentSocialTipViewModel(dependencyProvider: dependencyProvider, input: input)
        self.pointViewModel = PointViewModel(dependencyProvider: dependencyProvider)
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if PRODUCTION
        let userDefaults = UserDefaults.standard
        let key = "PaymentSocialTipVCPresented_v3.2.0.r"
        if !userDefaults.bool(forKey: key) {
            coachMarksController.start(in: .currentWindow(of: self))
            userDefaults.setValue(true, forKey: key)
            userDefaults.synchronize()
        }
        #else
        coachMarksController.start(in: .currentWindow(of: self))
        #endif
    }
    
    private func bind() {
        pointViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .usePoint(_):
                viewModel.sendTipButtonTapped()
            case .addPoint(_): break
            case .reportError(let err):
                print(String(describing: err))
                showAlert(
                    title: "ポイント不足",
                    message: "ポイントが足りませんでした！シェアボタンからツイッターでシェアしてポイントを貯めよう！"
                )
            }
        }
        .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didGetProducts(let products):
                guard let defaultTip = products.first?.price.intValue else { return }
                templateTipList.addTags(products.map { String($0.price.intValue) })
                tipLabel.setText(text: String(defaultTip))
                viewModel.didUpdateTip(tip: defaultTip)
            case .didGetMyPoint(let point):
                pointLabel.text = "ポイントを使う(\(point)pt)"
            case .updateSubmittableState(let state):
                switch state {
                case .loading:
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
                    self.activityIndicator.startAnimating()
                case .editting(let submittable):
                    self.registerButton.isHidden = !submittable
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: registerButton)
                    self.activityIndicator.stopAnimating()
                }
            case .didSendSocialTip(let tip): showSuccessPopup(tip: tip)
            case .reportError(let err):
                print(String(describing: err))
                showAlert()
            case .failedToPay(let err):
                print(String(describing: err))
                showAlert(title: "決済失敗", message: "支払いに失敗しました")
            }
        }
        .store(in: &cancellables)
        
        tipLabel.listen { [unowned self] in
            guard let text = tipLabel.getText() else { return }
            viewModel.didUpdateTip(tip: Int(text) ?? 0)
        }
        
        switchButton.addTarget(self, action: #selector(switchButtonTapped), for: .touchUpInside)
        
        registerButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
    }
    
    private func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.title = "チップを送る"
        coachMarksController.dataSource = self
        coachMarksController.delegate = self
        
        self.view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.view.keyboardSafeArea.layoutGuide.topAnchor),
            scrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            scrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardSafeArea.layoutGuide.bottomAnchor),
        ])
        
        scrollView.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            banner.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            banner.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            banner.heightAnchor.constraint(equalToConstant: 100),
            banner.topAnchor.constraint(equalTo: scrollView.topAnchor),
        ])
        
        scrollView.addSubview(scrollStackView)
        NSLayoutConstraint.activate([
            scrollStackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 16),
            scrollStackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -16),
            scrollStackView.topAnchor.constraint(equalTo: banner.bottomAnchor, constant: 16),
            scrollStackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            scrollStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: registerButton)
        
        templateMessageList.addTags([
            "応援してます！",
            "大好きです！",
        ])
        
//        templateTipList.addTags([
//            "1000",
//            "2000",
//            "5000",
//            "10000",
//        ])
        
        switch viewModel.state.type {
        case .group(let group):
            banner.inject(input: (
                artworkURL: group.artworkURL,
                title: group.name,
                imagePipeline: dependencyProvider.imagePipeline
            ))
        case .live(let live):
            banner.inject(input: (
                artworkURL: live.artworkURL ?? live.hostGroup.artworkURL,
                title: live.title,
                imagePipeline: dependencyProvider.imagePipeline
            ))
        }
    }
    
    @objc private func switchButtonTapped() {
        viewModel.didUpdatePaymentMethod(isRealMoney: !switchButton.isOn)
    }
    
    @objc private func sendButtonTapped() {
        switch viewModel.state.type {
        case .group(let group):
            // entryしていないgroupにはポイントしか送れない
            if !group.isEntried && viewModel.state.isRealMoney {
                showAlert(title: "送金不可能", message: "このアーティストにはポイントしか送れません")
            } else {
                viewModel.state.isRealMoney
                    ? pay()
                    : pointViewModel.usePoint(point: viewModel.state.tip)
            }
        default: break
        }
    }
    
    private func pay() {
        guard let product = viewModel.state.products.filter { $0.price.intValue == viewModel.state.tip }.first else { return }
        showAlert(title: "購入確認", message: "\(viewModel.state.tip)円でチップを購入しますか？") { [unowned self] in
            viewModel.purchase(product)
        }
    }
    
    private func showSuccessPopup(tip: SocialTip) {
        let alertView = SCLAlertView()
        alertView.addButton(
            "Twitterでシェア",
            backgroundColor: Brand.color(for: .brand(.twitter)),
            textColor: Brand.color(for: .text(.primary)),
            action: { [unowned self] in
                shareWithTwitter(type: .tip(tip))
        })
        alertView.showSuccess("成功", subTitle: "チップを送りました！！！")
    }
}

extension PaymentSocialTipViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let message: String? = textView.text.isEmpty ? nil : textView.text
        viewModel.didUpdateMessage(message: message)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

extension PaymentSocialTipViewController: TagListViewDelegate {
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        switch sender {
        case templateMessageList:
            textView.text = title
            viewModel.didUpdateMessage(message: title)
        case templateTipList:
            tipLabel.setText(text: title)
            guard let tip = Int(title) else { return }
            viewModel.didUpdateTip(tip: tip)
        default: break
        }
    }
}

extension PaymentSocialTipViewController: CoachMarksControllerDelegate, CoachMarksControllerDataSource {
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return coachSteps.count
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        return coachMarksController.helper.makeCoachMark(for: coachSteps[index].view)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: (UIView & CoachMarkBodyView), arrowView: (UIView & CoachMarkArrowView)?) {
        let coachStep = self.coachSteps[index]
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        coachViews.bodyView.hintLabel.text = coachStep.hint
        coachViews.bodyView.nextLabel.text = coachStep.next
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
}

