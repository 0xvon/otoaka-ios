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

final class PostViewController: UIViewController, Instantiable {
    typealias Input = Void

    private lazy var postView: UIView = {
        let postView = UIView()
        postView.translatesAutoresizingMaskIntoConstraints = false
        postView.backgroundColor = Brand.color(for: .background(.primary))
        return postView
    }()
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = ""
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.font = Brand.font(for: .largeStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        return textView
    }()
    private lazy var numOfTextLabel: UILabel = {
        let numOfTextLabel = UILabel()
        numOfTextLabel.translatesAutoresizingMaskIntoConstraints = false
        numOfTextLabel.text = "140"
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
        avatarImageView.layer.cornerRadius = 30
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        return avatarImageView
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
    
    func bind() {
        postButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: viewModel.post)
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didPostArtistFeed(_):
                self.dismiss(animated: true, completion: nil)
            case .updateSubmittableState(let pageState):
                switch pageState {
                case .completed:
                    activityIndicator.stopAnimating()
                case .editting(let submittable):
                    navigationItem.rightBarButtonItem = submittable ? UIBarButtonItem(customView: postButton): nil
                    postButton.isHidden = !submittable
                case .loading:
                    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
                    activityIndicator.startAnimating()
                }
            case .didGetThumbnail(let state):
                switch state {
                case .movie(let url):
                    let image = generateThumbnailFromVideo(url)
                    movieThumbnailImageView.image = image
                    cancelMovieButton.isHidden = false
                case .youtube(let url):
                    dependencyProvider.imagePipeline.loadImage(url, into: movieThumbnailImageView)
                    cancelMovieButton.isHidden = false
                case .none:
                    movieThumbnailImageView.image = nil
                    cancelMovieButton.isHidden = true
                }
            case .reportError(let error):
                showAlert(title: "エラー", message: error.localizedDescription)
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
        
        postView.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: postView.topAnchor, constant: 16),
            avatarImageView.leftAnchor.constraint(equalTo: postView.leftAnchor, constant: 16),
            avatarImageView.heightAnchor.constraint(equalToConstant: 60),
            avatarImageView.widthAnchor.constraint(equalToConstant: 60),
        ])
        
        postView.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: postView.topAnchor, constant: 16),
            textView.rightAnchor.constraint(equalTo: postView.rightAnchor, constant: -16),
            textView.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 8),
        ])
        
        postView.addSubview(movieThumbnailImageView)
        NSLayoutConstraint.activate([
            movieThumbnailImageView.heightAnchor.constraint(equalToConstant: 100),
            movieThumbnailImageView.widthAnchor.constraint(equalToConstant: 200),
            movieThumbnailImageView.rightAnchor.constraint(equalTo: postView.rightAnchor, constant: -16),
            movieThumbnailImageView.bottomAnchor.constraint(equalTo: numOfTextLabel.topAnchor, constant: -16),
            movieThumbnailImageView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
        ])
        
        postView.addSubview(cancelMovieButton)
        NSLayoutConstraint.activate([
            cancelMovieButton.topAnchor.constraint(equalTo: movieThumbnailImageView.topAnchor, constant: -12),
            cancelMovieButton.rightAnchor.constraint(equalTo: movieThumbnailImageView.rightAnchor, constant: 12),
            cancelMovieButton.widthAnchor.constraint(equalToConstant: 24),
            cancelMovieButton.heightAnchor.constraint(equalToConstant: 24),
        ])
        
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
            stackView.leftAnchor.constraint(equalTo: sectionView.leftAnchor, constant: 16),
            
            movieButtonView.widthAnchor.constraint(equalToConstant: 60),
            
            movieButtonImage.widthAnchor.constraint(equalToConstant: 40),
            movieButtonImage.heightAnchor.constraint(equalToConstant: 40),
            movieButtonImage.centerYAnchor.constraint(equalTo: movieButtonView.centerYAnchor),
            movieButtonImage.centerXAnchor.constraint(equalTo: movieButtonView.centerXAnchor),
            
            movieButton.topAnchor.constraint(equalTo: movieButtonView.topAnchor),
            movieButton.bottomAnchor.constraint(equalTo: movieButtonView.bottomAnchor),
            movieButton.rightAnchor.constraint(equalTo: movieButtonView.rightAnchor),
            movieButton.leftAnchor.constraint(equalTo: movieButtonView.leftAnchor),
            
            youtubeButtonView.widthAnchor.constraint(equalToConstant: 60),
            
            youtubeButtonImage.widthAnchor.constraint(equalToConstant: 40),
            youtubeButtonImage.heightAnchor.constraint(equalToConstant: 40),
            youtubeButtonImage.centerYAnchor.constraint(equalTo: youtubeButtonView.centerYAnchor),
            youtubeButtonImage.centerXAnchor.constraint(equalTo: youtubeButtonView.centerXAnchor),
            
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
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    @objc private func searchYoutube(_ sender: Any) {
        let alertController = UIAlertController(
            title: "YouTubeの動画URLを入力", message: nil, preferredStyle: UIAlertController.Style.alert)

        let cancelAction = UIAlertAction(
            title: "cancel", style: UIAlertAction.Style.cancel,
            handler: { action in })
        let doneAction = UIAlertAction(title: "ok", style: .default, handler: { [unowned self] action in
            if let textFields = alertController.textFields, let text = textFields.first!.text, let url = URL(string: text) {
                viewModel.didUpdatePost(post: .youtube(url))
                viewModel.getYouTubeThumbnail(url: text)
            }
        })
        alertController.addTextField(configurationHandler: {(text: UITextField!) -> Void in
            text.text = ""
            text.placeholder = "URLを入力"
            text.keyboardType = .URL
            text.tag = 1
        })
        alertController.addAction(cancelAction)
        alertController.addAction(doneAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc private func searchSpotify(_ sender: Any) {
        print("c")
    }
    
    @objc private func cancelMovie(_ sender: UIButton) {
        self.viewModel.didUpdatePost(post: nil)
    }
}

extension PostViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let textCount = textView.text.count
        numOfTextLabel.text = "\(viewModel.state.maxLength - textCount)"
        
        let text: String? = textView.text.isEmpty ? nil : textView.text
        viewModel.didUpdateInputText(text: text)
    }
}

extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let key = UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerMediaURL")
        let videoUrl = info[key] as? NSURL
        if let asset = info[.phAsset] as? PHAsset {
            viewModel.didUpdatePost(post: .movie(videoUrl! as URL, asset))
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func generateThumbnailFromVideo(_ url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        var time = asset.duration
        time.value = min(time.value, 2)
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            return nil
        }
    }
}
