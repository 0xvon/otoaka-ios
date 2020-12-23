//
//  PostViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/07.
//

import UIKit
import Endpoint
import Photos
import PhotosUI
import AVKit

final class PostViewController: UIViewController, Instantiable {
    typealias Input = Void
    var dependencyProvider: LoggedInDependencyProvider!

    private var postView: UIView!
    private var postViewHeightConstraint: NSLayoutConstraint!
    private var textView: UITextView!
    private var numOfTextLable: UILabel!
    private var sectionView: UIView!
    private var avatarImageView: UIImageView!
    private var sectionStackView: UIStackView!
    private var postButton: UIButton!
    private var movieThumbnailImageView: UIImageView!
    private var cancelMovieButton: UIButton!
    
    private var postType: PostType = .movie(nil, nil)
    private let maxLength = 140

    enum PostType {
        case movie(URL?, PHAsset?)
        case youtube(URL?)
        case spotify(URL?)
    }

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    lazy var viewModel = PostViewModel(
        apiClient: dependencyProvider.apiClient,
        s3Bucket: dependencyProvider.s3Bucket,
        user: dependencyProvider.user,
        outputHander: { output in
            switch output {
            case .post(let feed):
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            case .error(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: error.localizedDescription)
                }
            }
        }
    )

    func setup() {
        self.view.backgroundColor = style.color.background.get()
        
        postView = UIView()
        postView.translatesAutoresizingMaskIntoConstraints = false
        postView.backgroundColor = style.color.background.get()
        self.view.addSubview(postView)
        
        postViewHeightConstraint = NSLayoutConstraint(
            item: postView!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1,
            constant: 300
        )
        postView.addConstraint(postViewHeightConstraint)
        
        avatarImageView = UIImageView()
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.loadImageAsynchronously(url: URL(string: dependencyProvider.user.thumbnailURL!))
        avatarImageView.layer.cornerRadius = 30
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        postView.addSubview(avatarImageView)
        
        textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = ""
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.font = style.font.large.get()
        textView.textColor = style.color.main.get()
        postView.addSubview(textView)
        
        movieThumbnailImageView = UIImageView()
        movieThumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        movieThumbnailImageView.layer.cornerRadius = 16
        movieThumbnailImageView.contentMode = .scaleAspectFill
        movieThumbnailImageView.clipsToBounds = true
        postView.addSubview(movieThumbnailImageView)
        
        cancelMovieButton = UIButton()
        cancelMovieButton.translatesAutoresizingMaskIntoConstraints = false
        cancelMovieButton.setTitleColor(style.color.main.get(), for: .normal)
        cancelMovieButton.setTitleColor(style.color.subBackground.get(), for: .highlighted)
        cancelMovieButton.setTitle("✗", for: .normal)
        cancelMovieButton.addTarget(self, action: #selector(cancelMovie(_:)), for: .touchUpInside)
        cancelMovieButton.isHidden = true
        cancelMovieButton.titleLabel?.font = style.font.large.get()
        cancelMovieButton.layer.cornerRadius = 12
        cancelMovieButton.layer.borderWidth = 1
        cancelMovieButton.layer.borderColor = style.color.main.get().cgColor
        postView.addSubview(cancelMovieButton)
        
        numOfTextLable = UILabel()
        numOfTextLable.translatesAutoresizingMaskIntoConstraints = false
        numOfTextLable.text = "140"
        numOfTextLable.font = style.font.regular.get()
        postView.addSubview(numOfTextLable)
        
        sectionView = UIView()
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        sectionView.backgroundColor = .clear
        postView.addSubview(sectionView)
        
        let sectionBorderView = UIView()
        sectionBorderView.translatesAutoresizingMaskIntoConstraints = false
        sectionBorderView.backgroundColor = style.color.main.get()
        sectionView.addSubview(sectionBorderView)
        
        setupSectionView()

        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(notification:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        postButton = UIButton()
        postButton.translatesAutoresizingMaskIntoConstraints = false
        postButton.setTitleColor(style.color.main.get(), for: .normal)
        postButton.setTitleColor(style.color.subBackground.get(), for: .highlighted)
        postButton.setTitle("post", for: .normal)
        postButton.addTarget(self, action: #selector(post(_:)), for: .touchUpInside)
        postButton.titleLabel?.font = style.font.large.get()

        let barButtonItem = UIBarButtonItem(customView: postButton)
        self.navigationItem.rightBarButtonItem = barButtonItem
        
        let constraints: [NSLayoutConstraint] = [
            postView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            postView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            postView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            
            avatarImageView.topAnchor.constraint(equalTo: postView.topAnchor, constant: 16),
            avatarImageView.leftAnchor.constraint(equalTo: postView.leftAnchor, constant: 16),
            avatarImageView.heightAnchor.constraint(equalToConstant: 60),
            avatarImageView.widthAnchor.constraint(equalToConstant: 60),
            
            textView.topAnchor.constraint(equalTo: postView.topAnchor, constant: 16),
            textView.rightAnchor.constraint(equalTo: postView.rightAnchor, constant: -16),
            textView.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 8),
            
            sectionView.heightAnchor.constraint(equalToConstant: 92),
            sectionView.leftAnchor.constraint(equalTo: postView.leftAnchor),
            sectionView.rightAnchor.constraint(equalTo: postView.rightAnchor),
            sectionView.bottomAnchor.constraint(equalTo: postView.bottomAnchor),
            
            numOfTextLable.rightAnchor.constraint(equalTo: postView.rightAnchor, constant: -16),
            numOfTextLable.bottomAnchor.constraint(equalTo: sectionView.topAnchor, constant: -16),
            
            movieThumbnailImageView.heightAnchor.constraint(equalToConstant: 100),
            movieThumbnailImageView.widthAnchor.constraint(equalToConstant: 200),
            movieThumbnailImageView.rightAnchor.constraint(equalTo: postView.rightAnchor, constant: -16),
            movieThumbnailImageView.bottomAnchor.constraint(equalTo: numOfTextLable.topAnchor, constant: -16),
            movieThumbnailImageView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            
            cancelMovieButton.topAnchor.constraint(equalTo: movieThumbnailImageView.topAnchor, constant: -12),
            cancelMovieButton.rightAnchor.constraint(equalTo: movieThumbnailImageView.rightAnchor, constant: 12),
            cancelMovieButton.widthAnchor.constraint(equalToConstant: 24),
            cancelMovieButton.heightAnchor.constraint(equalToConstant: 24),
            
            sectionBorderView.rightAnchor.constraint(equalTo: sectionView.rightAnchor),
            sectionBorderView.leftAnchor.constraint(equalTo: sectionView.leftAnchor),
            sectionBorderView.topAnchor.constraint(equalTo: sectionView.topAnchor),
            sectionBorderView.heightAnchor.constraint(equalToConstant: 1),
        ]
        NSLayoutConstraint.activate(constraints)
        
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

    @objc private func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboard = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                resizePostView(keyboardRect: keyboard.cgRectValue)
            } else {
                resizePostView(keyboardRect: CGRect(x: 0, y: 0, width: 0, height: 0))
            }
                
        }
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
            title: "YouTubeから検索", message: nil, preferredStyle: UIAlertController.Style.alert)

        let cancelAction = UIAlertAction(
            title: "cancel", style: UIAlertAction.Style.cancel,
            handler: { action in
                print("close")
        })
        let doneAction = UIAlertAction(title: "ok", style: .default, handler: { [weak alertController] action in
            if let textFields = alertController?.textFields, let text = textFields.first!.text, let url = URL(string: text) {
                let youTubeClient = YouTubeClient(url: text)
                let thumbnailUrl = youTubeClient.getThumbnailUrl()
                self.movieThumbnailImageView.loadImageAsynchronously(url: thumbnailUrl)
                self.cancelMovieButton.isHidden = false
                self.postType = .youtube(url)
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

    @objc private func post(_ sender: Any) {
        self.viewModel.post(postType: self.postType, text: self.textView.text ?? "")
    }
    
    @objc private func cancelMovie(_ sender: UIButton) {
        self.postType = .movie(nil, nil)
        self.movieThumbnailImageView.image = nil
        self.cancelMovieButton.isHidden = true
    }
    
    func resizePostView(keyboardRect: CGRect) {
        let viewHeight = self.view.frame.height - self.view.safeAreaInsets.top
        let postViewHeight = viewHeight - keyboardRect.height
        postViewHeightConstraint.constant = postViewHeight
    }
}

extension PostViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let textCount = textView.text.count
        numOfTextLable.text = "\(maxLength - textCount)"
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
            let thumbnail = generateThumbnailFromVideo(videoUrl!.absoluteURL!)
            movieThumbnailImageView.image = thumbnail
            cancelMovieButton.isHidden = false
            self.postType = .movie(videoUrl?.absoluteURL, asset)
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
