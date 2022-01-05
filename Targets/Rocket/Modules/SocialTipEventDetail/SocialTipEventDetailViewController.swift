//
//  SocialTipEventDetailViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/01/05.
//

import Foundation
import UIKit
import Combine
import SafariServices
import InternalDomain
import UIComponent
import Endpoint

final class SocialTipEventDetailViewController: UIViewController, Instantiable {
    typealias Input = SocialTipEvent
    
    private let viewModel: SocialTipEventDetailViewModel
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    private lazy var liveView: LiveBannerCellContent = {
        let content = LiveBannerCellContent()
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()
    private lazy var eventTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .xxlargeStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = ""
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.font = Brand.font(for: .mediumStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .left
        
        textView.returnKeyType = .done
        return textView
    }()
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .xsmall)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    
    private lazy var scrollStackView: UIStackView = {
        let postView = UIStackView()
        postView.translatesAutoresizingMaskIntoConstraints = false
        postView.backgroundColor = Brand.color(for: .background(.primary))
        postView.axis = .vertical
        postView.spacing = 16
        
        postView.addArrangedSubview(eventTitleLabel)
        postView.addArrangedSubview(textView)
        postView.addArrangedSubview(dateLabel)
        
        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        postView.addArrangedSubview(bottomSpacer)
        NSLayoutConstraint.activate([
            bottomSpacer.widthAnchor.constraint(equalTo: postView.widthAnchor),
            bottomSpacer.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        return postView
    }()
    
    private let refreshControl = BrandRefreshControl()
    let dependencyProvider: LoggedInDependencyProvider
    var cancellables: Set<AnyCancellable> = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = SocialTipEventDetailViewModel(dependencyProvider: dependencyProvider, input: input)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        bind()
    }
    private func bind() {
        liveView.addTarget(self, action: #selector(liveViewTapped), for: .touchUpInside)
    }
    
    private func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            scrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            scrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
        ])
        
        scrollView.addSubview(liveView)
        NSLayoutConstraint.activate([
            liveView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            liveView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            liveView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            liveView.heightAnchor.constraint(equalToConstant: 100),
            liveView.topAnchor.constraint(equalTo: scrollView.topAnchor),
        ])
        
        scrollView.addSubview(scrollStackView)
        NSLayoutConstraint.activate([
            scrollStackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 16),
            scrollStackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -16),
            scrollStackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            scrollStackView.topAnchor.constraint(equalTo: liveView.bottomAnchor, constant: 16),
            scrollStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])
        
        liveView.inject(input: (live: viewModel.state.event.live, imagePipeline: dependencyProvider.imagePipeline))
        eventTitleLabel.text = viewModel.state.event.title
        textView.text = viewModel.state.event.description
        dateLabel.text = "\(viewModel.state.event.since.toFormatString(format: "yyyy/MM/dd")) ~ \(viewModel.state.event.until.toFormatString(format: "yyyy/MM/dd"))"
    }
    
    @objc private func liveViewTapped() {
        let vc = LiveDetailViewController(dependencyProvider: dependencyProvider, input: viewModel.state.event.live)
        navigationController?.pushViewController(vc, animated: true)
    }
}
