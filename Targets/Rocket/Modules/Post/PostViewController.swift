//
//  PostViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/07.
//

import Combine
import UIKit
import UIComponent
import Endpoint
import Photos
import PhotosUI
import AVKit
import KeyboardGuide
import UITextView_Placeholder

final class PostViewController: UIViewController, Instantiable {
    typealias Input = PostViewModel.Input

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    private lazy var liveView: LiveBannerCellContent = {
        let content = LiveBannerCellContent()
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()
    private lazy var scrollStackView: UIStackView = {
        let postView = UIStackView()
        postView.translatesAutoresizingMaskIntoConstraints = false
        postView.backgroundColor = Brand.color(for: .background(.primary))
        postView.axis = .vertical
        postView.spacing = 16
        
        postView.addArrangedSubview(liveView)
        NSLayoutConstraint.activate([
            liveView.widthAnchor.constraint(equalTo: postView.widthAnchor),
            liveView.heightAnchor.constraint(equalToConstant: 100),
        ])
        
        postView.addArrangedSubview(textContainerView)
        NSLayoutConstraint.activate([
            textContainerView.widthAnchor.constraint(equalTo: postView.widthAnchor)
        ])
        
        postView.addArrangedSubview(imageGalleryView)
        NSLayoutConstraint.activate([
            imageGalleryView.widthAnchor.constraint(equalTo: postView.widthAnchor),
            imageGalleryView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
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
            avatarImageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
        ])
        
        view.addSubview(usernameLabel)
        NSLayoutConstraint.activate([
            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            usernameLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 4),
            usernameLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
        ])
        
        view.addSubview(trackNameLabel)
        NSLayoutConstraint.activate([
            trackNameLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor),
            trackNameLabel.leftAnchor.constraint(equalTo: usernameLabel.leftAnchor),
            trackNameLabel.rightAnchor.constraint(equalTo: usernameLabel.rightAnchor),
        ])
        
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
            textView.rightAnchor.constraint(equalTo: usernameLabel.rightAnchor),
            textView.leftAnchor.constraint(equalTo: avatarImageView.leftAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.heightAnchor.constraint(greaterThanOrEqualTo: avatarImageView.heightAnchor, multiplier: 1.6),
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
        textView.placeholder = "セットリスト・MCで言っていたことなどを記録しよう。下から画像や楽曲も選択できるよ。"
        textView.placeholderTextView.textAlignment = .left
        textView.placeholderColor = Brand.color(for: .background(.light))
        textView.font = Brand.font(for: .mediumStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .left
        
        textView.returnKeyType = .done
        return textView
    }()
    private lazy var imageGalleryView: ImageGalleryCollectionView = {
        let view = ImageGalleryCollectionView(images: .none, imagePipeline: dependencyProvider.imagePipeline)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .smallStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var trackNameLabel: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = Brand.font(for: .xsmall)
        button.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(trackTapped), for: .touchUpInside)
        return button
    }()
    private lazy var postButton: UIButton = {
        let postButton = UIButton()
        postButton.translatesAutoresizingMaskIntoConstraints = false
        postButton.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        postButton.setTitleColor(Brand.color(for: .brand(.primary)), for: .highlighted)
        postButton.setTitle("post", for: .normal)
        postButton.titleLabel?.font = Brand.font(for: .largeStrong)
        return postButton
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
    let pointViewModel: PointViewModel
    var cancellables: Set<AnyCancellable> = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = PostViewModel(dependencyProvider: dependencyProvider, input: input)
        self.pointViewModel = PointViewModel(dependencyProvider: dependencyProvider)

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
            .sink(receiveValue: { [unowned self] in postButtonTapped() })
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didPost(_): break
//                pointViewModel.addPoint(point: 100)
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
            case .didInitContent:
                textView.text = viewModel.state.post?.text
                trackNameLabel.setTitle(viewModel.state.tracks.first?.name, for: .normal)
                usernameLabel.text = dependencyProvider.user.name
                liveView.inject(input: (live: viewModel.state.live, imagePipeline: dependencyProvider.imagePipeline))
                imageGalleryView.inject(images: .image(viewModel.state.images))
                imageGalleryView.isHidden = viewModel.state.images.isEmpty
            case .didUpdateContent:
                textView.text = viewModel.state.text
                trackNameLabel.setTitle(viewModel.state.tracks.first?.name, for: .normal)
                imageGalleryView.inject(images: .image(viewModel.state.images))
                imageGalleryView.isHidden = viewModel.state.images.isEmpty
            }
        }.store(in: &cancellables)
        
        pointViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .addPoint(_):
                self.showSuccessToGetPoint(100)
                navigationController?.popToRootViewController(animated: true)
            default: break
            }
        }
        .store(in: &cancellables)
        
        imageGalleryView.listen { [unowned self] index in
            uploadedImageTapped(at: index)
        }
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.title = "レポートを書く"
        
        self.view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            scrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            scrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
        ])
        
        self.view.addSubview(sectionView)
        NSLayoutConstraint.activate([
            sectionView.bottomAnchor.constraint(equalTo: self.view.keyboardSafeArea.layoutGuide.bottomAnchor),
            sectionView.heightAnchor.constraint(equalToConstant: 48),
            sectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            sectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            sectionView.topAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])
        setupSectionView()
        
        scrollView.addSubview(scrollStackView)
        NSLayoutConstraint.activate([
            scrollStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            scrollStackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            scrollStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            scrollStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
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
        stackView.spacing = 24
        stackView.distribution = .fill
        sectionView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.heightAnchor.constraint(equalToConstant: 30),
            stackView.centerYAnchor.constraint(equalTo: sectionView.centerYAnchor),
            stackView.leftAnchor.constraint(equalTo: sectionView.leftAnchor, constant: 16),
            stackView.rightAnchor.constraint(equalTo: sectionView.rightAnchor, constant: -16),
        ])
        
        let selectImageButton = UIButton()
        selectImageButton.backgroundColor = .clear
        selectImageButton.translatesAutoresizingMaskIntoConstraints = false
        selectImageButton.setImage(UIImage(named: "image"), for: .normal)
        selectImageButton.addTarget(self, action: #selector(selectImageButtonTapped(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(selectImageButton)
        NSLayoutConstraint.activate([
            selectImageButton.widthAnchor.constraint(equalToConstant: 30),
            selectImageButton.heightAnchor.constraint(equalToConstant: 30),
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
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(spacer)
        
        stackView.addArrangedSubview(numOfTextLabel)
        NSLayoutConstraint.activate([
            numOfTextLabel.widthAnchor.constraint(equalToConstant: 40),
            numOfTextLabel.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    
    @objc private func selectImageButtonTapped(_ sender: Any) {
        if viewModel.state.images.count == 4 {
            showAlert(title: "画像は最大4枚までです", message: "")
        } else {
            if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.delegate = self
                self.present(picker, animated: true, completion: nil)
            }
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
    
    @objc func postButtonTapped() {
        viewModel.postButtonTapped()
    }
    
    @objc private func trackTapped() {
        let alertController = UIAlertController(title: "楽曲を削除しますか？", message: nil, preferredStyle: .actionSheet)
        let acceptAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.default,
            handler: { [unowned self] action in
                viewModel.didSelectTrack(tracks: [])
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
    
    @objc private func uploadedImageTapped(at index: Int) {
        let alertController = UIAlertController(
            title: "削除しますか？", message: nil, preferredStyle: .actionSheet)

        let acceptAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.default,
            handler: { [unowned self] action in
                viewModel.didDeleteImage(at: index)
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
        viewModel.didUploadImage(image: image)
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
