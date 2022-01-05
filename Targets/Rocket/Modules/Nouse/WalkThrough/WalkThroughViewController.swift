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
        button.titleLabel?.textColor = Brand.color(for: .brand(.primary))
        button.addTarget(self, action: #selector(_closeButtonTapped), for: .touchUpInside)
        
        return button
    }()
    let titles = [
        "好きなアーティストをフォロー",
        "参戦する/したライブを探してチェック",
        "プロフィールを作成",
        "ライブ予定を友達にシェア",
        "アーティストを応援",
        "ポイントを増やす",
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
        let vc2 = SearchLiveViewController(dependencyProvider: dependencyProvider)
        let vc3 = AppDescriptionViewController(input: (description: "あとはプロフィールを設定すれば完成！", imageName: "ss_stats"))
        let vc4 = AppDescriptionViewController(input: (description: "ホームに直近のライブが表示され、参戦予定の友達がひと目で分かるよ！！！友達をOTOAKAに誘って繋がってみてね！！！！", imageName: "ss_home"))
        let vc5 = AppDescriptionViewController(input: (description: "アーティストに応援メッセージと共に直接チップを投げることができるよ！チップはApple Payかポイントから送れるよ！！", imageName: "ss_tip"))
        let vc6 = AppDescriptionViewController(input: (description: "ポイントは色んなページの右上にあるシェアボタンからツイッターでシェアすると増えるよ！", imageName: "ss_share"))
        
        let vcs = [vc1, vc2, vc3, vc4, vc5, vc6]
        vcs.forEach { add(viewController: $0) }
        
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
        _nextButton.isHidden = pageNumber == 5
        navigationItem.rightBarButtonItem = pageNumber == 5 ? UIBarButtonItem(customView: _closeButton) : nil
        
        title = titles[pageNumber]
    }
    
    override func scrollViewDidScroll(_ sv: UIScrollView) {
        sv.contentOffset.y = 0
    }
}
