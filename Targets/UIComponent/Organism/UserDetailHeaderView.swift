//
//  UserDetailHeaderView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/02/28.
//

import DomainEntity
import Endpoint
import InternalDomain
import UIKit
import ImagePipeline

public final class UserDetailHeaderView: UIView, PageHeaderView {
    public var pageHeaderHeight: CGFloat = 156
    
    public typealias Input = (
        selfUser: User,
        userDetail: UserDetail,
        imagePipeline: ImagePipeline
    )
    
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
    
    func bind() {
        userInformationView.listen { [unowned self] output in
            switch output {
            case .arrowButtonTapped: break
            case .followerCountButtonTapped:
                self.listener(.followersButtonTapped)
            case .followingUserCountButtonTapped:
                self.listener(.followingUsersButtonTapped)
            case .likedPostButtonTapped:
                self.listener(.likedPostsButtonTapped)
            case .followButtonTapped:
                self.listener(.followButtonTapped)
            case .sendMessageButtonTapped:
                self.listener(.sendMessageButtonTapped)
            case .editButtonTapped:
                self.listener(.editButtonTapped)
            }
        }
    }
    
    private func setup() {
        backgroundColor = .clear
        addSubview(userInformationView)
        NSLayoutConstraint.activate([
            userInformationView.topAnchor.constraint(equalTo: topAnchor),
            userInformationView.bottomAnchor.constraint(equalTo: bottomAnchor),
            userInformationView.leftAnchor.constraint(equalTo: leftAnchor),
            userInformationView.rightAnchor.constraint(equalTo: rightAnchor),
        ])
        bind()
    }

    // MARK: - Output
    private var listener: (Output) -> Void = { listenType in }
    public func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
    
    public enum Output {
        case followersButtonTapped
        case followingUsersButtonTapped
        case likedPostsButtonTapped
        case followButtonTapped
        case sendMessageButtonTapped
        case editButtonTapped
    }
}
