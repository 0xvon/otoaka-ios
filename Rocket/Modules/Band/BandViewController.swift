//
//  BandViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import Foundation
import UIKit

final class BandViewController: UIViewController, Instantiable {
    
    typealias Input = Void
    var dependencyProvider: DependencyProvider!
    var startPoint: CGPoint!
    
    @IBOutlet weak var pageTitleStackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentsPageTitleView: TitleLabelView!
    @IBOutlet weak var chartsPageTitleView: TitleLabelView!
    @IBOutlet weak var bandsPageTitleView: TitleLabelView!
    @IBOutlet weak var horizontalScrollView: UIScrollView!
    @IBOutlet weak var searchBar: UISearchBar!
    
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
        horizontalScrollView.isPagingEnabled = true
        horizontalScrollView.translatesAutoresizingMaskIntoConstraints = false
        horizontalScrollView.contentSize = CGSize(width: UIScreen.main.bounds.width * 3, height: UIScreen.main.bounds.height)
        horizontalScrollView.delegate = self
        
        let contentsView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - searchBar.bounds.height))
        contentsView.backgroundColor = .red
        horizontalScrollView.addSubview(contentsView)
        
        let chartsView = UIView(frame: CGRect(x: UIScreen.main.bounds.width, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - searchBar.bounds.height))
        chartsView.backgroundColor = .blue
        horizontalScrollView.addSubview(chartsView)
        
        let bandsView = UIView(frame: CGRect(x: UIScreen.main.bounds.width * 2, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - searchBar.bounds.height))
        bandsView.backgroundColor = .green
        horizontalScrollView.addSubview(bandsView)
        
        contentsPageTitleView.inject(input: (title: "CONTENTS", font: style.font.xlarge.get(), color: style.color.main.get()))
        chartsPageTitleView.inject(input: (title: "CHARTS", font: style.font.regular.get(), color: style.color.main.get()))
        bandsPageTitleView.inject(input: (title: "BANDS", font: style.font.regular.get(), color: style.color.main.get()))
    }
}

extension BandViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == horizontalScrollView {
            startPoint = scrollView.contentOffset
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == horizontalScrollView {
            scrollView.contentOffset.y = startPoint.y
            let pageIndex: Int = min(Int(scrollView.contentOffset.x * 1.5 / UIScreen.main.bounds.width), 2)
            var titleViews: [TitleLabelView] = [contentsPageTitleView, chartsPageTitleView, bandsPageTitleView]
            titleViews[pageIndex].changeStyle(font: style.font.xlarge.get(), color: style.color.main.get())
            titleViews.remove(at: pageIndex)
            titleViews.forEach { $0.changeStyle(font: style.font.regular.get(), color: style.color.main.get()) }
            pageTitleStackViewLeadingConstraint.constant = CGFloat(16 - (scrollView.contentOffset.x / UIScreen.main.bounds.width * 70))
        }
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct BandViewController_Previews: PreviewProvider {
    static var previews: some View {
        ViewControllerWrapper<BandViewController>(
            dependencyProvider: .make(),
            input: ()
        )
    }
}

#endif

