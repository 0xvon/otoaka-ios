//
//  PostViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/07.
//

import Combine
import UIKit
import Endpoint
import Photos
import PhotosUI
import AVKit
import KeyboardGuide
import UITextView_Placeholder

final class PostViewController: UIViewController, Instantiable {
    typealias Input = Void

    private lazy var postView: UIView = {
        let postView = UIView()
        postView.translatesAutoresizingMaskIntoConstraints = false
        postView.backgroundColor = Brand.color(for: .background(.primary))
        return postView
    }()
    private lazy var feedPreview: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Brand.color(for: .background(.cellSelected))
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        view.clipsToBounds = true
        return view
    }()
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = ""
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.placeholder = "歌詞やMCでの言葉を添えよう！"
        textView.placeholderTextView.textAlignment = .center
        textView.placeholderColor = Brand.color(for: .background(.secondary))
        textView.font = Brand.font(for: .xlargeStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textAlignment = .center
        
        textView.returnKeyType = .done
        return textView
    }()
    private lazy var numOfTextLabel: UILabel = {
        let numOfTextLabel = UILabel()
        numOfTextLabel.translatesAutoresizingMaskIntoConstraints = false
        numOfTextLabel.text = "\(viewModel.state.maxLength)"
        numOfTextLabel.font = Brand.font(for: .medium)
        return numOfTextLabel
    }()
    private lazy var sectionView: UIView = {
        let sectionView = UIView()
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        sectionView.backgroundColor = .clear
        return sectionView
    }()
    private lazy var sectionBorderView: UIView = {
        let sectionBorderView = UIView()
        sectionBorderView.translatesAutoresizingMaskIntoConstraints = false
        sectionBorderView.backgroundColor = Brand.color(for: .text(.primary))
        return sectionBorderView
    }()
    private lazy var avatarImageView: UIImageView = {
        let avatarImageView = UIImageView()
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        return avatarImageView
    }()
    private lazy var userNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .mediumStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var trackInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .smallStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var postButton: UIButton = {
        let postButton = UIButton()
        postButton.translatesAutoresizingMaskIntoConstraints = false
        postButton.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        postButton.setTitleColor(Brand.color(for: .text(.toggle)), for: .highlighted)
        postButton.setTitle("post", for: .normal)
        postButton.titleLabel?.font = Brand.font(for: .largeStrong)
        return postButton
    }()
    private lazy var movieThumbnailImageView: UIImageView = {
        let movieThumbnailImageView = UIImageView()
        movieThumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        movieThumbnailImageView.layer.cornerRadius = 16
        movieThumbnailImageView.contentMode = .scaleAspectFill
        movieThumbnailImageView.clipsToBounds = true
        movieThumbnailImageView.layer.opacity = 0.6
        return movieThumbnailImageView
    }()
    private lazy var cancelMovieButton: UIButton = {
        let cancelMovieButton = UIButton()
        cancelMovieButton.translatesAutoresizingMaskIntoConstraints = false
        cancelMovieButton.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        cancelMovieButton.setTitleColor(Brand.color(for: .background(.cellSelected)), for: .highlighted)
        cancelMovieButton.setTitle("✗", for: .normal)
        cancelMovieButton.addTarget(self, action: #selector(cancelMovie(_:)), for: .touchUpInside)
        cancelMovieButton.isHidden = true
        cancelMovieButton.titleLabel?.font = Brand.font(for: .largeStrong)
        cancelMovieButton.layer.cornerRadius = 12
        cancelMovieButton.layer.borderWidth = 1
        cancelMovieButton.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        return cancelMovieButton
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
    
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: PostViewModel
    var cancellables: Set<AnyCancellable> = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = PostViewModel(dependencyProvider: dependencyProvider)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    func bind() {
        postButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: postButtonTapped)
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didPostUserFeed(_):
                navigationController?.popViewController(animated: true)
            case .updateSubmittableState(let pageState):
                switch pageState {
                case .editting(let submittable):
                    activityIndicator.stopAnimating()
                    navigationItem.rightBarButtonItem = submittable ? UIBarButtonItem(customView: postButton): nil
                    postButton.isHidden = !submittable
                case .loading:
                    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
                    activityIndicator.startAnimating()
                }
            case .reportError(let error):
                showAlert(title: "エラー", message: String(describing: error))
            case .didSelectPost:
                trackInfoLabel.text = viewModel.state.title
                if let thumbnail = viewModel.state.thumbnailUrl {
                    dependencyProvider.imagePipeline.loadImage(thumbnail, into: movieThumbnailImageView)
                }
            }
        }.store(in: &cancellables)
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.title = "フィード投稿"
        self.navigationItem.largeTitleDisplayMode = .never
        
        self.view.addSubview(postView)
        NSLayoutConstraint.activate([
            postView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            postView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            postView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            postView.bottomAnchor.constraint(equalTo: self.view.keyboardSafeArea.layoutGuide.bottomAnchor),
        ])
        
        postView.addSubview(feedPreview)
        NSLayoutConstraint.activate([
            feedPreview.topAnchor.constraint(equalTo: postView.topAnchor, constant: 24),
            feedPreview.leftAnchor.constraint(equalTo: postView.leftAnchor, constant: 16),
            feedPreview.rightAnchor.constraint(equalTo: postView.rightAnchor, constant: -16),
            feedPreview.heightAnchor.constraint(equalTo: feedPreview.widthAnchor, multiplier: 1 / 1.91),
        ])
        
        postView.addSubview(sectionView)
        NSLayoutConstraint.activate([
            sectionView.heightAnchor.constraint(equalToConstant: 92),
            sectionView.leftAnchor.constraint(equalTo: postView.leftAnchor),
            sectionView.rightAnchor.constraint(equalTo: postView.rightAnchor),
            sectionView.bottomAnchor.constraint(equalTo: postView.bottomAnchor),
        ])
        
        sectionView.addSubview(sectionBorderView)
        NSLayoutConstraint.activate([
            sectionBorderView.rightAnchor.constraint(equalTo: sectionView.rightAnchor),
            sectionBorderView.leftAnchor.constraint(equalTo: sectionView.leftAnchor),
            sectionBorderView.topAnchor.constraint(equalTo: sectionView.topAnchor),
            sectionBorderView.heightAnchor.constraint(equalToConstant: 1),
        ])
        setupSectionView()
        
        postView.addSubview(numOfTextLabel)
        NSLayoutConstraint.activate([
            numOfTextLabel.rightAnchor.constraint(equalTo: postView.rightAnchor, constant: -16),
            numOfTextLabel.bottomAnchor.constraint(equalTo: sectionView.topAnchor, constant: -16),
        ])
        
        feedPreview.addSubview(movieThumbnailImageView)
        NSLayoutConstraint.activate([
            movieThumbnailImageView.rightAnchor.constraint(equalTo: feedPreview.rightAnchor),
            movieThumbnailImageView.leftAnchor.constraint(equalTo: feedPreview.leftAnchor),
            movieThumbnailImageView.topAnchor.constraint(equalTo: feedPreview.topAnchor),
            movieThumbnailImageView.bottomAnchor.constraint(equalTo: feedPreview.bottomAnchor),
        ])
        
        feedPreview.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: feedPreview.topAnchor, constant: 16),
            avatarImageView.leftAnchor.constraint(equalTo: feedPreview.leftAnchor, constant: 16),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
        ])
        
        feedPreview.addSubview(userNameLabel)
        NSLayoutConstraint.activate([
            userNameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            userNameLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 8),
            userNameLabel.rightAnchor.constraint(equalTo: feedPreview.rightAnchor, constant: 8),
        ])
        
        feedPreview.addSubview(trackInfoLabel)
        NSLayoutConstraint.activate([
            trackInfoLabel.topAnchor.constraint(equalTo: userNameLabel.bottomAnchor, constant: 4),
            trackInfoLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 8),
            trackInfoLabel.rightAnchor.constraint(equalTo: feedPreview.rightAnchor, constant: -8),
        ])
        
        feedPreview.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            textView.rightAnchor.constraint(equalTo: feedPreview.rightAnchor, constant: -8),
            textView.leftAnchor.constraint(equalTo: feedPreview.leftAnchor, constant: 8),
            textView.bottomAnchor.constraint(equalTo: feedPreview.bottomAnchor, constant: -8),
        ])
        
        
//        postView.addSubview(cancelMovieButton)
//        NSLayoutConstraint.activate([
//            cancelMovieButton.topAnchor.constraint(equalTo: movieThumbnailImageView.topAnchor, constant: -12),
//            cancelMovieButton.rightAnchor.constraint(equalTo: movieThumbnailImageView.rightAnchor, constant: 12),
//            cancelMovieButton.widthAnchor.constraint(equalToConstant: 24),
//            cancelMovieButton.heightAnchor.constraint(equalToConstant: 24),
//        ])
        
        userNameLabel.text = dependencyProvider.user.name
        trackInfoLabel.text = nil
        if let thumbnailURL = dependencyProvider.user.thumbnailURL.flatMap(URL.init(string: )) {
            dependencyProvider.imagePipeline.loadImage(thumbnailURL, into: avatarImageView)
        }

        textView.becomeFirstResponder()
    }
    
    func setupSectionView () {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        sectionView.addSubview(stackView)
        
        let movieButtonView = UIView()
        movieButtonView.isHidden = true
        movieButtonView.backgroundColor = .clear
        stackView.addArrangedSubview(movieButtonView)
        
        let movieButtonImage = UIImageView()
        movieButtonImage.image = UIImage(named: "image")
        movieButtonImage.clipsToBounds = true
        movieButtonImage.translatesAutoresizingMaskIntoConstraints = false
        movieButtonView.addSubview(movieButtonImage)
        
        let movieButton = UIButton()
        movieButton.backgroundColor = .clear
        movieButton.translatesAutoresizingMaskIntoConstraints = false
        movieButton.addTarget(self, action: #selector(searchMovie(_:)), for: .touchUpInside)
        movieButtonView.addSubview(movieButton)
        
        let youtubeButtonView = UIView()
        youtubeButtonView.backgroundColor = .clear
        stackView.addArrangedSubview(youtubeButtonView)
        
        let youtubeButtonImage = UIImageView()
        youtubeButtonImage.image = UIImage(named: "movie")
        youtubeButtonImage.clipsToBounds = true
        youtubeButtonImage.translatesAutoresizingMaskIntoConstraints = false
        youtubeButtonView.addSubview(youtubeButtonImage)
        
        let searchTitleLabel = UILabel()
        searchTitleLabel.text = "動画を選択"
        searchTitleLabel.textAlignment = .center
        searchTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        searchTitleLabel.font = Brand.font(for: .largeStrong)
        searchTitleLabel.textColor = Brand.color(for: .text(.primary))
        youtubeButtonView.addSubview(searchTitleLabel)
        
        let youtubeButton = UIButton()
        youtubeButton.backgroundColor = .clear
        youtubeButton.translatesAutoresizingMaskIntoConstraints = false
        youtubeButton.addTarget(self, action: #selector(searchYoutube(_:)), for: .touchUpInside)
        youtubeButtonView.addSubview(youtubeButton)
        
//        let spotifyButtonView = UIView()
//        spotifyButtonView.backgroundColor = .clear
//        stackView.addArrangedSubview(spotifyButtonView)
//
//        let spotifyButtonImage = UIImageView()
//        spotifyButtonImage.image = UIImage(named: "music")
//        spotifyButtonImage.clipsToBounds = true
//        spotifyButtonImage.translatesAutoresizingMaskIntoConstraints = false
//        spotifyButtonView.addSubview(spotifyButtonImage)
//
//        let spotifyButton = UIButton()
//        spotifyButton.backgroundColor = .clear
//        spotifyButton.translatesAutoresizingMaskIntoConstraints = false
//        spotifyButton.addTarget(self, action: #selector(searchSpotify(_:)), for: .touchUpInside)
//        spotifyButtonView.addSubview(spotifyButton)
        
        let constraints: [NSLayoutConstraint] = [
            stackView.heightAnchor.constraint(equalToConstant: 60),
            stackView.centerYAnchor.constraint(equalTo: sectionView.centerYAnchor),
//            stackView.leftAnchor.constraint(equalTo: sectionView.leftAnchor, constant: 16),
            stackView.centerXAnchor.constraint(equalTo: sectionView.centerXAnchor),
            
            movieButtonView.widthAnchor.constraint(equalToConstant: 60),
            
            movieButtonImage.widthAnchor.constraint(equalToConstant: 40),
            movieButtonImage.heightAnchor.constraint(equalToConstant: 40),
            movieButtonImage.centerYAnchor.constraint(equalTo: movieButtonView.centerYAnchor),
            movieButtonImage.centerXAnchor.constraint(equalTo: movieButtonView.centerXAnchor),
            
            movieButton.topAnchor.constraint(equalTo: movieButtonView.topAnchor),
            movieButton.bottomAnchor.constraint(equalTo: movieButtonView.bottomAnchor),
            movieButton.rightAnchor.constraint(equalTo: movieButtonView.rightAnchor),
            movieButton.leftAnchor.constraint(equalTo: movieButtonView.leftAnchor),
            
            youtubeButtonView.widthAnchor.constraint(equalToConstant: 140),
            
            youtubeButtonImage.widthAnchor.constraint(equalToConstant: 40),
            youtubeButtonImage.heightAnchor.constraint(equalToConstant: 40),
            youtubeButtonImage.leftAnchor.constraint(equalTo: youtubeButtonView.leftAnchor),
            youtubeButtonImage.centerYAnchor.constraint(equalTo: youtubeButtonView.centerYAnchor),
            
            searchTitleLabel.leftAnchor.constraint(equalTo: youtubeButtonImage.rightAnchor, constant: 8),
            searchTitleLabel.rightAnchor.constraint(equalTo: youtubeButtonView.rightAnchor),
            searchTitleLabel.centerYAnchor.constraint(equalTo: youtubeButtonView.centerYAnchor),
            
            youtubeButton.topAnchor.constraint(equalTo: youtubeButtonView.topAnchor),
            youtubeButton.bottomAnchor.constraint(equalTo: youtubeButtonView.bottomAnchor),
            youtubeButton.rightAnchor.constraint(equalTo: youtubeButtonView.rightAnchor),
            youtubeButton.leftAnchor.constraint(equalTo: youtubeButtonView.leftAnchor),
            
//            spotifyButtonView.widthAnchor.constraint(equalToConstant: 60),
//
//            spotifyButtonImage.widthAnchor.constraint(equalToConstant: 40),
//            spotifyButtonImage.heightAnchor.constraint(equalToConstant: 40),
//            spotifyButtonImage.centerYAnchor.constraint(equalTo: spotifyButtonView.centerYAnchor),
//            spotifyButtonImage.centerXAnchor.constraint(equalTo: spotifyButtonView.centerXAnchor),
//
//            spotifyButton.topAnchor.constraint(equalTo: spotifyButtonView.topAnchor),
//            spotifyButton.bottomAnchor.constraint(equalTo: spotifyButtonView.bottomAnchor),
//            spotifyButton.rightAnchor.constraint(equalTo: spotifyButtonView.rightAnchor),
//            spotifyButton.leftAnchor.constraint(equalTo: spotifyButtonView.leftAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc private func searchMovie(_ sender: Any) {
//        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
//            let picker = UIImagePickerController()
//            picker.sourceType = .photoLibrary
//            picker.delegate = self
//            picker.mediaTypes = ["public.movie"]
//            self.present(picker, animated: true, completion: nil)
//        }
    }
    
    @objc private func searchYoutube(_ sender: Any) {
        print("search")
        let vc = SelectGroupViewController(dependencyProvider: dependencyProvider)
        vc.listen { [unowned self] group, track in
            viewModel.didSelectTrack(group: group, track: track)
        }
        let nav = BrandNavigationController(rootViewController: vc)
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc private func searchSpotify(_ sender: Any) {
        print("c")
    }
    
    @objc private func cancelMovie(_ sender: UIButton) {
//        self.viewModel.didUpdatePost(post: .none)
    }
    
    @objc func postButtonTapped() {
        guard let ogpImage: UIImage = feedPreview.getSnapShot() else { return }
        UIImageWriteToSavedPhotosAlbum(ogpImage, self, #selector(didFinishSavingImage(_:didFinishSavingWithError:contextInfo:)), nil)
        print("hello")
    }
    
    @objc func didFinishSavingImage(_ image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutableRawPointer) {
        
        // 結果によって出すアラートを変更する
        var title = "保存完了"
        var message = "カメラロールに保存しました"
        
        if error != nil {
            title = "エラー"
            message = "保存に失敗しました"
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}

extension PostViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let textCount = textView.text.count
        numOfTextLabel.text = "\(viewModel.state.maxLength - textCount)"
        
        let text: String? = textView.text.isEmpty ? nil : textView.text
        viewModel.didUpdateInputText(text: text)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

//extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//    func imagePickerController(
//        _ picker: UIImagePickerController,
//        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
//    ) {
//        let key = UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerMediaURL")
//        let videoUrl = info[key] as? NSURL
//        if let asset = info[.phAsset] as? PHAsset {
//            viewModel.didUpdatePost(post: .movie(videoUrl! as URL, asset))
//            self.dismiss(animated: true, completion: nil)
//        }
//    }
//
//    private func generateThumbnailFromVideo(_ url: URL) -> UIImage? {
//        let asset = AVAsset(url: url)
//        let imageGenerator = AVAssetImageGenerator(asset: asset)
//        imageGenerator.appliesPreferredTrackTransform = true
//        var time = asset.duration
//        time.value = min(time.value, 2)
//        do {
//            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
//            return UIImage(cgImage: imageRef)
//        } catch {
//            return nil
//        }
//    }
//}
