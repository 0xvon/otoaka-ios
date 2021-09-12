//
//  WalkThroughViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/08/18.
//

import UIKit
import BWWalkthrough

final class WalkThroughViewController: BWWalkthroughViewController, BWWalkthroughViewControllerDelegate {
    let dependencyProvider: LoggedInDependencyProvider
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var _prevButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrowtriangle.left.fill")?.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleToFill
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.addTarget(self, action: #selector(_prevButtonTapped), for: .touchUpInside)
        
        return button
    }()
    private lazy var _nextButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrowtriangle.right.fill")?.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleToFill
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.addTarget(self, action: #selector(_nextButtonTapped), for: .touchUpInside)
        
        return button
    }()
    private lazy var _closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("はじめる", for: .normal)
        button.titleLabel?.font = Brand.font(for: .mediumStrong)
        button.titleLabel?.textColor = Brand.color(for: .text(.toggle))
        button.addTarget(self, action: #selector(_closeButtonTapped), for: .touchUpInside)
        
        return button
    }()
    let titles = [
        "アーティストをフォローしよう",
        "行きたいライブをいいねしよう",
        "ライブの感想を記録しよう"
    ]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = []
        self.delegate = self
        title = titles[0]
        navigationItem.largeTitleDisplayMode = .never
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        scrollview.isPagingEnabled = true
        scrollview.alwaysBounceVertical = false
        scrollview.showsVerticalScrollIndicator = false
        scrollview.delegate = self
        
        let vc1 = GroupListViewController(dependencyProvider: dependencyProvider, input: .allGroup)
        let vc2 = LiveListViewController(dependencyProvider: dependencyProvider, input: .upcoming(dependencyProvider.user))
        let vc3 = AppDescriptionViewController(input: (description: "検索🔍タブから自分が行ったライブを探して「このライブのレポートを書く」を押してレポートを書こう！レポートにはその日のセットリスト、MCやライブ中に起こった印象的な出来事、感想を記録しよう！レポートはマイページに溜まっていくよ！", imageName: "ss_post"))
        
        add(viewController: vc1)
        add(viewController: vc2)
        add(viewController: vc3)
        
        self.view.addSubview(_prevButton)
        self.view.addSubview(_nextButton)
        NSLayoutConstraint.activate([
            _prevButton.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 8),
            _prevButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            _prevButton.heightAnchor.constraint(equalToConstant: 80),
            _prevButton.widthAnchor.constraint(equalToConstant: 30),
            
            _nextButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -8),
            _nextButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            _nextButton.heightAnchor.constraint(equalToConstant: 80),
            _nextButton.widthAnchor.constraint(equalToConstant: 30),
        ])
        
        _prevButton.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    @objc private func _prevButtonTapped() {
        self.prevPage()
    }
    
    @objc private func _nextButtonTapped() {
        self.nextPage()
    }
    
    @objc private func _closeButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func walkthroughPageDidChange(_ pageNumber: Int) {
        _prevButton.isHidden = pageNumber == 0
        _nextButton.isHidden = pageNumber == 2
        navigationItem.rightBarButtonItem = pageNumber == 2 ? UIBarButtonItem(customView: _closeButton) : nil
        
        title = titles[pageNumber]
    }
    
    override func scrollViewDidScroll(_ sv: UIScrollView) {
        sv.contentOffset.y = 0
    }
}
