import UIKit
import UIComponent

class FloatingOverlayWindow: UIWindow {
    let floatingViewController: FloatingViewController
    override var isHidden: Bool {
        didSet {
            if isHidden {
                floatingViewController.isOpening = false
            }
        }
    }
    override init(windowScene: UIWindowScene) {
        floatingViewController = FloatingViewController()
        super.init(windowScene: windowScene)
        windowLevel = UIWindow.Level.statusBar + 1
        rootViewController = floatingViewController
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return super.hitTest(point, with: event) as? FloatingButtonItem
    }
}

class FloatingViewController: UIViewController {
    
    var isOpening: Bool = false {
        didSet {
            if isOpening {
                openItems()
            } else {
                closeItems()
            }
        }
    }
    private var buttonItems: [FloatingButtonItem] = []
    private let buttonsContainer: UIStackView = {
        let container = UIStackView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        container.axis = .vertical
        container.distribution = .fillEqually
        return container
    }()
    private lazy var openButtonItem: FloatingButtonItem = {
        let button = FloatingButtonItem(icon: UIImage(named: "plus")!)
        button.addTarget(self, action: #selector(toggleOpenClose), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutButtons()
    }

    private func layoutButtons() {
        view.addSubview(buttonsContainer)
        NSLayoutConstraint.activate([
            view.rightAnchor.constraint(equalTo: buttonsContainer.rightAnchor, constant: 16),
            view.bottomAnchor.constraint(equalTo: buttonsContainer.bottomAnchor, constant: 100),
            buttonsContainer.widthAnchor.constraint(equalToConstant: 60),
        ])
        openButtonItem.isHidden = true
        buttonsContainer.addArrangedSubview(openButtonItem)
    }

    func setFloatingButtonItems(_ items: [FloatingButtonItem]) {
        for oldItem in buttonItems {
            buttonsContainer.removeArrangedSubview(oldItem)
            oldItem.removeFromSuperview()
        }
        openButtonItem.isHidden = items.isEmpty
        for item in items {
            item.isHidden = true
            buttonsContainer.insertArrangedSubview(item, at: 0)
        }
        buttonItems = items
    }

    @objc private func toggleOpenClose() {
        self.isOpening.toggle()
    }

    private func openItems() {
        UIView.animate(withDuration: 0.2) {
            self.openButtonItem.transform = CGAffineTransform(rotationAngle: .pi * 3 / 4)
            for item in self.buttonItems {
                item.alpha = 1.0
                item.isHidden = false
            }
        }
    }
    private func closeItems() {
        UIView.animate(withDuration: 0.2) {
            for item in self.buttonItems {
                item.alpha = 0.0
                item.isHidden = true
            }
            self.openButtonItem.transform = .identity
        }
    }
}
