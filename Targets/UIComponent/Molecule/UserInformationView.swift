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
    private lazy var sendMessageButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 16
        button.setImage(
            UIImage(systemName: "envelope")!.withTintColor(Brand.color(for: .text(.toggle)), renderingMode: .alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(sendMessageButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    private lazy var followButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 16
        button.setImage(
            UIImage(systemName: "person.badge.plus")!.withTintColor(Brand.color(for: .text(.toggle)), renderingMode: .alwaysOriginal), for: .normal)
        button.setImage(UIImage(systemName: "person.fill.checkmark.rtl")!.withTintColor(.black, renderingMode: .alwaysOriginal), for: .selected)
        button.addTarget(self, action: #selector(followButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    private let editProfileButton: ToggleButton = {
        let button = ToggleButton()
        button.setImage(
            UIImage(systemName: "gearshape")!.withTintColor(Brand.color(for: .text(.toggle)), renderingMode: .alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 16
        button.isHidden = true
        button.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        return button
    }()
    private lazy var profileSummaryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Brand.color(for: .text(.primary))
        label.font = Brand.font(for: .xsmall)
        return label
    }()
    private lazy var liveStyleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = Brand.color(for: .text(.toggle))
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Brand.color(for: .text(.primary))
        label.font = Brand.font(for: .xsmallStrong)
        return label
    }()
    private lazy var countSummaryStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.spacing = 8
        
        stackView.addArrangedSubview(followerCountSumamryView)
        stackView.addArrangedSubview(followingUserCountSummaryView)
        
        return stackView
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
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func update(input: Input) {
        displayNameLabel.text = input.userDetail.user.name
        profileSummaryLabel.text = [input.userDetail.user.age.map {String($0)}, input.userDetail.user.sex, input.userDetail.user.residence].compactMap {$0}.joined(separator: "・")
        liveStyleLabel.text = input.userDetail.user.liveStyle.map { "  \($0)  "}
        followerCountSumamryView.update(input: (title: "フォロワー", count: input.userDetail.followersCount))
        followingUserCountSummaryView.update(input: (title: "フォロー", count: input.userDetail.followingUsersCount))
        if let thumbnail = input.userDetail.thumbnailURL, let url = URL(string: thumbnail) {
            input.imagePipeline.loadImage(url, into: profileImageView)
        }
        if input.userDetail.user.id == input.selfUser.id {
            editProfileButton.isHidden = false
            followButton.isHidden = true
            sendMessageButton.isHidden = true
        } else {
            editProfileButton.isHidden = true
            followButton.isHidden = false
            followButton.isEnabled = true
            sendMessageButton.isHidden = false
            sendMessageButton.isEnabled = true
            followButton.isSelected = input.userDetail.isFollowing
        }
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
            displayNameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -104),
        ])
        
        addSubview(followButton)
        NSLayoutConstraint.activate([
            followButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            followButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            followButton.widthAnchor.constraint(equalToConstant: 32),
            followButton.heightAnchor.constraint(equalTo: followButton.widthAnchor),
        ])
        addSubview(sendMessageButton)
        NSLayoutConstraint.activate([
            sendMessageButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            sendMessageButton.rightAnchor.constraint(equalTo: followButton.leftAnchor, constant: -8),
            sendMessageButton.widthAnchor.constraint(equalToConstant: 32),
            sendMessageButton.heightAnchor.constraint(equalTo: sendMessageButton.widthAnchor),
        ])
        addSubview(editProfileButton)
        NSLayoutConstraint.activate([
            editProfileButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            editProfileButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            editProfileButton.widthAnchor.constraint(equalToConstant: 32),
            editProfileButton.heightAnchor.constraint(equalTo: followButton.widthAnchor),
        ])
        
        addSubview(profileSummaryLabel)
        NSLayoutConstraint.activate([
            profileSummaryLabel.topAnchor.constraint(equalTo: displayNameLabel.bottomAnchor, constant: 4),
            profileSummaryLabel.leftAnchor.constraint(equalTo: displayNameLabel.leftAnchor),
            profileSummaryLabel.rightAnchor.constraint(equalTo: displayNameLabel.rightAnchor),
        ])
        
        addSubview(liveStyleLabel)
        NSLayoutConstraint.activate([
            liveStyleLabel.topAnchor.constraint(equalTo: profileSummaryLabel.bottomAnchor, constant: 4),
            liveStyleLabel.leftAnchor.constraint(equalTo: displayNameLabel.leftAnchor),
            liveStyleLabel.heightAnchor.constraint(equalToConstant: 24),
            liveStyleLabel.rightAnchor.constraint(lessThanOrEqualTo: displayNameLabel.rightAnchor),
        ])
        
        addSubview(countSummaryStackView)
        NSLayoutConstraint.activate([
            countSummaryStackView.leftAnchor.constraint(equalTo: displayNameLabel.leftAnchor),
            countSummaryStackView.topAnchor.constraint(equalTo: liveStyleLabel.bottomAnchor, constant: 8),
        ])
    }
    
    private var listener: (Output) -> Void = { listenType in }
    public func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }

    public enum Output {
        case followerCountButtonTapped
        case followingUserCountButtonTapped
        case likedPostButtonTapped
        case sendMessageButtonTapped
        case arrowButtonTapped
        case followButtonTapped
        case editButtonTapped
    }
    
    @objc private func touchUpInsideArrowButton() {
        listener(.arrowButtonTapped)
    }
    
    @objc private func followersSummaryViewTapped() {
        listener(.followerCountButtonTapped)
    }
    
    @objc private func sendMessageButtonTapped() {
        listener(.sendMessageButtonTapped)
    }
    
    @objc private func followingUserSummaryViewTapped() {
        listener(.followingUserCountButtonTapped)
    }
    
    @objc private func likedPostSummaryViewTapped() {
        listener(.likedPostButtonTapped)
    }
    
    @objc private func followButtonTapped() {
        followButton.isEnabled = false
        listener(.followButtonTapped)
    }
    
    @objc private func editButtonTapped() {
        listener(.editButtonTapped)
    }
}
