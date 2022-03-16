//
//  MergeLiveViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/03/16.
//

import Combine
import Endpoint
import UIComponent
import Foundation
import InternalDomain
import UIKit

final class MergeLiveViewController: UIViewController, Instantiable {
    let dependencyProvider: LoggedInDependencyProvider
    typealias Input = Live
    let viewModel: MergeLiveViewModel
    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = MergeLiveViewModel(dependencyProvider: dependencyProvider, live: input)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private lazy var verticalScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        return scrollView
    }()
    private lazy var scrollStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isUserInteractionEnabled = true
        stackView.spacing = 8
        stackView.axis = .vertical
        return stackView
    }()
    private lazy var masterLive: LiveDetailHeaderView = {
        let view = LiveDetailHeaderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        return view
    }()
    private lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .mediumStrong)
        label.text = "+"
        label.textAlignment = .center
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var otherLive: LiveDetailHeaderView = {
        let view = LiveDetailHeaderView()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(liveTapped)))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var addButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("選択する", for: .normal)
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        button.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        button.setTitleColor(Brand.color(for: .text(.primary)).pressed(), for: .highlighted)
        button.titleLabel?.font = Brand.font(for: .largeStrong)
        button.layer.cornerRadius = 20
        button.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        button.layer.borderWidth = 1
        return button
    }()
    private lazy var goButton: UIButton = {
        let postButton = UIButton()
        postButton.translatesAutoresizingMaskIntoConstraints = false
        postButton.setTitleColor(Brand.color(for: .brand(.primary)), for: .normal)
        postButton.setTitle("OK", for: .normal)
        postButton.titleLabel?.font = Brand.font(for: .largeStrong)
        postButton.addTarget(self, action: #selector(goButtonTapped), for: .touchUpInside)
        return postButton
    }()
    private lazy var activityIndicator: LoadingCollectionView = {
        let activityIndicator = LoadingCollectionView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    override func loadView() {
        view = verticalScrollView
        view.backgroundColor = Brand.color(for: .background(.primary))
        view.addSubview(scrollStackView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: scrollStackView.topAnchor),
            view.bottomAnchor.constraint(equalTo: scrollStackView.bottomAnchor),
            view.leftAnchor.constraint(equalTo: scrollStackView.leftAnchor, constant: -16),
            view.rightAnchor.constraint(equalTo: scrollStackView.rightAnchor, constant: 16),
        ])
        
        let topSpacer = UIView()
        topSpacer.translatesAutoresizingMaskIntoConstraints = false
        scrollStackView.addArrangedSubview(topSpacer)
        NSLayoutConstraint.activate([
            topSpacer.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        scrollStackView.addArrangedSubview(masterLive)
        NSLayoutConstraint.activate([
            masterLive.heightAnchor.constraint(equalToConstant: 250),
            masterLive.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - 32),
        ])
        
        scrollStackView.addArrangedSubview(label)
        
        otherLive.isHidden = true
        scrollStackView.addArrangedSubview(otherLive)
        NSLayoutConstraint.activate([
            otherLive.heightAnchor.constraint(equalToConstant: 250),
//            otherLive.widthAnchor.constraint(equalTo: scrollStackView.widthAnchor),
        ])
        
        scrollStackView.addArrangedSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.heightAnchor.constraint(equalToConstant: 250),
//            addButton.widthAnchor.constraint(equalTo: scrollStackView.widthAnchor),
        ])
        
        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        scrollStackView.addArrangedSubview(bottomSpacer)
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        masterLive.update(input: (
            live: viewModel.state.live,
            imagePipeline: dependencyProvider.imagePipeline
        ))
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didMergeLive:
                activityIndicator.stopAnimating()
                navigationController?.popViewController(animated: true)
            case .updateSubmittableState(let state):
                switch state {
                case .editting(let isSubmittable):
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: goButton)
                    activityIndicator.stopAnimating()
                    if let live = viewModel.state.otherLives.first {
                        otherLive.update(input: (
                            live: live,
                            imagePipeline: dependencyProvider.imagePipeline
                        ))
                        otherLive.isHidden = false
                        addButton.isHidden = true
                    } else {
                        otherLive.isHidden = true
                        addButton.isHidden = false
                    }
                    
                    if isSubmittable {
                        goButton.isEnabled = true
                        goButton.setTitleColor(Brand.color(for: .brand(.primary)), for: .normal)
                    } else {
                        goButton.isEnabled = false
                        goButton.setTitleColor(Brand.color(for: .background(.light)), for: .normal)
                    }
                case .loading:
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
                    activityIndicator.startAnimating()
                }
            case .reportError(let err):
                print(String(describing: err))
                showAlert()
                activityIndicator.stopAnimating()
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: goButton)
            }
        }
        .store(in: &cancellables)
    }
    
    @objc private func goButtonTapped() {
        viewModel.merge()
    }
    
    @objc private func addButtonTapped() {
        let vc = SelectLiveViewController(dependencyProvider: dependencyProvider)
        vc.listen { [unowned self] live in
            viewModel.addLive(live)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func liveTapped() {
        showConfirmAlert(title: "削除", message: "選択中のライブを削除しますか？") { [unowned self] in
            guard let live = viewModel.state.otherLives.first else { return }
            viewModel.removeLive(live)
        }
    }
}
