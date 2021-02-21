//
//  CommentListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/18.
//

import UIKit
import Endpoint
import Combine

final class CommentListViewController: UIViewController, Instantiable {
    typealias Input = CommentListViewModel.Input
    
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: CommentListViewModel
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var commentTableView: UITableView = {
       let commentTableView = UITableView(frame: .zero, style: .grouped)
        commentTableView.translatesAutoresizingMaskIntoConstraints = false
        commentTableView.showsVerticalScrollIndicator = false
        commentTableView.tableFooterView = UIView(frame: .zero)
        commentTableView.separatorStyle = .none
        commentTableView.backgroundColor = Brand.color(for: .background(.primary))
        commentTableView.delegate = self
        commentTableView.dataSource = self
        commentTableView.register(
            UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")
        
        commentTableView.refreshControl = BrandRefreshControl()
        commentTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroups(sender:)), for: .valueChanged)
        return commentTableView
    }()

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = CommentListViewModel(dependencyProvider: dependencyProvider, input: input)
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
        viewModel.refresh()
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadTableView:
                commentTableView.reloadData()
                setTableViewBackgroundView(tableView: self.commentTableView)
            case .didPostComment(_):
                commentTableView.reloadData()
                setTableViewBackgroundView(tableView: self.commentTableView)
            case .reportError(let error):
                self.showAlert(title: "エラー", message: String(describing: error))
            }
        }.store(in: &cancellables)
    }
    
    func inject(_ input: Input) {
        viewModel.inject(input)
    }
        
    func setup() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        self.title = "コメント"
        self.navigationItem.largeTitleDisplayMode = .never
        self.view.addSubview(commentTableView)
        let constraints: [NSLayoutConstraint] = [
            commentTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            commentTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            commentTableView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor, constant: 32),
            commentTableView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func refreshComments() {
        viewModel.refresh()
    }
    
    @objc private func refreshGroups(sender: UIRefreshControl) {
        self.refreshComments()
        sender.endRefreshing()
    }
}

extension CommentListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return max(1, viewModel.state.comments.count)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 282
        default:
            return 16
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            let view = UIView(
                frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 266))
            
            let textView = UITextView()
            textView.delegate = self
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.layer.cornerRadius = 16
            textView.layer.borderWidth = 1
            textView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
            textView.backgroundColor = .clear
            textView.isEditable = true
            textView.font = Brand.font(for: .medium)
            textView.textColor = Brand.color(for: .text(.primary))
            view.addSubview(textView)
            
            let commentView = UIView()
            commentView.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .clear
            view.addSubview(commentView)
            let commentButton = PrimaryButton(text: "コメントを送信")
            commentButton.translatesAutoresizingMaskIntoConstraints = false
            commentButton.layer.cornerRadius = 25
            commentButton.listen {
                textView.endEditing(true)
            }
            commentView.addSubview(commentButton)
            
            let constraints = [
                textView.leftAnchor.constraint(equalTo: view.leftAnchor),
                textView.rightAnchor.constraint(equalTo: view.rightAnchor),
                textView.topAnchor.constraint(equalTo: view.topAnchor),
                textView.heightAnchor.constraint(equalToConstant: 200),
                
                commentView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
                commentView.rightAnchor.constraint(equalTo: textView.rightAnchor),
                commentView.widthAnchor.constraint(equalToConstant: 150),
                commentView.heightAnchor.constraint(equalToConstant: 50),
                
                commentButton.widthAnchor.constraint(equalTo: commentView.widthAnchor),
                commentButton.heightAnchor.constraint(equalTo: commentView.heightAnchor),
                
            ]
            NSLayoutConstraint.activate(constraints)
            
            return view
        default:
            let view = UIView()
            view.backgroundColor = .clear
            return view
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if viewModel.state.comments.isEmpty {
            let view = UITableViewCell()
            view.backgroundColor = .clear
            return view
        }
        let comment = viewModel.state.comments[indexPath.section]
        let cell = tableView.dequeueReusableCell(
            CommentCell.self,
            input: (comment: comment, imagePipeline: dependencyProvider.imagePipeline),
            for: indexPath
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(rowAt: indexPath)
    }
    
    private func comment(comment: String?) {
        viewModel.postFeedComment(comment: comment)
    }
    
    func setTableViewBackgroundView(tableView: UITableView) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .feedComment, actionButtonTitle: nil)
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        tableView.backgroundView = viewModel.state.comments.isEmpty ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 300),
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            ])
        }
    }
}

extension CommentListViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        let text: String? = textView.text.isEmpty ? nil : textView.text
        self.comment(comment: text)
        textView.text = ""
        self.resignFirstResponder()
    }
}
