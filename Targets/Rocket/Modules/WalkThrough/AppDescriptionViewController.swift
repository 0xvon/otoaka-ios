//
//  AppDescriptionViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/08/18.
//

import UIKit

final class AppDescriptionViewController: UIViewController {
    typealias Input = (
        description: String?,
        imageName: String
    )
    var input: Input
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private lazy var descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = Brand.font(for: .largeStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textAlignment = .center
        textView.textContainer.lineFragmentPadding = 0
        
        return textView
    }()
    
    init(input: Input) {
        self.input = input
        super.init(nibName: nil, bundle: nil)
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = UIImage(named: input.imageName)
        descriptionTextView.text = input.description
        
        self.view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: self.view.bounds.width * 0.8),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.37),
            imageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])
        
        self.view.addSubview(descriptionTextView)
        NSLayoutConstraint.activate([
            descriptionTextView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            descriptionTextView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            descriptionTextView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor, constant: 120),
        ])
    }
}
