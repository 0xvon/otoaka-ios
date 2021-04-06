//
//  EmptyCollectionView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/01/01.
//

import UIKit

public final class EmptyCollectionView: UIStackView {
    public enum EmptyType: String {
        case feed = "フィードがまだありません。ここにはフォローしているユーザーのフィードが表示されます。試しにフィードを投稿してみましょう。"
        case feedComment = "コメントがまだありません。試しにコメントを投稿してみましょう。"
        case live = "ライブ一覧がまだありません。ここにはフォローしているバンドのライブ予定が表示されます。試しにバンドをフォローしてみましょう。"
        case group = "バンドがまだありません。他のバンドにこのアプリを教えてあげましょう。"
        case followingGroup = "フォローしているバンドがまだいません。試しにバンドをフォローしてみましょう。"
        case groupList = "バンドがいません。"
        case userList = "ユーザーがいません。"
        case chart = "動画がまだありません。"
        case chartList = "動画がありません。"
        case request = "リクエストがまだありません。ここには他のバンドからの対バンリクエストが表示されます。試しに他のバンドにコンタクトを取ってみましょう。"
        case ticket = "チケットがまだありません。ここには取り置き予約したライブチケットが表示されます。いきたいライブを探して予約しましょう。"
        case search = "検索結果はありません。"
        case notification = "通知はありません。"
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "（’・_・｀）"
        label.textAlignment = .center
        label.font = Brand.font(for: .largeStrong)
        label.backgroundColor = .clear
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private let messageTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textAlignment = .center
        textView.font = Brand.font(for: .medium)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.backgroundColor = .clear
        textView.isUserInteractionEnabled = false
        textView.isScrollEnabled = false
        return textView
    }()
    private let button: PrimaryButton = {
        let button = PrimaryButton(text: "")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 25
        return button
    }()
    
    public init(emptyType: EmptyType, actionButtonTitle: String?) {
        super.init(frame: .zero)
        setup()
        update(emptyType: emptyType, actionButtonTitle: actionButtonTitle)
    }
    
    func update(emptyType: EmptyType, actionButtonTitle: String?) {
        messageTextView.text = emptyType.rawValue
        if let title = actionButtonTitle {
            button.isHidden = false
            button.setTitle(title, for: .normal)
        } else {
            button.isHidden = true
        }
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        backgroundColor = Brand.color(for: .background(.primary))
        axis = .vertical
        distribution = .fill
        spacing = 16
        
        let topSpacer = UIView()
        addArrangedSubview(topSpacer)
        NSLayoutConstraint.activate([
            topSpacer.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        addArrangedSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        addArrangedSubview(messageTextView)
        NSLayoutConstraint.activate([
            messageTextView.heightAnchor.constraint(equalToConstant: 120),
        ])
        
        addArrangedSubview(button)
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        let bottomSpacer = UIView()
        addArrangedSubview(bottomSpacer)
        
        button.listen {
            self.listener()
        }
    }
    
    private var listener: () -> Void = {}
    public func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}

#if PREVIEW
import SwiftUI

struct EmptyCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ViewWrapper(view: EmptyCollectionView(emptyType: .feed, actionButtonTitle: "バンドを探す"))
                .previewLayout(.fixed(width: 320, height: 500))
        }
        .background(Color.black)
        
        Group {
            ViewWrapper(view: EmptyCollectionView(emptyType: .group, actionButtonTitle: nil))
                .previewLayout(.fixed(width: 320, height: 220))
        }
        .background(Color.black)
        
        Group {
            ViewWrapper(view: EmptyCollectionView(emptyType: .live, actionButtonTitle: "バンドを探す"))
                .previewLayout(.fixed(width: 320, height: 500))
        }
        .background(Color.black)
    }
}
#endif
