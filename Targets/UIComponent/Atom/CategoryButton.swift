//
//  CategoryButton.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/09/10.
//

import UIKit

public final class CategoryButton: UIButton {
    private let arrowButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.right")?.withTintColor(Brand.color(for: .background(.light)), renderingMode: .alwaysOriginal), for: .normal)
        button.isUserInteractionEnabled = false
        button.isEnabled = true
        return button
    }()
    public let _imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        return imageView
    }()
    public init(text: String? = nil, image: UIImage? = nil) {
        super.init(frame: .zero)
        
        setup()
    }
    
    public func _setImage(image: UIImage) {
        _imageView.image = image
    }
    
    public override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.6 : 1.0
        }
    }
    
    public override var isEnabled: Bool {
        didSet {
            layer.opacity = isEnabled ? 1.0 : 0.6
        }
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        clipsToBounds = true
        titleLabel?.font = Brand.font(for: .largeStrong)
        setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        setTitleColor(Brand.color(for: .text(.primary)).pressed(), for: .highlighted)
        contentHorizontalAlignment = .left
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 44, bottom: 0, right: 0)
        
        addSubview(_imageView)
        NSLayoutConstraint.activate([
            _imageView.topAnchor.constraint(equalTo: topAnchor),
            _imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            _imageView.widthAnchor.constraint(equalTo: _imageView.heightAnchor),
            _imageView.leftAnchor.constraint(equalTo: leftAnchor),
        ])
        
        addSubview(arrowButton)
        NSLayoutConstraint.activate([
            arrowButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrowButton.rightAnchor.constraint(equalTo: rightAnchor),
        ])
    }
}

#if PREVIEW
import SwiftUI

struct CategoryButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PreviewWrapper(view: {
                let button = CategoryButton()
                button.setTitle("ユーザーを探す", for: .normal)
                button.setImage(UIImage(systemName: "person.fill")?.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal), for: .normal)
                return button
            }())
            .previewLayout(.fixed(width: 180, height: 42))
        }
        .background(Color.black)
    }
}
#endif
