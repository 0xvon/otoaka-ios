//
//  Button.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/21.
//

import UIKit

final class Button: UIView {
    static var xibName: String { "Button" }
    typealias Input = type
    
    var input: Input!
    
    enum type {
        case listen
        case play
        case buyTicket
        case signin
    }
    
    @IBOutlet private weak var buttonImageView: UIImageView!
    @IBOutlet private weak var buttonTitleLabel: UILabel!
    @IBOutlet private weak var button: UIButton!
    
    convenience init(input: Input) {
        self.init()
        self.input = input
        self.inject(input: input)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadView()
        
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadView()
    }
    
    private func loadView() {
        let xib = UINib(nibName: Self.xibName, bundle: nil)
        guard let contentView = xib.instantiate(withOwner: self, options: nil).first as? UIView else {
            preconditionFailure()
        }
        addSubview(contentView)
        
        button.addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
        contentView.frame = CGRect(x: 0, y: 0, width: 180, height: 48)
        contentView.backgroundColor = .clear
        contentView.layer.opacity = 0.8
        contentView.layer.cornerRadius = 24
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = style.color.main.get().cgColor
        
    }
    
    @objc private func touchUpInside() {
        self.listener()
    }
    
    func inject(input: type) {
        self.input = input
        self.layout()
    }
    
    private var listener: () -> Void = {}
    func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }

    
    func layout() {
        self.buttonImageView.tintColor = style.color.main
            .get()
        
        self.button.layer.cornerRadius = 24
        self.button.backgroundColor = .clear
        
        self.buttonTitleLabel.textColor = style.color.main.get()
        self.buttonTitleLabel.font = style.font.regular.get()
        
        switch self.input {
        case .buyTicket:
            self.buttonImageView.image = UIImage(systemName: "ticket")
            self.buttonTitleLabel.text = "チケット購入"
        case .listen:
            self.buttonImageView.image = UIImage(systemName: "play")
            self.buttonTitleLabel.text = "曲を聴く"
        case .play:
            self.buttonImageView.image = UIImage(systemName: "play")
            self.buttonTitleLabel.text = "再生"
        case .signin:
            self.buttonImageView.image = nil
            self.buttonTitleLabel.text = "サインイン"
            self.frame = CGRect(x: 0, y: 0, width: 300, height: 60)
        default:
            print("hoa")
        }
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI
//
//struct Button_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            ViewWrapper<Button>(
//                input: .listen
//            ).previewDisplayName("listening")
//            ViewWrapper<Button>(
//                input: .play
//            ).previewDisplayName("playing")
//            ViewWrapper<Button>(
//                input: .buyTicket
//            ).previewDisplayName("ticketing")
//        }
//        .previewLayout(.fixed(width: 180, height: 48))
//        .preferredColorScheme(.dark)
//    }
//}
#endif
