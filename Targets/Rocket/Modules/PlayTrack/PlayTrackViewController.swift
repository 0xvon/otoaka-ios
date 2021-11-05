//
//  PlayTrackViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/04.
//

import Foundation
import UIKit
import Combine
import YoutubePlayer_in_WKWebView
import UIComponent
import StoreKit
import MediaPlayer

final class PlayTrackViewController: UIViewController, Instantiable {
    typealias Input = PlayTrackViewModel.Input
    
    var dependencyProvider: LoggedInDependencyProvider
    let viewModel: PlayTrackViewModel
    var cancellables: Set<AnyCancellable> = []
    let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    
    private let refreshControl = BrandRefreshControl()
    private var timer = Timer()
    
    private lazy var verticalScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isScrollEnabled = true
        scrollView.refreshControl = refreshControl
        return scrollView
    }()
    
    private lazy var scrollStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()
    
    private lazy var playerView: WKYTPlayerView = {
        let playerView = WKYTPlayerView()
        playerView.delegate = self
        playerView.backgroundColor = .clear
        playerView.translatesAutoresizingMaskIntoConstraints = false
        return playerView
    }()
    
    private lazy var cassetteTapeView: UIView = {
        let cassetteTapeView = UIView()
        cassetteTapeView.layer.cornerRadius = 20
        cassetteTapeView.backgroundColor = .gray
        cassetteTapeView.translatesAutoresizingMaskIntoConstraints = false
        
        let leftTopEdgePinView = UIView()
        leftTopEdgePinView.translatesAutoresizingMaskIntoConstraints = false
        leftTopEdgePinView.backgroundColor = .white
        leftTopEdgePinView.layer.cornerRadius = 7
        cassetteTapeView.addSubview(leftTopEdgePinView)
        NSLayoutConstraint.activate([
            leftTopEdgePinView.widthAnchor.constraint(equalToConstant: 14),
            leftTopEdgePinView.heightAnchor.constraint(equalTo: leftTopEdgePinView.widthAnchor, multiplier: 1),
            leftTopEdgePinView.topAnchor.constraint(equalTo: cassetteTapeView.topAnchor, constant: 8),
            leftTopEdgePinView.leftAnchor.constraint(equalTo: cassetteTapeView.leftAnchor, constant: 8),
        ])
        
        let rightTopEdgePinView = UIView()
        rightTopEdgePinView.translatesAutoresizingMaskIntoConstraints = false
        rightTopEdgePinView.backgroundColor = .white
        rightTopEdgePinView.layer.cornerRadius = 7
        cassetteTapeView.addSubview(rightTopEdgePinView)
        NSLayoutConstraint.activate([
            rightTopEdgePinView.widthAnchor.constraint(equalToConstant: 14),
            rightTopEdgePinView.heightAnchor.constraint(equalTo: rightTopEdgePinView.widthAnchor, multiplier: 1),
            rightTopEdgePinView.topAnchor.constraint(equalTo: cassetteTapeView.topAnchor, constant: 8),
            rightTopEdgePinView.rightAnchor.constraint(equalTo: cassetteTapeView.rightAnchor, constant: -8),
        ])
        
        let leftBottomEdgePinView = UIView()
        leftBottomEdgePinView.translatesAutoresizingMaskIntoConstraints = false
        leftBottomEdgePinView.backgroundColor = .white
        leftBottomEdgePinView.layer.cornerRadius = 7
        cassetteTapeView.addSubview(leftBottomEdgePinView)
        NSLayoutConstraint.activate([
            leftBottomEdgePinView.widthAnchor.constraint(equalToConstant: 14),
            leftBottomEdgePinView.heightAnchor.constraint(equalTo: leftBottomEdgePinView.widthAnchor, multiplier: 1),
            leftBottomEdgePinView.bottomAnchor.constraint(equalTo: cassetteTapeView.bottomAnchor, constant: -8),
            leftBottomEdgePinView.leftAnchor.constraint(equalTo: cassetteTapeView.leftAnchor, constant: 8),
        ])
        
        let rightBottomEdgePinView = UIView()
        rightBottomEdgePinView.translatesAutoresizingMaskIntoConstraints = false
        rightBottomEdgePinView.backgroundColor = .white
        rightBottomEdgePinView.layer.cornerRadius = 7
        cassetteTapeView.addSubview(rightBottomEdgePinView)
        NSLayoutConstraint.activate([
            rightBottomEdgePinView.widthAnchor.constraint(equalToConstant: 14),
            rightBottomEdgePinView.heightAnchor.constraint(equalTo: rightBottomEdgePinView.widthAnchor, multiplier: 1),
            rightBottomEdgePinView.bottomAnchor.constraint(equalTo: cassetteTapeView.bottomAnchor, constant: -8),
            rightBottomEdgePinView.rightAnchor.constraint(equalTo: cassetteTapeView.rightAnchor, constant: -8),
        ])
        
        cassetteTapeView.addSubview(bottomShellView)
        NSLayoutConstraint.activate([
            bottomShellView.bottomAnchor.constraint(equalTo: cassetteTapeView.bottomAnchor),
            bottomShellView.centerXAnchor.constraint(equalTo: cassetteTapeView.centerXAnchor),
            bottomShellView.widthAnchor.constraint(equalTo: cassetteTapeView.widthAnchor, multiplier: 0.6),
            bottomShellView.heightAnchor.constraint(equalTo: bottomShellView.widthAnchor, multiplier: 0.25),
        ])
        
        cassetteTapeView.addSubview(cassetteCenterView)
        NSLayoutConstraint.activate([
            cassetteCenterView.widthAnchor.constraint(equalTo: cassetteTapeView.widthAnchor, multiplier: 0.8),
            cassetteCenterView.centerXAnchor.constraint(equalTo: cassetteTapeView.centerXAnchor),
            cassetteCenterView.topAnchor.constraint(equalTo: cassetteTapeView.topAnchor, constant: 28),
            cassetteCenterView.bottomAnchor.constraint(equalTo: bottomShellView.topAnchor, constant: -8),
        ])
        
        return cassetteTapeView
    }()
    private lazy var cassetteCenterView: UIView = {
        let cassetteCenterView = UIView()
        cassetteCenterView.backgroundColor = .black
        cassetteCenterView.layer.cornerRadius = 32
        cassetteCenterView.translatesAutoresizingMaskIntoConstraints = false
        cassetteCenterView.addSubview(cassetteEyeView)
        NSLayoutConstraint.activate([
            cassetteEyeView.heightAnchor.constraint(equalToConstant: 50),
            cassetteEyeView.widthAnchor.constraint(equalTo: cassetteCenterView.widthAnchor, multiplier: 0.7),
            cassetteEyeView.centerXAnchor.constraint(equalTo: cassetteCenterView.centerXAnchor),
            cassetteEyeView.bottomAnchor.constraint(equalTo: cassetteCenterView.bottomAnchor, constant: -16),
        ])
        
        cassetteCenterView.addSubview(cassetteTitleLabel)
        NSLayoutConstraint.activate([
            cassetteTitleLabel.leftAnchor.constraint(equalTo: cassetteCenterView.leftAnchor, constant: 16),
            cassetteTitleLabel.rightAnchor.constraint(equalTo: cassetteCenterView.rightAnchor, constant: -16),
            cassetteTitleLabel.bottomAnchor.constraint(equalTo: cassetteEyeView.topAnchor, constant: -8),
            cassetteTitleLabel.topAnchor.constraint(equalTo: cassetteCenterView.topAnchor, constant: 16),
        ])
        return cassetteCenterView
    }()
    private lazy var cassetteEyeView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 196 / 255, green: 196 / 255, blue: 196 / 255, alpha: 1)
        view.layer.cornerRadius = 25
        
        view.addSubview(leftCassetteRole)
        NSLayoutConstraint.activate([
            leftCassetteRole.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            leftCassetteRole.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            leftCassetteRole.widthAnchor.constraint(equalToConstant: 40),
            leftCassetteRole.heightAnchor.constraint(equalTo: leftCassetteRole.widthAnchor),
        ])
        
        view.addSubview(rightCassetteRole)
        NSLayoutConstraint.activate([
            rightCassetteRole.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            rightCassetteRole.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            rightCassetteRole.widthAnchor.constraint(equalToConstant: 40),
            rightCassetteRole.heightAnchor.constraint(equalTo: leftCassetteRole.widthAnchor),
        ])
        return view
    }()
    private lazy var cassetteTitleLabel: UILabel = {
        let cassetteTitleLabel = UILabel()
        cassetteTitleLabel.text = "Home - MY FIRST STORY"
        cassetteTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cassetteTitleLabel.textColor = Brand.color(for: .text(.primary))
        cassetteTitleLabel.adjustsFontSizeToFitWidth = true
        cassetteTitleLabel.textAlignment = .center
//        cassetteTitleLabel.minimumScaleFactor = 8
        return cassetteTitleLabel
    }()
    private lazy var leftCassetteRole: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "cassetteRole")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    private lazy var rightCassetteRole: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "cassetteRole")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    private lazy var bottomShellView: UIView = {
        let bottomShellView = UIView()
        bottomShellView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "W.O.D. Inc."
        label.font = Brand.font(for: .xsmallStrong)
        label.textColor = Brand.color(for: .text(.primary))
        bottomShellView.addSubview(label)
        NSLayoutConstraint.activate([
            label.bottomAnchor.constraint(equalTo: bottomShellView.bottomAnchor, constant: -4),
            label.leftAnchor.constraint(equalTo: bottomShellView.leftAnchor, constant: 8),
            label.rightAnchor.constraint(equalTo: bottomShellView.rightAnchor, constant: -8),
        ])
        return bottomShellView
    }()
    private lazy var musicPlayerIndicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        
        let musicThermalIndicatorStackView = UIStackView()
        musicThermalIndicatorStackView.translatesAutoresizingMaskIntoConstraints = false
        musicThermalIndicatorStackView.axis = .vertical
        musicThermalIndicatorStackView.distribution = .fillEqually
        musicThermalIndicatorStackView.spacing = 4
        
        view.addSubview(musicThermalIndicatorStackView)
        NSLayoutConstraint.activate([
            musicThermalIndicatorStackView.topAnchor.constraint(equalTo: view.topAnchor),
            musicThermalIndicatorStackView.leftAnchor.constraint(equalTo: view.leftAnchor),
            musicThermalIndicatorStackView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        
        musicThermalIndicatorStackView.addArrangedSubview(musicPlayerFirstThermalIndicaterView)
        NSLayoutConstraint.activate([
            musicPlayerFirstThermalIndicaterView.leftAnchor.constraint(equalTo: musicThermalIndicatorStackView.leftAnchor),
            musicPlayerFirstThermalIndicaterView.rightAnchor.constraint(equalTo: musicThermalIndicatorStackView.rightAnchor),
            musicPlayerFirstThermalIndicaterView.heightAnchor.constraint(equalToConstant: 8),
        ])
        
        musicThermalIndicatorStackView.addArrangedSubview(musicPlayerSecondThermalIndicaterView)
        NSLayoutConstraint.activate([
            musicPlayerSecondThermalIndicaterView.leftAnchor.constraint(equalTo: musicThermalIndicatorStackView.leftAnchor),
            musicPlayerSecondThermalIndicaterView.rightAnchor.constraint(equalTo: musicThermalIndicatorStackView.rightAnchor),
            musicPlayerSecondThermalIndicaterView.heightAnchor.constraint(equalToConstant: 8),
        ])
        
        musicThermalIndicatorStackView.addArrangedSubview(musicPlayerThirdThermalIndicaterView)
        NSLayoutConstraint.activate([
            musicPlayerThirdThermalIndicaterView.leftAnchor.constraint(equalTo: musicThermalIndicatorStackView.leftAnchor),
            musicPlayerThirdThermalIndicaterView.rightAnchor.constraint(equalTo: musicThermalIndicatorStackView.rightAnchor),
            musicPlayerThirdThermalIndicaterView.heightAnchor.constraint(equalToConstant: 8),
        ])
        
        view.addSubview(durationLabel)
        NSLayoutConstraint.activate([
            durationLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
            durationLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
            durationLabel.topAnchor.constraint(equalTo: musicThermalIndicatorStackView.bottomAnchor, constant: 8),
            durationLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            durationLabel.heightAnchor.constraint(equalToConstant: 20),
        ])
        return view
    }()
    private lazy var musicPlayerFirstThermalIndicaterView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 2
        return stackView
    }()
    private lazy var musicPlayerSecondThermalIndicaterView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 2
        return stackView
    }()
    private lazy var musicPlayerThirdThermalIndicaterView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 2
        return stackView
    }()
    private lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Brand.color(for: .brand(.primary))
        label.font = Brand.font(for: .small)
        return label
    }()
    private lazy var musicPlayerActionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 16
        stackView.distribution = .fill
        stackView.axis = .horizontal
        
        stackView.addArrangedSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.heightAnchor.constraint(equalToConstant: 44),
            backButton.widthAnchor.constraint(equalToConstant: 88),
        ])
        stackView.addArrangedSubview(playButton)
        NSLayoutConstraint.activate([
            playButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        stackView.addArrangedSubview(forButton)
        NSLayoutConstraint.activate([
            forButton.heightAnchor.constraint(equalToConstant: 44),
            forButton.widthAnchor.constraint(equalToConstant: 88),
        ])
        
        return stackView
    }()
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 10
        button.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        button.layer.borderWidth = 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backward), for: .touchUpInside)
        button.setImage(
            UIImage(systemName: "backward.fill")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal
        )
        return button
    }()
    
    private lazy var forButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 10
        button.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        button.layer.borderWidth = 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(forward), for: .touchUpInside)
        button.setImage(
            UIImage(systemName: "forward.fill")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal
        )
        return button
    }()
    private lazy var playButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 10
        button.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        button.layer.borderWidth = 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        button.setImage(
            UIImage(systemName: "play.fill")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal
        )
        button.setImage(
            UIImage(systemName: "pause.fill")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .selected
        )
        return button
    }()
    
    private lazy var logoView: UIView = {
        let logoView = UIView()
        logoView.translatesAutoresizingMaskIntoConstraints = false
        
        let logoInnerView = UIView()
        logoInnerView.translatesAutoresizingMaskIntoConstraints = false
        
        let logo = UIImageView()
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.image = UIImage(named: "icon")
        logo.layer.cornerRadius = 4
        logo.clipsToBounds = true
        logoInnerView.addSubview(logo)
        NSLayoutConstraint.activate([
            logo.widthAnchor.constraint(equalToConstant: 30),
            logo.heightAnchor.constraint(equalTo: logo.widthAnchor),
            logo.topAnchor.constraint(equalTo: logoInnerView.topAnchor),
            logo.leftAnchor.constraint(equalTo: logoInnerView.leftAnchor),
            logo.bottomAnchor.constraint(equalTo: logoInnerView.bottomAnchor),
        ])
        
        let logoTitle = UILabel()
        logoTitle.translatesAutoresizingMaskIntoConstraints = false
        logoTitle.text = "OTOAKA"
        logoTitle.font = Brand.font(for: .mediumStrong)
        logoTitle.textColor = Brand.color(for: .text(.primary))
        logoInnerView.addSubview(logoTitle)
        NSLayoutConstraint.activate([
            logoTitle.leftAnchor.constraint(equalTo: logo.rightAnchor, constant: 4),
            logoTitle.rightAnchor.constraint(equalTo: logoInnerView.rightAnchor),
            logoTitle.centerYAnchor.constraint(equalTo: logo.centerYAnchor),
        ])
        
        logoView.addSubview(logoInnerView)
        NSLayoutConstraint.activate([
            logoInnerView.centerXAnchor.constraint(equalTo: logoView.centerXAnchor),
            logoInnerView.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),
        ])
        
        return logoView
    }()
    
    private lazy var actionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        stackView.axis = .horizontal
        
        stackView.addArrangedSubview(commentButtonView)
        NSLayoutConstraint.activate([
            commentButtonView.widthAnchor.constraint(equalToConstant: 60),
            commentButtonView.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        stackView.addArrangedSubview(likeButtonView)
        NSLayoutConstraint.activate([
            likeButtonView.widthAnchor.constraint(equalToConstant: 60),
            likeButtonView.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        stackView.addArrangedSubview(shareButton)
        NSLayoutConstraint.activate([
            shareButton.widthAnchor.constraint(equalToConstant: 44),
            shareButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        stackView.addArrangedSubview(instagramButton)
        NSLayoutConstraint.activate([
            instagramButton.widthAnchor.constraint(equalToConstant: 44),
            instagramButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        stackView.addArrangedSubview(downloadButton)
        NSLayoutConstraint.activate([
            downloadButton.widthAnchor.constraint(equalToConstant: 44),
            downloadButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        stackView.addArrangedSubview(deleteButton)
        NSLayoutConstraint.activate([
            deleteButton.widthAnchor.constraint(equalToConstant: 44),
            deleteButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        let spacer = UIView()
        stackView.addArrangedSubview(spacer)
        
        return stackView
    }()
    
    private lazy var userSectionView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(profileImageView)
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.topAnchor),
            profileImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor, multiplier: 1),
            profileImageView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ])
        
        view.addSubview(userNameLabel)
        NSLayoutConstraint.activate([
            userNameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor),
            userNameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8),
            userNameLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        return view
    }()
    private lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 30
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        )
        return imageView
    }()
    private lazy var userNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .medium)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    
    private lazy var feedTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = Brand.font(for: .mediumStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textAlignment = .left
        textView.isScrollEnabled = false
        textView.isSelectable = false
        textView.isUserInteractionEnabled = false
        textView.backgroundColor = .clear
        return textView
    }()
    
    private lazy var commentButtonView: ReactionIndicatorButton = {
        let commentButton = ReactionIndicatorButton()
        commentButton.translatesAutoresizingMaskIntoConstraints = false
        commentButton.setImage(
            UIImage(systemName: "bubble.right")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal
        )
        commentButton.addTarget(self, action: #selector(commentButtonTapped), for: .touchUpInside)
        return commentButton
    }()
    private lazy var likeButtonView: ReactionIndicatorButton = {
        let likeButton = ReactionIndicatorButton()
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.setImage(
            UIImage(systemName: "heart")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal)
        likeButton.setImage(
            UIImage(systemName: "heart.fill")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .selected)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return likeButton
    }()
    private lazy var shareButton: UIButton = {
        let shareButton = UIButton()
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setImage(
            UIImage(named: "twitterMargin"),
            for: .normal)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        return shareButton
    }()
    private lazy var instagramButton: UIButton = {
        let shareButton = UIButton()
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setImage(
            UIImage(named: "instaMargin"),
            for: .normal)
        shareButton.addTarget(self, action: #selector(shareInstagramButtonTapped), for: .touchUpInside)
        return shareButton
    }()
    private lazy var downloadButton: UIButton = {
        let shareButton = UIButton()
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setImage(
            UIImage(systemName: "arrow.down.to.line")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal
        )
        shareButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
        return shareButton
    }()
    private lazy var deleteButton: UIButton = {
        let deleteButton = UIButton()
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(
            UIImage(systemName: "trash")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteFeedButtonTapped), for: .touchUpInside)
        return deleteButton
    }()
    private lazy var searchTrackButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        button.setTitleColor(Brand.color(for: .brand(.primary)), for: .highlighted)
        button.setTitle("歌詞検索", for: .normal)
        button.titleLabel?.font = Brand.font(for: .largeStrong)
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
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = PlayTrackViewModel(dependencyProvider: dependencyProvider, input: input)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer)
        musicPlayer.endGeneratingPlaybackNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        
        title = "動画再生"
        navigationItem.largeTitleDisplayMode = .never
    }
    
    func bind() {
        searchTrackButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: searchTrackButtonTapped)
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .playingStateChanged:
                switch viewModel.state.playingState {
                case .playing:
                    playButton.isSelected = true
                    let rollingAnimation = CABasicAnimation(keyPath: "transform.rotation")
                    rollingAnimation.fromValue = 0
                    rollingAnimation.toValue = CGFloat.pi * 2.0
                    rollingAnimation.duration = 2.0
                    rollingAnimation.repeatDuration = .infinity
                    leftCassetteRole.layer.add(rollingAnimation, forKey: "rollingImage")
                    rightCassetteRole.layer.add(rollingAnimation, forKey: "rollingImage")
                case .pausing:
                    playButton.isSelected = false
                    leftCassetteRole.layer.removeAllAnimations()
                    rightCassetteRole.layer.removeAllAnimations()
                }
            case .playingDurationChanged:
                let durationFormatter = DateFormatter()
                durationFormatter.dateFormat = "mm:ss"
                switch viewModel.state.dataSource {
                case .track(let track):
                    switch track.trackType {
                    case .appleMusic(_):
                        let durationDate = Date(timeIntervalSinceReferenceDate: musicPlayer.currentPlaybackTime)
                        durationLabel.text = durationFormatter.string(from: durationDate)
                    case .youtube(_):
                        durationLabel.text = nil
                    }
                case .youtubeVideo(_):
                    durationLabel.text = nil
                case .userFeed(let feed):
                    switch feed.feedType {
                    case .appleMusic(_):
                        let durationDate = Date(timeIntervalSinceReferenceDate: musicPlayer.currentPlaybackTime)
                        durationLabel.text = durationFormatter.string(from: durationDate)
                    case .youtube(_):
                        durationLabel.text = nil
                    }
                }
                injectMusicPlayerIndicator()
            case .didDeleteFeed:
                self.navigationController?.popViewController(animated: true)
            case .didToggleLikeFeed:
                likeButtonView.setTitle("\(viewModel.state.likeCount)", for: .normal)
                likeButtonView.isSelected.toggle()
            case .didSearchLyrics(let lyrics):
                activityIndicator.stopAnimating()
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: searchTrackButton)
                
                if let lyrics = lyrics {
                    let textView = UITextView()
                    textView.font = Brand.font(for: .mediumStrong)
                    textView.textAlignment = .center
                    textView.textColor = Brand.color(for: .text(.primary))
                    textView.backgroundColor = Brand.color(for: .background(.primary))
                    let vc = UIViewController(nibName: nil, bundle: nil)
                    vc.view = textView
                    vc.title = "歌詞"
                    vc.navigationItem.largeTitleDisplayMode = .never
                    textView.text = lyrics
                    textView.isEditable = false
                    textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
                    let nav = BrandNavigationController(rootViewController: vc)
                    self.present(nav, animated: true, completion: nil)
                } else {
                    showAlert(title: "(´・_・｀)", message: "歌詞が見つかりませんでした")
                }
                
            case .error(let error):
                activityIndicator.stopAnimating()
//                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: searchTrackButton)
                print(error)
                showAlert()
            }
        }
        .store(in: &cancellables)
        
        refreshControl.controlEventPublisher(for: .valueChanged)
            .sink { [unowned self] _ in
                refreshControl.endRefreshing()
            }
            .store(in: &cancellables)
    }
    
    override func loadView() {
        super.loadView()
        
        view = verticalScrollView
        view.backgroundColor = Brand.color(for: .background(.primary))
        
//        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: searchTrackButton)
        
        view.addSubview(scrollStackView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: scrollStackView.topAnchor),
            view.bottomAnchor.constraint(equalTo: scrollStackView.bottomAnchor),
            scrollStackView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - 32),
            scrollStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        let topSpacer = UIView()
        scrollStackView.addArrangedSubview(topSpacer)
        NSLayoutConstraint.activate([
            topSpacer.heightAnchor.constraint(equalToConstant: 48),
            topSpacer.widthAnchor.constraint(equalTo: scrollStackView.widthAnchor),
        ])
        
        scrollStackView.addArrangedSubview(cassetteTapeView)
        NSLayoutConstraint.activate([
            cassetteTapeView.widthAnchor.constraint(equalTo: scrollStackView.widthAnchor),
            cassetteTapeView.heightAnchor.constraint(equalTo: cassetteTapeView.widthAnchor, multiplier: 0.6),
        ])
        
        scrollStackView.addArrangedSubview(musicPlayerIndicatorView)
        NSLayoutConstraint.activate([
            musicPlayerIndicatorView.widthAnchor.constraint(equalTo: scrollStackView.widthAnchor),
        ])
        
        scrollStackView.addArrangedSubview(musicPlayerActionStackView)
        NSLayoutConstraint.activate([
            musicPlayerActionStackView.widthAnchor.constraint(equalTo: scrollStackView.widthAnchor)
        ])
        
        scrollStackView.addArrangedSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.widthAnchor.constraint(equalTo: scrollStackView.widthAnchor),
            playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 1 / 1.91),
        ])
        
        scrollStackView.addArrangedSubview(logoView)
        NSLayoutConstraint.activate([
            logoView.widthAnchor.constraint(equalTo: scrollStackView.widthAnchor),
            logoView.heightAnchor.constraint(equalToConstant: 60),
        ])
        
        scrollStackView.addArrangedSubview(userSectionView)
        NSLayoutConstraint.activate([
            userSectionView.widthAnchor.constraint(equalTo: scrollStackView.widthAnchor),
        ])
        scrollStackView.addArrangedSubview(feedTextView)
        NSLayoutConstraint.activate([
            feedTextView.widthAnchor.constraint(equalTo: scrollStackView.widthAnchor),
        ])
        scrollStackView.addArrangedSubview(actionStackView)
        NSLayoutConstraint.activate([
            actionStackView.widthAnchor.constraint(equalTo: scrollStackView.widthAnchor),
        ])
        
        let bottomSpacer = UIView()
        scrollStackView.addArrangedSubview(bottomSpacer)
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 48),
            bottomSpacer.widthAnchor.constraint(equalTo: scrollStackView.widthAnchor),
        ])
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(backgroundOperation(notification:)), name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer)
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        switch viewModel.state.dataSource {
        case .userFeed(let feed):
            setupAsFeed()
            if let profile = feed.author.thumbnailURL, let url = URL(string: profile) {
                dependencyProvider.imagePipeline.loadImage(url, into: profileImageView)
            }
            cassetteTitleLabel.text = feed.title
            userNameLabel.text = feed.author.name
            feedTextView.text = feed.text
            deleteButton.isHidden = (feed.author.id != dependencyProvider.user.id)
            likeButtonView.isSelected = feed.isLiked
            commentButtonView.setTitle("\(feed.commentCount)", for: .normal)
            likeButtonView.setTitle("\(feed.likeCount)", for: .normal)
            switch feed.feedType {
            case .youtube(let url):
                musicPlayerActionStackView.isHidden = true
                guard let videoId = YouTubeClient(url: url.absoluteString).getId() else { return }
                playerView.load(
                    withVideoId: videoId,
                    playerVars: ["playsinline": 1, "playlist": []])
            case .appleMusic(let songId):
                playerView.isHidden = true
                cassetteTitleLabel.text = "\(feed.title) - \(feed.group.name)"
                playAppleMusicTrack(trackIds: [songId])
                playerView.isHidden = true
            }
        case .youtubeVideo(let videoId):
            setupAsFeed(false)
            cassetteTitleLabel.text = ""
            musicPlayerActionStackView.isHidden = true
            playerView.load(
                withVideoId: videoId,
                playerVars: ["playsinline": 1, "playlist": []])
        case .track(let track):
            setupAsFeed(false)
            switch track.trackType {
            case .appleMusic(let id):
                cassetteTitleLabel.text = "\(track.name) - \(track.artistName)"
                playAppleMusicTrack(trackIds: [id])
                playerView.isHidden = true
            case .youtube(let url):
                guard let videoId = YouTubeClient(url: url.absoluteString).getId() else { return }
                cassetteTitleLabel.text = "\(track.name)"
                musicPlayerActionStackView.isHidden = true
                musicPlayerIndicatorView.isHidden = true
                playerView.load(
                    withVideoId: videoId,
                    playerVars: ["playsinline": 1, "playlist": []])
            }
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: { _ in
            self.viewModel.changePlayingDuration()
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        bottomShellView.addBorders(width: 2, color: .white, positions: [.left, .top, .right])
    }
    
    func injectMusicPlayerIndicator() {
        let thermalSubViews = [
            musicPlayerFirstThermalIndicaterView,
            musicPlayerSecondThermalIndicaterView,
            musicPlayerThirdThermalIndicaterView,
        ]
        for (i, thermalSubView) in zip(thermalSubViews.indices, thermalSubViews) {
            thermalSubView.subviews.forEach {
                thermalSubView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            if viewModel.state.playingThermalIndicators[i] != 0 {
                for _ in 0..<viewModel.state.playingThermalIndicators[i] {
                    let dot = UIView()
                    dot.backgroundColor = Brand.color(for: .brand(.primary))
                    dot.translatesAutoresizingMaskIntoConstraints = false
                    dot.layer.cornerRadius = 4
                    
                    thermalSubView.addArrangedSubview(dot)
                    NSLayoutConstraint.activate([
                        dot.widthAnchor.constraint(equalToConstant: 28),
                        dot.heightAnchor.constraint(equalToConstant: 8),
                    ])
                }
                let spacer = UIView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                thermalSubView.addArrangedSubview(spacer)
            }
        }
    }
    
    func setupAsFeed(_ isFeed: Bool = true) {
        userSectionView.isHidden = !isFeed
        feedTextView.isHidden = !isFeed
        actionStackView.isHidden = !isFeed
    }
    
    func playAppleMusicTrack(trackIds: [String]) {
        let cloudServiceController = SKCloudServiceController()
        SKCloudServiceController.requestAuthorization { status in
            guard status == .authorized else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            cloudServiceController.requestCapabilities { capabilities, error in
                if let error = error {
                    print(error)
                    self.showAlert()
                }
                if !capabilities.contains(.musicCatalogPlayback) {
                    let cloudServiceSetupViewController = SKCloudServiceSetupViewController()
                    cloudServiceSetupViewController.load(options: [.action: SKCloudServiceSetupAction.subscribe], completionHandler: { result, error in
                        if let error = error {
                            print(error)
                            self.showAlert()
                        }
                        guard result else {
                            self.dismiss(animated: true, completion: nil)
                            return
                        }
                    })
                    self.present(cloudServiceSetupViewController, animated: true, completion: nil)
                }
                
                let descriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: trackIds)
                self.musicPlayer.setQueue(with: descriptor)
                self.musicPlayer.play()
            }
            
        }
    }
    
    @objc private func searchTrackButtonTapped() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
        viewModel.searchLyrics()
    }
    
    @objc private func deleteFeedButtonTapped() {
        let alertController = UIAlertController(
            title: "フィードを削除しますか？", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        let acceptAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.default,
            handler: { [unowned self] action in
                viewModel.deleteFeed()
            })
        let cancelAction = UIAlertAction(
            title: "キャンセル", style: UIAlertAction.Style.cancel,
            handler: { action in })
        alertController.addAction(acceptAction)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc private func backward() {
        musicPlayer.currentPlaybackTime -= 15.0
    }
    
    @objc private func backgroundOperation(notification: NSNotification) {
        switch musicPlayer.playbackState {
        case .playing:
            viewModel.changePlayingState(.playing)
        case .paused, .interrupted, .stopped:
            viewModel.changePlayingState(.pausing)
        default: break
        }
    }
    
    @objc private func playButtonTapped() {
        playButton.isSelected ? musicPlayer.pause() : musicPlayer.play()
    }
    
    @objc private func forward() {
        musicPlayer.currentPlaybackTime += 15.0
    }
    
    @objc private func profileTapped() {
        switch viewModel.state.dataSource {
        case .userFeed(let feed):
            let user = feed.author
            let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: user)
            self.navigationController?.pushViewController(vc, animated: true)
        default: break
        }
    }

    @objc private func commentButtonTapped() {
        switch viewModel.state.dataSource {
        case .userFeed(let feed):
            let vc = CommentListViewController(dependencyProvider: dependencyProvider, input: .feedComment(feed))
            let nav = BrandNavigationController(rootViewController: vc)
            present(nav, animated: true, completion: nil)
        default: break
        }
    }
    
    @objc private func likeButtonTapped() {
        likeButtonView.isSelected ? viewModel.unlikeFeed() : viewModel.likeFeed()
    }
    
    @objc private func shareButtonTapped() {
    }
    
    @objc private func shareInstagramButtonTapped() {
    }
    
    @objc private func downloadButtonTapped() {
        switch viewModel.state.dataSource {
        case .userFeed(let feed):
            if let thumbnail = feed.ogpUrl {
                let image = UIImage(url: thumbnail)
                downloadImage(image: image)
            }
        default: break
        }
    }
}

extension PlayTrackViewController: WKYTPlayerViewDelegate {
    func playerViewDidBecomeReady(_ playerView: WKYTPlayerView) {
        playerView.playVideo()
    }
    
    func playerView(_ playerView: WKYTPlayerView, didChangeTo state: WKYTPlayerState) {
        switch state {
        case .playing:
            viewModel.changePlayingState(.playing)
        case .paused, .ended, .unstarted:
            viewModel.changePlayingState(.pausing)
        default: break
        }
    }
}
