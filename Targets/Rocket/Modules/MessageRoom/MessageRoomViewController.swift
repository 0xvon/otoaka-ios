//
//  MessageRoomViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/06/20.
//

import Combine
import Endpoint
import UIKit
import Foundation
import UIComponent
import MessageKit
import InputBarAccessoryView
import ImagePipeline

final class MessageRoomViewController: MessagesViewController {
    typealias Input = MessageRoom
    
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: MessageRoomViewModel
    var cancellables: Set<AnyCancellable> = []
    
    private let refreshControl = BrandRefreshControl()
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd HH:mm"
        return dateFormatter
    }()
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = MessageRoomViewModel(dependencyProvider: dependencyProvider, input: input)
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
        view.backgroundColor = Brand.color(for: .background(.primary))
        navigationItem.largeTitleDisplayMode = .never
        title = ([viewModel.state.room.owner] + viewModel.state.room.members).filter { $0.id != dependencyProvider.user.id }.first!.name
        
        messageInputBar.delegate = self
        messageInputBar.backgroundColor = Brand.color(for: .background(.primary))
        messageInputBar.inputTextView.textColor = Brand.color(for: .text(.primary))
        messageInputBar.backgroundView.backgroundColor = Brand.color(for: .background(.primary))
        messageInputBar.sendButton.setTitle("送信", for: .normal)
        messageInputBar.sendButton.setTitleColor(Brand.color(for: .brand(.secondary)), for: .normal)
        
        messagesCollectionView.backgroundColor = Brand.color(for: .background(.primary))
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.refreshControl = BrandRefreshControl()
        messagesCollectionView.refreshControl?.addTarget(
            self, action: #selector(refresh(sender:)), for: .valueChanged)
        
        scrollsToLastItemOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        showMessageTimestampOnSwipeLeft = true
                
        bind()
        viewModel.refresh()
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .openMessage:
                messagesCollectionView.refreshControl?.endRefreshing()
                messagesCollectionView.reloadData()
                if viewModel.state.messages.count <= per {
                    messagesCollectionView.scrollToLastItem()
                }
            case .didGetUserDetail(let userDetail):
                let isAvailable = !userDetail.isBlocked && !userDetail.isBlocking
                messageInputBar.inputTextView.isEditable = isAvailable
                messageInputBar.sendButton.isEnabled = isAvailable
                if !isAvailable {
                    messageInputBar.inputTextView.placeholderLabel.text = "メッセージは送れません"
                }
            case .sentMessage:
                messageInputBar.sendButton.stopAnimating()
                viewModel.refresh()
            case .userTapped: break
            case .reportError(let err):
                messageInputBar.sendButton.stopAnimating()
                print(err)
                showAlert()
            }
        }
        .store(in: &cancellables)
    }
    
    @objc private func refresh(sender: UIRefreshControl) {
        viewModel.next()
        sender.endRefreshing()
    }
}

extension MessageRoomViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return Sender(senderId: dependencyProvider.user.id.rawValue.uuidString, displayName: dependencyProvider.user.name)
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        let message = viewModel.state.messages[indexPath.section]
        return translate(from: message)
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return viewModel.state.messages.count
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let date = dateFormatter.string(from: message.sentDate)
        return NSAttributedString(string: date, attributes: [.font: UIFont.preferredFont(forTextStyle: .caption2), .foregroundColor: Brand.color(for: .text(.primary))])
    }
    
    public struct Sender: SenderType {
        public let senderId: String
        public let displayName: String
    }

    public struct MessageKitMessage: MessageType {
        public let sender: SenderType
        public let messageId: String
        public let sentDate: Date
        public let kind: MessageKind
    }
    
    public func translate(from message: Endpoint.Message) -> MessageKitMessage {
        let kind: MessageKind = .text(message.text ?? "")
        return MessageKitMessage(
            sender: Sender(senderId: message.sentBy.id.rawValue.uuidString, displayName: message.sentBy.name),
            messageId: message.id.rawValue.uuidString,
            sentDate: message.sentAt,
            kind: kind
        )
    }

}

extension MessageRoomViewController: MessagesDisplayDelegate {
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let mes = viewModel.state.messages[indexPath.section]
        if let thumbnail = mes.sentBy.thumbnailURL, let url = URL(string: thumbnail) {
            dependencyProvider.imagePipeline.loadImage(url, into: avatarView)
        }
        
    }
}

extension MessageRoomViewController: MessagesLayoutDelegate {
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
}

extension MessageRoomViewController: MessageCellDelegate {
    func didTapBackground(in cell: MessageCollectionViewCell) {
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        messageInputBar.inputTextView.resignFirstResponder()
    }
}

extension MessageRoomViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        inputBar.sendButton.startAnimating()
        viewModel.sendMessage(text: text, image: nil)
        inputBar.inputTextView.text = ""
        inputBar.inputTextView.resignFirstResponder()
    }
}
