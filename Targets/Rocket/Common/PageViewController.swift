//
//  PageViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/08/17.
//

import Foundation
import UIKit

public protocol PageHeaderView: ViewWrapper {
    var pageHeaderHeight: CGFloat { get }
}

public protocol PageContent: ViewWrapper {
    var scrollView: UIScrollView { get }
}

public protocol PageTabView: ViewWrapper {
    var pageTabHeight: CGFloat { get }
    func setPageViewController(_ pageViewController: PageViewController)
}

fileprivate class TransparentScrollView: UIScrollView {
    weak var parent: PageViewController?
    init(parent: PageViewController) {
        self.parent = parent
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private weak var _superScrollView: UIScrollView?
    var superScrollView: UIScrollView? {
        if let superScrollView = _superScrollView { return superScrollView }
        _superScrollView = {
            var view = superview
            while view != nil {
                if let result = view as? UIScrollView { return result }
                view = view?.superview
            }
            return nil
        }()
        return _superScrollView
    }
    
    private var isHitTesting: Bool = false
    func hitTestSuperViewSubViews(at point: CGPoint, event: UIEvent?) -> UIView? {
        if isDecelerating || isDragging { return nil }
        guard let delegateView: UIView = {
            guard superScrollView != nil else {
                if superview == parent?.view { return superview }
                return nil
            }
            return nil
        }() else { return nil }
        func contains(view: UIView, target: UIView) -> Bool {
            if view == target { return true }
            return view.subviews.contains { contains(view: $0, target: target) }
        }
        return delegateView.subviews.filter { !contains(view: $0, target: self) }.reduce(into: UIView?.none) { result, view in
            if result != nil { return }
            result = view.hitTest(view.convert(point, from: self), with: event)
        }
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return hitTestSuperViewSubViews(at: point, event: event) ?? super.hitTest(point, with: event)
    }
}

public final class PageViewController: UIViewController {
    public typealias Content = (
        header: PageHeaderView,
        tab: PageTabView,
        children: [UIViewController & PageContent]
    )
    lazy var containerScrollView: UIScrollView = {
        let scrollView = TransparentScrollView(parent: self)
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()

    var viewControllersContainer: PageViewControllersContainer?
    var viewControllers: [UIViewController & PageContent] = []
    var containerWidthConstraint: NSLayoutConstraint? {
        willSet {
            containerWidthConstraint?.isActive = false
        }
    }
    

    public func embed(_ content: Content) {
        self.viewControllers = content.children

        let attachmentContainer = PageAttachmentViewContainer(
            tabView: content.tab, headerView: content.header, view: view
        )

        content.header.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content.header.view)
        content.tab.setPageViewController(self)
        content.tab.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content.tab.view)

        NSLayoutConstraint.activate(attachmentContainer.constraints)

        viewControllersContainer = PageViewControllersContainer(
            viewControllers: content.children,
            attachmentView: attachmentContainer
        )

        containerWidthConstraint = containerStackView.widthAnchor.constraint(
            equalTo: view.widthAnchor, multiplier: CGFloat(content.children.count)
        )
        containerWidthConstraint?.isActive = true
        for viewController in content.children {
            addChild(viewController)
            containerStackView.addArrangedSubview(viewController.view)
            viewController.didMove(toParent: viewController)
        }
        view.bringSubviewToFront(content.header.view)
        view.bringSubviewToFront(containerScrollView)
        view.bringSubviewToFront(content.tab.view)
    }

    public override func loadView() {
        super.loadView()

        view.addSubview(containerScrollView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerScrollView.addSubview(containerStackView)
        containerScrollView.translatesAutoresizingMaskIntoConstraints = false

        let pageViewControllerEdgeConstraints = [
            view.topAnchor.constraint(equalTo: containerScrollView.topAnchor),
            view.bottomAnchor.constraint(equalTo: containerScrollView.bottomAnchor),
            view.leftAnchor.constraint(equalTo: containerScrollView.leftAnchor),
            view.rightAnchor.constraint(equalTo: containerScrollView.rightAnchor),

            view.topAnchor.constraint(equalTo:    containerStackView.topAnchor),
            view.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
            containerScrollView.leftAnchor.constraint(equalTo:   containerStackView.leftAnchor),
            containerScrollView.rightAnchor.constraint(equalTo:  containerStackView.rightAnchor),
            containerScrollView.heightAnchor.constraint(equalTo: containerStackView.heightAnchor),
        ]

        NSLayoutConstraint.activate(pageViewControllerEdgeConstraints)
    }
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension PageViewController {
    public func selectViewController(at index: Int, tabButton: [UIButton]) {
        let xOffset = CGFloat(index) * view.frame.width
        containerScrollView.setContentOffset(CGPoint(x: xOffset, y: 0), animated: true)
    }
}

class PageAttachmentViewContainer {

    let headerTopConstraint: NSLayoutConstraint
    let headerHeightConstraint: NSLayoutConstraint
    let tabTopConstraint: NSLayoutConstraint
    let constraints: [NSLayoutConstraint]

    var tabViewHeight: () -> CGFloat
    var height: () -> CGFloat

    init(tabView: PageTabView, headerView: PageHeaderView, view: UIView) {
        headerTopConstraint = headerView.view.topAnchor.constraint(equalTo: view.topAnchor)
        headerHeightConstraint = headerView.view.heightAnchor.constraint(equalToConstant: headerView.pageHeaderHeight)
        tabTopConstraint = tabView.view.topAnchor.constraint(equalTo: headerView.view.bottomAnchor)
        tabTopConstraint.priority = .defaultLow

        constraints = [
            headerView.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            headerView.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            headerTopConstraint,
            headerHeightConstraint,

            tabView.view.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            tabView.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            tabView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabTopConstraint
        ]

        tabViewHeight = { tabView.pageTabHeight }
        height = { headerView.pageHeaderHeight + tabView.pageTabHeight }
    }

    func updateHeaderHeight(viaContentOffset contentOffset: CGPoint) {
        headerHeightConstraint.constant = -(contentOffset.y + tabViewHeight())
    }

    func updateHeaderTop(_ top: CGFloat) {
        headerTopConstraint.constant = top
    }
}

class PageViewControllersContainer {

    private(set) var subscriptions: [(Observer, NSKeyValueObservation)] = []
    let viewControllers: [UIViewController & PageContent]

    init(viewControllers: [UIViewController & PageContent], attachmentView: PageAttachmentViewContainer) {
        self.viewControllers = viewControllers
        for viewController in viewControllers {
            let syncTargets = viewControllers.lazy.filter { ($0 as UIViewController) != viewController }
            let observer = Observer(
                target: viewController,
                syncOffset: syncOffset(targets: syncTargets),
                shrinkHeader: attachmentView.updateHeaderHeight(viaContentOffset:),
                setHeaderTop: attachmentView.updateHeaderTop
            )
            viewController.scrollView.contentInset = UIEdgeInsets(
                top: attachmentView.height(), left: 0, bottom: 0, right: 0
            )
            let subscription = viewController.scrollView.observe(
                \.contentOffset, options: [.new, .old], changeHandler: observer.on
            )
            subscriptions.append((observer, subscription))
        }
    }

    deinit {
        subscriptions.forEach { $1.invalidate() }
    }

    func syncOffset<S>(targets: S) -> (_ offset: CGPoint) -> Void
        where S: Sequence, S.Element == UIViewController & PageContent {
        return { offset in
            targets.forEach { target in
                target.scrollView.contentOffset = offset
            }
        }
    }

    class Observer {
        let syncOffset: (CGPoint) -> Void
        let shrinkHeader: (CGPoint) -> Void
        let setHeaderTop: (CGFloat) -> Void

        var isSynching: Bool = false
        init(target: UIViewController,
             syncOffset: @escaping (CGPoint) -> Void,
             shrinkHeader: @escaping (CGPoint) -> Void,
             setHeaderTop: @escaping (CGFloat) -> Void) {
            self.syncOffset = syncOffset
            self.shrinkHeader = shrinkHeader
            self.setHeaderTop = setHeaderTop
        }
        func on(scrollView: UIScrollView, change: NSKeyValueObservedChange<CGPoint>) {
            guard !isSynching else { return }
            guard let contentOffset = change.newValue,
                contentOffset != change.oldValue else { return }
            isSynching = true
            syncOffset(contentOffset)
            isSynching = false
            if contentOffset.y + scrollView.contentInset.top < 0 {
                shrinkHeader(contentOffset)
                setHeaderTop(0)
            } else {
                setHeaderTop(-(contentOffset.y + scrollView.contentInset.top))
            }
        }
    }
}
