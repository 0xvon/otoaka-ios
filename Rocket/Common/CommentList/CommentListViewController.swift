//
//  CommentListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/18.
//

import UIKit
import Endpoint

final class CommentListViewController: UIViewController, Instantiable {
    typealias Input = ListType
    
    enum ListType {
        case feedComment(GroupFeed)
    }

    var dependencyProvider: LoggedInDependencyProvider!
    var input: Input!
    var comments: [String] = []
    private var commentTableView: UITableView!

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var viewModel = CommentListViewModel(
        apiClient: dependencyProvider.apiClient,
        type: input,
        auth: dependencyProvider.auth,
        outputHander: { output in
            switch output {
            case .getFeedComments(let comments):
                DispatchQueue.main.async {
                    print(comments)
                }
            case .refreshFeedComments(let comments):
                DispatchQueue.main.async {
                    print(comments)
                }
            case .error(let error):
                print(error)
            }
        }
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
        
    func setup() {
        view.backgroundColor = style.color.background.get()
        
        commentTableView = UITableView(frame: .zero, style: .grouped)
        commentTableView.translatesAutoresizingMaskIntoConstraints = false
        commentTableView.showsVerticalScrollIndicator = false
        commentTableView.tableFooterView = UIView(frame: .zero)
        commentTableView.separatorStyle = .none
        commentTableView.backgroundColor = style.color.background.get()
        commentTableView.delegate = self
        commentTableView.dataSource = self
        commentTableView.register(
            UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")
        self.view.addSubview(commentTableView)
        
        commentTableView.refreshControl = UIRefreshControl()
        commentTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroups(sender:)), for: .valueChanged)
        self.getComments()
        
        let constraints: [NSLayoutConstraint] = [
            commentTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            commentTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            commentTableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 32),
            commentTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func getComments() {
        switch input {
        case .feedComment(_):
            self.viewModel.getFeedComments()
        case .none:
            break
        }
    }
    
    func refreshComments() {
        switch input {
        case .feedComment(_):
            self.viewModel.refreshFeedComments()
        case .none:
            break
        }
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
        return 10
        
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
            textView.layer.borderColor = style.color.main.get().cgColor
            textView.backgroundColor = .clear
            textView.isEditable = true
            textView.font = style.font.regular.get()
            textView.textColor = style.color.main.get()
            view.addSubview(textView)
            
            let commentView = UIView()
            commentView.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .clear
            view.addSubview(commentView)
            let commentButton = Button(input: (text: "コメントを送信", image: nil))
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
//        let comment = self.comments[indexPath.section]
        let cell = tableView.reuse(CommentCell.self, input: "", for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (self.comments.count - indexPath.section) == 2 && self.comments.count % per == 0 {
            self.getComments()
        }
    }
    
    private func comment(text: String) {
        print(text)
    }
}

extension CommentListViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        self.comment(text: textView.text!)
        textView.text = ""
        self.resignFirstResponder()
    }
}
