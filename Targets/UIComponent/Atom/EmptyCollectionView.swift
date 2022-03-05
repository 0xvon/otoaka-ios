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
        case post = "ここには自分やフォローしたユーザーのライブ予定やライブの感想が表示されます。友達にこのアプリを教えて繋がろう！"
        case livePost = "ここにはライブのレポート一覧が表示されます。試しにレポートを書いてみましょう。"
        case feedComment = "コメントがまだありません。試しにコメントを投稿してみましょう。"
        case live = "ライブ一覧がまだありません。ここにはフォローしているアーティストのライブ予定が表示されます。試しにアーティストをフォローしてみましょう。"
        case group = "アーティストがまだありません。他のアーティストにこのアプリを教えてあげましょう。"
        case followingGroup = "スキなアーティストがまだいません。試しにアーティストを探して「スキ」に登録してみましょう。"
        case groupList = "アーティストがいません。"
        case userList = "ユーザーがいません。"
        case postList = "ライブレポートがありません。"
        case liveList = "ライブが見つかりませんでした。追加しよう！"
        case likedLiveList = "「探す」タブから行くライブを探して「行く」を押すとここに表示されます。ライブが見つからなかった場合申請することができます。"
        case pastLive = "まだ行ったライブがありません。「参戦した」を押したライブがここにコレクションされます。"
        case groupLiveList = "このアーティストのライブが見つかりませんでした。追加しよう！"
        case followingGroupsLives = "ここにはスキなアーティストの直近のライブが表示されます。試しに好きなアーティストを探して「スキ」に登録してみましょう。"
        case messageList = "メッセージがまだありません。ライブ友達を探して好きなアーティストやライブ予定の話をしてみましょう。"
        case message = "やりとりがまだありません。"
        case chart = "動画がまだありません。"
        case chartList = "動画がありません。"
        case request = "リクエストがまだありません。ここには他のアーティストからの対バンリクエストが表示されます。試しに他のバンドにコンタクトを取ってみましょう。"
        case ticket = "チケットがまだありません。ここには取り置き予約したライブチケットが表示されます。いきたいライブを探して予約しましょう。"
        case search = "検索結果はありません。"
        case friend = ""
        case liveSchedule = "ライブ予定はありません。"
        case notification = "通知はありません。"
        case event = "イベントはまだありません。"
        case tip = "snackをまだしていません。"
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
//        NSLayoutConstraint.activate([
//            messageTextView.heightAnchor.constraint(equalToConstant: 120),
//        ])
        
        addArrangedSubview(button)
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        let bottomSpacer = UIView()
        addArrangedSubview(bottomSpacer)
        
        button.listen { [unowned self] in
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
            PreviewWrapper(view: EmptyCollectionView(emptyType: .feed, actionButtonTitle: "バンドを探す"))
                .previewLayout(.fixed(width: 320, height: 500))
        }
        .background(Color.black)
        
        Group {
            PreviewWrapper(view: EmptyCollectionView(emptyType: .group, actionButtonTitle: nil))
                .previewLayout(.fixed(width: 320, height: 220))
        }
        .background(Color.black)
        
        Group {
            PreviewWrapper(view: EmptyCollectionView(emptyType: .live, actionButtonTitle: "バンドを探す"))
                .previewLayout(.fixed(width: 320, height: 500))
        }
        .background(Color.black)
    }
}
#endif
