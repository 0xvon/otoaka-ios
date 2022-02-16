//
//  NichiTagCanvasViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/02/15.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import UIKit
import TagListView
import CropViewController

final class NichiTagCanvasViewController: UIViewController, Instantiable {
    typealias Input = Void
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: NichiTagCanvasViewModel
    var cancellables: Set<AnyCancellable> = []
    private lazy var canvas: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.color(for: .background(.primary))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var canvasBackgroundImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0.3
        imageView.backgroundColor = Brand.color(for: .background(.milder))
        return imageView
    }()
    private lazy var contentsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        
        stackView.addArrangedSubview(spacer)
        spacer.isHidden = true
        stackView.addArrangedSubview(recentlyFollowingContent)
        stackView.addArrangedSubview(liveScheduleTableView)
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(spacer)
        
        return stackView
    }()
    private lazy var spacer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 60),
        ])
        return view
    }()
    private lazy var recentlyFollowingContent: TagListView = {
        let content = TagListView()
        content.translatesAutoresizingMaskIntoConstraints = false
        content.alignment = .left
        content.cornerRadius = 16
        content.paddingY = 8
        content.paddingX = 12
        content.marginX = 0
        content.marginY = 0
        content.textFont = Brand.font(for: .medium)
        return content
    }()
    private lazy var liveScheduleTableView: LiveScheduleTableView = {
        let content = LiveScheduleTableView(liveFeeds: [], imagePipeline: dependencyProvider.imagePipeline)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.isScrollEnabled = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 76 * 3),
        ])
        return content
    }()
    
    private lazy var adjustmentPanel: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Brand.color(for: .background(.milder))
        
        let horizontalStackView = UIStackView()
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 24
        horizontalStackView.distribution = .fillEqually
        
        view.addSubview(horizontalStackView)
        NSLayoutConstraint.activate([
            horizontalStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            horizontalStackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            horizontalStackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
        ])
        
        let leftStackView = UIStackView()
        leftStackView.translatesAutoresizingMaskIntoConstraints = false
        leftStackView.axis = .vertical
        leftStackView.spacing = 8
        leftStackView.addArrangedSubview(recentlyToggleSwitch)
        NSLayoutConstraint.activate([
            recentlyToggleSwitch.heightAnchor.constraint(equalToConstant: 31),
        ])
        leftStackView.addArrangedSubview(liveScheduleToggleSwitch)
        NSLayoutConstraint.activate([
            liveScheduleToggleSwitch.heightAnchor.constraint(equalToConstant: 31),
        ])
        
        let rightStackView = UIStackView()
        rightStackView.translatesAutoresizingMaskIntoConstraints = false
        rightStackView.axis = .vertical
        rightStackView.spacing = 8
        
        let actionItemStackView = UIStackView()
        actionItemStackView.translatesAutoresizingMaskIntoConstraints = false
        actionItemStackView.axis = .horizontal
        actionItemStackView.spacing = 8
        
        actionItemStackView.addArrangedSubview(addImageItem)
        NSLayoutConstraint.activate([
            addImageItem.widthAnchor.constraint(equalToConstant: 44),
            addImageItem.heightAnchor.constraint(equalToConstant: 48),
        ])
        
        let actionItemSpacer = UIView()
        actionItemSpacer.translatesAutoresizingMaskIntoConstraints = false
        actionItemStackView.addArrangedSubview(actionItemSpacer)
        
        rightStackView.addArrangedSubview(actionItemStackView)
        let rightStackSpacer = UIView()
        rightStackSpacer.translatesAutoresizingMaskIntoConstraints = false
        rightStackView.addArrangedSubview(rightStackSpacer)
        
        horizontalStackView.addArrangedSubview(leftStackView)
        horizontalStackView.addArrangedSubview(rightStackView)
        
        return view
    }()
    private lazy var recentlyToggleSwitch: ToggleSwitch = {
        let toggleSwitch = ToggleSwitch(title: "最近好き")
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        return toggleSwitch
    }()
    private lazy var liveScheduleToggleSwitch: ToggleSwitch = {
        let toggleSwitch = ToggleSwitch(title: "参戦予定")
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        return toggleSwitch
    }()
    private lazy var addImageItem: NichiTagPanelAddImageItem = {
        let item = NichiTagPanelAddImageItem()
        item.translatesAutoresizingMaskIntoConstraints = false
        return item
    }()
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = NichiTagCanvasViewModel(dependencyProvider: dependencyProvider)
        
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
        title = "日タグ"
        
        super.viewDidLoad()
        setup()
        bind()
        viewModel.refresh()
    }
    
    func setup() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        view.addSubview(canvas)
        NSLayoutConstraint.activate([
            canvas.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            canvas.heightAnchor.constraint(equalTo: canvas.widthAnchor),
            canvas.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            canvas.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 24),
        ])
        
        canvas.addSubview(canvasBackgroundImage)
        NSLayoutConstraint.activate([
            canvasBackgroundImage.topAnchor.constraint(equalTo: canvas.topAnchor),
            canvasBackgroundImage.leftAnchor.constraint(equalTo: canvas.leftAnchor),
            canvasBackgroundImage.rightAnchor.constraint(equalTo: canvas.rightAnchor),
            canvasBackgroundImage.bottomAnchor.constraint(equalTo: canvas.bottomAnchor),
        ])
        
        canvas.addSubview(contentsStackView)
        NSLayoutConstraint.activate([
            contentsStackView.topAnchor.constraint(equalTo: canvas.topAnchor, constant: 16),
            contentsStackView.leftAnchor.constraint(equalTo: canvas.leftAnchor, constant: 16),
            contentsStackView.rightAnchor.constraint(equalTo: canvas.rightAnchor, constant: -16),
            contentsStackView.bottomAnchor.constraint(equalTo: canvas.bottomAnchor, constant: -16),
        ])
        
        view.addSubview(adjustmentPanel)
        NSLayoutConstraint.activate([
            adjustmentPanel.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            adjustmentPanel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            adjustmentPanel.topAnchor.constraint(equalTo: canvas.bottomAnchor),
            adjustmentPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        navigationItem.setRightBarButton(
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(createShare)),
            animated: true
        )
        
        canvasBackgroundImage.image = UIImage(named: "dpf")
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .getLeftItem:
                recentlyFollowingContent.removeAllTags()
                recentlyFollowingContent.addTags(viewModel.state.recentlyFollowingGroups.map { $0.group.name })
                recentlyFollowingContent.textColor = Brand.color(for: .text(.primary))
                recentlyFollowingContent.textFont = Brand.font(for: .mediumStrong)
                recentlyFollowingContent.tagBackgroundColor = .clear
                
                liveScheduleTableView.inject(liveFeeds: viewModel.state.liveSchedule)
            case .getRightItem: break
            case .error(let err):
                print(String(describing: err))
            }
        }
        .store(in: &cancellables)
        
        recentlyToggleSwitch.listen { [unowned self] isOn in
            recentlyFollowingContent.isHidden = !isOn
            workSpaceer()
        }
        
        liveScheduleToggleSwitch.listen { [unowned self] isOn in
            liveScheduleTableView.isHidden = !isOn
            workSpaceer()
        }
        
        addImageItem.listen { [unowned self] in
            addImage()
        }
    }
    
    @objc private func createShare() {
        guard let snapShot = canvas.getSnapShot() else { return }
        let activityController = UIActivityViewController(
            activityItems: [snapShot],
            applicationActivities: nil
        )
        self.present(activityController, animated: true, completion: nil)
    }
    
    func addImage() {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    func workSpaceer() {
        spacer.isHidden = !(recentlyFollowingContent.isHidden || liveScheduleTableView.isHidden)
    }
}

extension NichiTagCanvasViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        
        let cropController = CropViewController(image: image)
        cropController.delegate = self
        cropController.customAspectRatio = canvasBackgroundImage.frame.size
        cropController.aspectRatioPickerButtonHidden = true
        cropController.resetAspectRatioEnabled = false
        cropController.rotateButtonsHidden = true
        cropController.cropView.cropBoxResizeEnabled = false
        picker.dismiss(animated: true) {
            self.present(cropController, animated: true, completion: nil)
        }
    }
}

extension NichiTagCanvasViewController: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        canvasBackgroundImage.image = image
        cropViewController.dismiss(animated: true, completion: nil)
    }
}
