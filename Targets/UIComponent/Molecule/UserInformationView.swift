//
//  UserInformationView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/02/28.
//

import Foundation
import UIKit
import DomainEntity

class UserInformationView: UIView {
    public typealias Input = UserDetailHeaderView.Input
    
    private lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 40
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var displayNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Brand.color(for: .text(.primary))
        label.font = Brand.font(for: .largeStrong)
        return label
    }()
    
    private lazy var profileSummaryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Brand.color(for: .text(.primary))
        label.font = Brand.font(for: .medium)
        return label
    }()
    
    private lazy var liveStyleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Brand.color(for: .text(.primary))
        label.font = Brand.font(for: .medium)
        return label
    }()
    
    private lazy var followerCountSumamryView: CountSummaryView = {
        let summaryView = CountSummaryView()
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        summaryView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(followersSummaryViewTapped))
        )
        return summaryView
    }()
    
    private lazy var followingUserCountSummaryView: CountSummaryView = {
        let summaryView = CountSummaryView()
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        summaryView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(followingUserSummaryViewTapped))
        )
        return summaryView
    }()
    
    private lazy var likeFeedCountSummaryView: CountSummaryView = {
        let summaryView = CountSummaryView()
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        summaryView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(likeFeedSummaryViewTapped))
        )
        return summaryView
    }()
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func update(input: Input) {
        displayNameLabel.text = input.user.name
        profileSummaryLabel.text = [input.user.age.map {String($0)}, input.user.sex, input.user.residence].compactMap {$0}.joined(separator: "・")
        liveStyleLabel.text = input.user.liveStyle ?? ""
        followerCountSumamryView.update(input: (title: "フォロワー", count: input.followersCount))
        followingUserCountSummaryView.update(input: (title: "フォロー", count: input.followingUsersCount))
        likeFeedCountSummaryView.update(input: (title: "いいね", count: input.likePostCount))
        input.imagePipeline.loadImage(URL(string: input.user.thumbnailURL!)!, into: profileImageView)
    }
    
    private func setup() {
        backgroundColor = .clear
        
        addSubview(profileImageView)
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 80),
            profileImageView.heightAnchor.constraint(equalToConstant: 80),
            profileImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            profileImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
        ])
        
        addSubview(displayNameLabel)
        NSLayoutConstraint.activate([
            displayNameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor),
            displayNameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8),
            displayNameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
        ])
        
        addSubview(profileSummaryLabel)
        NSLayoutConstraint.activate([
            profileSummaryLabel.topAnchor.constraint(equalTo: displayNameLabel.bottomAnchor, constant: 8),
            profileSummaryLabel.leftAnchor.constraint(equalTo: displayNameLabel.leftAnchor),
            profileSummaryLabel.rightAnchor.constraint(equalTo: displayNameLabel.rightAnchor),
        ])
        
        addSubview(liveStyleLabel)
        NSLayoutConstraint.activate([
            liveStyleLabel.topAnchor.constraint(equalTo: profileSummaryLabel.bottomAnchor, constant: 8),
            liveStyleLabel.leftAnchor.constraint(equalTo: displayNameLabel.leftAnchor),
            liveStyleLabel.rightAnchor.constraint(equalTo: displayNameLabel.rightAnchor),
        ])
        
        addSubview(followerCountSumamryView)
        NSLayoutConstraint.activate([
            followerCountSumamryView.heightAnchor.constraint(equalToConstant: 60),
            followerCountSumamryView.widthAnchor.constraint(equalToConstant: 80),
            followerCountSumamryView.topAnchor.constraint(equalTo: liveStyleLabel.bottomAnchor, constant: 12),
            followerCountSumamryView.leftAnchor.constraint(equalTo: displayNameLabel.leftAnchor),
        ])
        
        addSubview(followingUserCountSummaryView)
        NSLayoutConstraint.activate([
            followingUserCountSummaryView.heightAnchor.constraint(equalToConstant: 60),
            followingUserCountSummaryView.widthAnchor.constraint(equalToConstant: 80),
            followingUserCountSummaryView.topAnchor.constraint(equalTo: followerCountSumamryView.topAnchor),
            followingUserCountSummaryView.leftAnchor.constraint(equalTo: followerCountSumamryView.rightAnchor, constant: 4),
        ])
        
        addSubview(likeFeedCountSummaryView)
        NSLayoutConstraint.activate([
            likeFeedCountSummaryView.heightAnchor.constraint(equalToConstant: 60),
            likeFeedCountSummaryView.widthAnchor.constraint(equalToConstant: 80),
            likeFeedCountSummaryView.topAnchor.constraint(equalTo: followerCountSumamryView.topAnchor),
            likeFeedCountSummaryView.leftAnchor.constraint(equalTo: followingUserCountSummaryView.rightAnchor, constant: 4),
        ])
    }
    
    private var listener: (Output) -> Void = { listenType in }
    public func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }

    public enum Output {
        case followerCountButtonTapped
        case followingUserCountButtonTapped
        case likeFeedCountButtonTapped
        case arrowButtonTapped
    }
    
    @objc private func touchUpInsideArrowButton() {
        listener(.arrowButtonTapped)
    }
    
    @objc private func followersSummaryViewTapped() {
        listener(.followerCountButtonTapped)
    }
    
    @objc private func followingUserSummaryViewTapped() {
        listener(.followingUserCountButtonTapped)
    }
    
    @objc private func likeFeedSummaryViewTapped() {
        listener(.likeFeedCountButtonTapped)
    }
}
