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
    
    private lazy var playerView: WKYTPlayerView = {
        let playerView = WKYTPlayerView()
        playerView.delegate = self
        playerView.backgroundColor = .clear
        playerView.translatesAutoresizingMaskIntoConstraints = false
        return playerView
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        stackView.axis = .horizontal
        return stackView
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
        textView.font = Brand.font(for: .xlargeStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textAlignment = .center
        textView.isScrollEnabled = false
        textView.isSelectable = false
        textView.isUserInteractionEnabled = false
        textView.backgroundColor = .clear
        return textView
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
            UIImage(named: "insta"),
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
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didDeleteFeed:
                self.navigationController?.popViewController(animated: true)
            case .didToggleLikeFeed:
                likeButtonView.setTitle("\(viewModel.state.likeCount)", for: .normal)
                likeButtonView.isSelected.toggle()
            case .error(let error):
                print(error)
                showAlert()
            }
        }
        .store(in: &cancellables)
    }
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor, constant: -16),
        ])
        
        view.addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            playerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 1/1.91),
        ])
        
        switch viewModel.state.dataSource {
        case .userFeed(let feed):
            setupFeedView()
            if let profile = feed.author.thumbnailURL, let url = URL(string: profile) {
                dependencyProvider.imagePipeline.loadImage(url, into: profileImageView)
            }
            userNameLabel.text = feed.author.name
            feedTextView.text = feed.text
            stackView.isHidden = false
            deleteButton.isHidden = (feed.author.id != dependencyProvider.user.id)
            likeButtonView.isSelected = feed.isLiked
            commentButtonView.setTitle("\(feed.commentCount)", for: .normal)
            likeButtonView.setTitle("\(feed.likeCount)", for: .normal)
            switch feed.feedType {
            case .youtube(let url):
                guard let videoId = YouTubeClient(url: url.absoluteString).getId() else { return }
                playerView.load(
                    withVideoId: videoId,
                    playerVars: ["playsinline": 1, "playlist": []])
            }
        case .youtubeVideo(let videoId):
            NSLayoutConstraint.activate([
                playerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
            stackView.isHidden = true
            playerView.load(
                withVideoId: videoId,
                playerVars: ["playsinline": 1, "playlist": []])
        case .track(let track):
            switch track.trackType {
            case .appleMusic(let id):
                playAppleMusicTrack(trackIds: [id])
            case .youtube(_): break // TODO
            }
            
        }
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
    
    func setupFeedView() {
        view.addSubview(profileImageView)
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor, multiplier: 1),
            profileImageView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor, constant: 16),
            profileImageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
        ])
        
        view.addSubview(userNameLabel)
        NSLayoutConstraint.activate([
            userNameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor),
            userNameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8),
            userNameLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
        ])
        
        view.addSubview(feedTextView)
        NSLayoutConstraint.activate([
            feedTextView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            feedTextView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            feedTextView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
        ])
        
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: feedTextView.bottomAnchor, constant: 16),
        ])
        
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

        self.present(alertController, animated: true, completion: nil)
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
        switch viewModel.state.dataSource {
        case .userFeed(let feed):
            shareWithTwitter(type: .feed(feed))
        default: break
        }
    }
    
    @objc private func shareInstagramButtonTapped() {
        switch viewModel.state.dataSource {
        case .userFeed(let feed):
            shareFeedWithInstagram(feed: feed)
        default: break
        }
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
//    func playerViewDidBecomeReady(_ playerView: WKYTPlayerView) {
//        playerView.playVideo()
//    }
}
