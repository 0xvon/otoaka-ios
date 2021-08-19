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
    typealias Input = PostViewModel.Input

    private lazy var postScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    private lazy var postView: UIStackView = {
        let postView = UIStackView()
        postView.translatesAutoresizingMaskIntoConstraints = false
        postView.backgroundColor = Brand.color(for: .background(.primary))
        postView.axis = .vertical
        postView.spacing = 16
        
        let topSpacer = UIView()
        topSpacer.translatesAutoresizingMaskIntoConstraints = false
        postView.addArrangedSubview(topSpacer)
        NSLayoutConstraint.activate([
            topSpacer.widthAnchor.constraint(equalTo: postView.widthAnchor),
            topSpacer.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        postView.addArrangedSubview(textContainerView)
        NSLayoutConstraint.activate([
            textContainerView.widthAnchor.constraint(equalTo: postView.widthAnchor)
        ])
        
        postView.addArrangedSubview(postContentStackView)
        NSLayoutConstraint.activate([
            postContentStackView.widthAnchor.constraint(equalTo: postView.widthAnchor),
        ])
        
        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        postView.addArrangedSubview(bottomSpacer)
        NSLayoutConstraint.activate([
            bottomSpacer.widthAnchor.constraint(equalTo: postView.widthAnchor),
            bottomSpacer.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        return postView
    }()
    private lazy var textContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.topAnchor),
            avatarImageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
        ])
        
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            textView.rightAnchor.constraint(equalTo: view.rightAnchor),
            textView.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 8),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.heightAnchor.constraint(greaterThanOrEqualTo: avatarImageView.heightAnchor, multiplier: 1),
        ])
        
        return view
    }()
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = ""
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.placeholder = "セットリスト・MCで言っていたこと・起こった出来事・友達との思い出を記録しよう"
        textView.placeholderTextView.textAlignment = .left
        textView.placeholderColor = Brand.color(for: .background(.secondary))
        textView.font = Brand.font(for: .mediumStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .left
        
        textView.returnKeyType = .done
        return textView
    }()
    private lazy var postContentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 4
        stackView.axis = .horizontal
        stackView.backgroundColor = .clear
        stackView.distribution = .fillEqually
        
        stackView.addArrangedSubview(uploadedImageView)
        stackView.addArrangedSubview(selectedGroupView)
        stackView.addArrangedSubview(playlistView)
        
        return stackView
    }()
    private lazy var uploadedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(uploadedImageTapped)))
        
        return imageView
    }()
    private lazy var selectedGroupView: GroupCellContent = {
        let content = UINib(nibName: "GroupCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! GroupCellContent
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 300),
        ])
        content.addTarget(self, action: #selector(selectedGroupTapped), for: .touchUpInside)
        return content
    }()
    private lazy var playlistView: PlaylistCell = {
        let content = PlaylistCell()
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 300),
        ])
        return content
    }()
    private lazy var numOfTextLabel: UILabel = {
        let numOfTextLabel = UILabel()
        numOfTextLabel.translatesAutoresizingMaskIntoConstraints = false
        numOfTextLabel.text = "\(viewModel.state.maxLength)"
        numOfTextLabel.font = Brand.font(for: .medium)
        numOfTextLabel.textColor = Brand.color(for: .text(.primary))
        return numOfTextLabel
    }()
    private lazy var sectionView: UIView = {
        let sectionView = UIView()
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        sectionView.backgroundColor = .clear
        
        let sectionBorderView = UIView()
        sectionBorderView.translatesAutoresizingMaskIntoConstraints = false
        sectionBorderView.backgroundColor = Brand.color(for: .text(.primary))
        sectionView.addSubview(sectionBorderView)
        NSLayoutConstraint.activate([
            sectionBorderView.rightAnchor.constraint(equalTo: sectionView.rightAnchor),
            sectionBorderView.leftAnchor.constraint(equalTo: sectionView.leftAnchor),
            sectionBorderView.topAnchor.constraint(equalTo: sectionView.topAnchor),
            sectionBorderView.heightAnchor.constraint(equalToConstant: 1),
        ])
        
        return sectionView
    }()
    private lazy var avatarImageView: UIImageView = {
        let avatarImageView = UIImageView()
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = 20
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
        movieThumbnailImageView.layer.opacity = 0.6
        return movieThumbnailImageView
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
        self.viewModel = PostViewModel(dependencyProvider: dependencyProvider, input: input)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
        
        viewModel.viewDidLoad()
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
            case .didPost(_):
                navigationController?.popToRootViewController(animated: true)
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
                print(error)
                showAlert()
            case .didUpdateContent:
                textView.text = viewModel.state.text
                uploadedImageView.isHidden = viewModel.state.images.isEmpty
                selectedGroupView.isHidden = viewModel.state.groups.isEmpty
                playlistView.isHidden = viewModel.state.tracks.isEmpty
                
                if let image = viewModel.state.images.first {
                    uploadedImageView.image = image
                }
                if let group = viewModel.state.groups.first {
                    selectedGroupView.inject(input: (group: group, imagePipeline: dependencyProvider.imagePipeline))
                }
                if !viewModel.state.tracks.isEmpty {
                    playlistView.inject(input: (tracks: viewModel.state.tracks, isEdittable: true, imagePipeline: dependencyProvider.imagePipeline))
                }
            }
        }.store(in: &cancellables)
        
        playlistView.listen { [unowned self] output in
            switch output {
            case .playButtonTapped(let track):
                let vc = PlayTrackViewController(dependencyProvider: dependencyProvider, input: .track(track))
                self.navigationController?.pushViewController(vc, animated: true)
            case .seeMoreTapped:
                let vc = TrackListViewController(dependencyProvider: dependencyProvider, input: .selectedPlaylist(viewModel.state.tracks))
                self.navigationController?.pushViewController(vc, animated: true)
            case .groupTapped(let track):
                viewModel.didSelectTrack(tracks: viewModel.state.tracks.filter { $0.name != track.name })
            case .trackTapped(_): break
            }
        }
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.title = "レポートを書く"
        self.navigationItem.largeTitleDisplayMode = .never
        
        self.view.addSubview(postScrollView)
        NSLayoutConstraint.activate([
            postScrollView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            postScrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            postScrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
        ])
        
        self.view.addSubview(sectionView)
        NSLayoutConstraint.activate([
            sectionView.bottomAnchor.constraint(equalTo: self.view.keyboardSafeArea.layoutGuide.bottomAnchor),
            sectionView.heightAnchor.constraint(equalToConstant: 48),
            sectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            sectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            sectionView.topAnchor.constraint(equalTo: postScrollView.bottomAnchor),
        ])
        setupSectionView()
        
        postScrollView.addSubview(postView)
        NSLayoutConstraint.activate([
            postView.widthAnchor.constraint(equalTo: postScrollView.widthAnchor),
            postView.centerXAnchor.constraint(equalTo: postScrollView.centerXAnchor),
            postView.topAnchor.constraint(equalTo: postScrollView.topAnchor),
            postView.bottomAnchor.constraint(equalTo: postScrollView.bottomAnchor),
        ])
        
        selectedGroupView.isHidden = true
        uploadedImageView.isHidden = true
        playlistView.isHidden = true
        
        if let thumbnailURL = dependencyProvider.user.thumbnailURL.flatMap(URL.init(string: )) {
            dependencyProvider.imagePipeline.loadImage(thumbnailURL, into: avatarImageView)
        }

        textView.becomeFirstResponder()
    }
    
    func setupSectionView () {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 24
        stackView.distribution = .fill
        sectionView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.heightAnchor.constraint(equalToConstant: 30),
            stackView.centerYAnchor.constraint(equalTo: sectionView.centerYAnchor),
            stackView.leftAnchor.constraint(equalTo: sectionView.leftAnchor, constant: 16),
            stackView.rightAnchor.constraint(equalTo: sectionView.rightAnchor, constant: -16),
        ])
        
        let movieButton = UIButton()
        movieButton.backgroundColor = .clear
        movieButton.translatesAutoresizingMaskIntoConstraints = false
        movieButton.setImage(UIImage(named: "image"), for: .normal)
        movieButton.addTarget(self, action: #selector(searchImage(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(movieButton)
        NSLayoutConstraint.activate([
            movieButton.widthAnchor.constraint(equalToConstant: 30),
            movieButton.heightAnchor.constraint(equalToConstant: 30),
        ])
        
        let youtubeButton = UIButton()
        youtubeButton.backgroundColor = .clear
        youtubeButton.translatesAutoresizingMaskIntoConstraints = false
        youtubeButton.setImage(UIImage(named: "music"), for: .normal)
        youtubeButton.addTarget(self, action: #selector(searchTrack(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(youtubeButton)
        NSLayoutConstraint.activate([
            youtubeButton.widthAnchor.constraint(equalToConstant: 30),
            youtubeButton.heightAnchor.constraint(equalToConstant: 30),
        ])
        
//        let groupButton = UIButton()
//        groupButton.backgroundColor = .clear
//        groupButton.translatesAutoresizingMaskIntoConstraints = false
//        groupButton.setImage(UIImage(named: "guitar"), for: .normal)
//        groupButton.addTarget(self, action: #selector(searchGroup(_:)), for: .touchUpInside)
//        stackView.addArrangedSubview(groupButton)
//        NSLayoutConstraint.activate([
//            groupButton.widthAnchor.constraint(equalToConstant: 30),
//            groupButton.heightAnchor.constraint(equalToConstant: 30),
//        ])
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(spacer)
        
        stackView.addArrangedSubview(numOfTextLabel)
        NSLayoutConstraint.activate([
            numOfTextLabel.widthAnchor.constraint(equalToConstant: 40),
            numOfTextLabel.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    
    @objc private func searchImage(_ sender: Any) {
//        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
//            let picker = UIImagePickerController()
//            picker.sourceType = .photoLibrary
//            picker.delegate = self
//            picker.mediaTypes = ["public.movie"]
//            self.present(picker, animated: true, completion: nil)
//        }
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    @objc private func searchTrack(_ sender: Any) {
        let vc = SelectTrackViewController(dependencyProvider: dependencyProvider, input: viewModel.state.tracks)
        vc.listen { [unowned self] tracks in
            self.dismiss(animated: true, completion: nil)
            viewModel.didSelectTrack(tracks: tracks)
        }
        let nav = BrandNavigationController(rootViewController: vc)
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc private func searchGroup(_ sender: Any) {
        let vc = SelectGroupViewController(dependencyProvider: dependencyProvider)
        let nav = BrandNavigationController(rootViewController: vc)
        vc.listen { [unowned self] group in
            self.dismiss(animated: true, completion: nil)
            viewModel.didSelectGroup(groups: [group])
        }
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc private func searchSpotify(_ sender: Any) {
        print("c")
    }
    
    @objc private func cancelMovie(_ sender: UIButton) {
//        self.viewModel.didUpdatePost(post: .none)
    }
    
    @objc func postButtonTapped() {
        viewModel.postButtonTapped()
    }
    
    @objc private func playTrackButtonTapped() {
        guard let track = viewModel.state.tracks.first else { return }
        let vc = PlayTrackViewController(dependencyProvider: dependencyProvider, input: .track(track))
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func selectedGroupTapped() {
        let alertController = UIAlertController(
            title: "削除しますか？", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        let acceptAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.default,
            handler: { [unowned self] action in
                viewModel.didSelectGroup(groups: [])
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
    
    @objc private func uploadedImageTapped() {
        let alertController = UIAlertController(
            title: "削除しますか？", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        let acceptAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.default,
            handler: { [unowned self] action in
                viewModel.didUploadImages(images: [])
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
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        viewModel.didUploadImages(images: [image])
        picker.dismiss(animated: true, completion: nil)
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
