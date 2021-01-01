//
//  EmptyCollectionView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/01/01.
//

import UIKit

public final class EmptyCollectionView: UIStackView {
    public enum EmptyType: String {
        case feed = "Feedがまだありません。試しにバンドをフォローしてみましょう。"
        case live = "Liveがまだありません。"
        case band = "Bandがまだありません。"
        case ticket = "Ticketがまだありません。いきたいライブを探して予約しましょう。"
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "ぴえん。。。"
        label.textAlignment = .center
        label.font = Brand.font(for: .largeStrong)
        label.backgroundColor = .clear
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = Brand.font(for: .medium)
        label.textColor = Brand.color(for: .text(.primary))
        label.backgroundColor = .clear
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = false
        label.sizeToFit()
        return label
    }()
    private let button: PrimaryButton = {
        let button = PrimaryButton(text: "ユーザー作成")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 25
        return button
    }()
    
    public init(emptyType: EmptyType, isActionButtonEnabled: Bool) {
        super.init(frame: .zero)
        setup()
        update(emptyType: emptyType, isActionButtonEnabled: isActionButtonEnabled)
    }
    
    func update(emptyType: EmptyType, isActionButtonEnabled: Bool) {
        messageLabel.text = emptyType.rawValue
        button.isHidden = !isActionButtonEnabled
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        backgroundColor = Brand.color(for: .background(.primary))
        axis = .vertical
        distribution = .fill
        spacing = 24
        
        let topSpacer = UIView()
        addArrangedSubview(topSpacer)
        NSLayoutConstraint.activate([
            topSpacer.heightAnchor.constraint(equalToConstant: 40),
        ])
        
        addArrangedSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        addArrangedSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        addArrangedSubview(button)
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        let bottomSpacer = UIView()
        addArrangedSubview(topSpacer)
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 40),
        ])
        
        button.listen {
            self.listener()
        }
        
        
    }
    
    private var listener: () -> Void = {}
    func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}

#if PREVIEW
import SwiftUI

struct EmptyCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ViewWrapper(view: EmptyCollectionView(emptyType: .feed, isActionButtonEnabled: true))
                .previewLayout(.fixed(width: 320, height: 320))
        }
        .background(Color.black)
    }
}
#endif
