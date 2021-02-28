//
//  UserDetailHeaderView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/02/28.
//

import DomainEntity
import InternalDomain
import UIKit
import ImagePipeline

public final class UserDetailHeaderView: UIView {
    public typealias Input = (
        user: User,
        followersCount: Int,
        followingUsersCount: Int,
        imagePipeline: ImagePipeline
    )
    
    private lazy var horizontalScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.isScrollEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var userInformationView: UserInformationView = {
        let view = UserInformationView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    
    public init() {
        super.init(frame: .zero)
        self.setup()
    }
    
    public init(input: Input) {
        super.init(frame: .zero)
        self.setup()
        
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    public func update(input: Input) {
        userInformationView.update(input: input)
    }
    
    func bind() {}
    
    private func setup() {
        backgroundColor = .clear
        
        addSubview(horizontalScrollView)
        NSLayoutConstraint.activate([
            horizontalScrollView.topAnchor.constraint(equalTo: topAnchor),
            horizontalScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalScrollView.leftAnchor.constraint(equalTo: leftAnchor),
            horizontalScrollView.rightAnchor.constraint(equalTo: rightAnchor),
        ])
        
        do {
            let arrangedSubviews = [userInformationView]
            let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .horizontal
            stackView.distribution = .fillEqually
            horizontalScrollView.addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                stackView.leftAnchor.constraint(equalTo: horizontalScrollView.leftAnchor),
                stackView.topAnchor.constraint(equalTo: horizontalScrollView.topAnchor),
                stackView.bottomAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor),
                stackView.rightAnchor.constraint(equalTo: horizontalScrollView.rightAnchor),
                stackView.widthAnchor.constraint(equalTo: horizontalScrollView.widthAnchor, multiplier: CGFloat(arrangedSubviews.count))
            ])
            
            bind()
        }
    }
    
    private func nextPage() {
        UIView.animate(withDuration: 0.3) {
            // FIXME: Support landscape mode?
            self.horizontalScrollView.contentOffset.x += UIScreen.main.bounds.width
        }
    }

    // MARK: - Output
    private var listener: (Output) -> Void = { listenType in }
    public func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
    
    public enum Output {
        case followersButtonTapped
        case followingUsersButtonTapped
    }
}
