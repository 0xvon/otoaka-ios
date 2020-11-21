//
//  PostViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/07.
//

import UIKit

final class PostViewController: UIViewController, Instantiable {
    typealias Input = Void
    var dependencyProvider: DependencyProvider!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var sectionView: UIView!
    
    private var sectionStackView: UIStackView!
    private var postButton: UIButton!
    private var postType: PostType = .movie
    
    enum PostType {
        case movie
        case youtube
        case spotify
    }
    
    init(dependencyProvider: DependencyProvider, input: Input) {
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
    
    func setup() {
        self.view.backgroundColor = style.color.background.get()
        textView.text = ""
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.font = style.font.regular.get()
        textView.textColor = style.color.main.get()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        postButton = UIButton()
        postButton.setTitleColor(style.color.main.get(), for: .normal)
        postButton.setTitle("post", for: .normal)
        postButton.titleLabel?.font = style.font.regular.get()
        
        let barButtonItem = UIBarButtonItem(customView: postButton)
        self.navigationItem.rightBarButtonItem = barButtonItem
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        print("keyboard showed")
    }
    
    @objc private func post(_ sender: Any) {
        print("post")
    }

}

extension PostViewController: UITextViewDelegate {
}
