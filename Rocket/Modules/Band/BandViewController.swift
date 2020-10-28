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
    
    @IBOutlet weak var pageTitleStackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentsPageTitleView: TitleLabelView!
    @IBOutlet weak var chartsPageTitleView: TitleLabelView!
    @IBOutlet weak var bandsPageTitleView: TitleLabelView!
    @IBOutlet weak var horizontalScrollView: UIScrollView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var contentsPageButton: UIButton!
    @IBOutlet weak var chartsPageButton: UIButton!
    @IBOutlet weak var bandsPageButton: UIButton!
    
    private var contentsTableView: UITableView!
    private var chartsTableView: UITableView!
    private var bandsTableView: UITableView!
    
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
    
    override func viewDidLayoutSubviews() {
        horizontalScrollView.contentSize.width = UIScreen.main.bounds.width * 3
    }
    
    func setup() {
        horizontalScrollView.delegate = self
        
        searchBar.barTintColor = style.color.background.get()
        searchBar.searchTextField.placeholder = "バンドを探す"
        searchBar.searchTextField.textColor = style.color.main.get()
        
        let contentsView = UIView()
        contentsView.translatesAutoresizingMaskIntoConstraints = false
        contentsView.backgroundColor = style.color.background.get()
        horizontalScrollView.addSubview(contentsView)
        
        contentsTableView = UITableView()
        contentsTableView.translatesAutoresizingMaskIntoConstraints = false
        contentsTableView.showsVerticalScrollIndicator = false
        contentsTableView.backgroundColor = style.color.background.get()
        contentsTableView.delegate = self
        contentsTableView.dataSource = self
        contentsTableView.register(UINib(nibName: "BandContentsCell", bundle: nil), forCellReuseIdentifier: "BandContentsCell")
        contentsView.addSubview(contentsTableView)
        
        let chartsView = UIView()
        chartsView.translatesAutoresizingMaskIntoConstraints = false
        chartsView.backgroundColor = style.color.background.get()
        horizontalScrollView.addSubview(chartsView)
        
        chartsTableView = UITableView()
        chartsTableView.translatesAutoresizingMaskIntoConstraints = false
        chartsTableView.showsVerticalScrollIndicator = false
        chartsTableView.backgroundColor = style.color.background.get()
        chartsTableView.delegate = self
        chartsTableView.dataSource = self
        chartsTableView.register(UINib(nibName: "TrackCell", bundle: nil), forCellReuseIdentifier: "TrackCell")
        chartsView.addSubview(chartsTableView)
        
        let bandsView = UIView()
        bandsView.translatesAutoresizingMaskIntoConstraints = false
        bandsView.backgroundColor = style.color.background.get()
        horizontalScrollView.addSubview(bandsView)
        
        bandsTableView = UITableView()
        bandsTableView.translatesAutoresizingMaskIntoConstraints = false
        bandsTableView.showsVerticalScrollIndicator = false
        bandsTableView.backgroundColor = style.color.background.get()
        bandsTableView.delegate = self
        bandsTableView.dataSource = self
        bandsTableView.register(UINib(nibName: "BandCell", bundle: nil), forCellReuseIdentifier: "BandCell")
        bandsView.addSubview(bandsTableView)
        
        contentsPageTitleView.inject(input: (title: "CONTENTS", font: style.font.xlarge.get(), color: style.color.main.get()))
        contentsPageTitleView.bringSubviewToFront(contentsPageButton)
        chartsPageTitleView.inject(input: (title: "CHARTS", font: style.font.regular.get(), color: style.color.main.get()))
        chartsPageTitleView.bringSubviewToFront(chartsPageButton)
        bandsPageTitleView.inject(input: (title: "BANDS", font: style.font.regular.get(), color: style.color.main.get()))
        bandsPageTitleView.bringSubviewToFront(bandsPageButton)
        
        let constraint = [
            contentsView.leftAnchor.constraint(equalTo: horizontalScrollView.leftAnchor),
            contentsView.topAnchor.constraint(equalTo: horizontalScrollView.topAnchor),
            contentsView.bottomAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor),
            contentsView.centerYAnchor.constraint(equalTo: horizontalScrollView.centerYAnchor),
            contentsView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            
            chartsView.leftAnchor.constraint(equalTo: contentsView.rightAnchor),
            chartsView.topAnchor.constraint(equalTo: horizontalScrollView.topAnchor),
            chartsView.bottomAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor),
            chartsView.centerYAnchor.constraint(equalTo: horizontalScrollView.centerYAnchor),
            chartsView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            
            bandsView.leftAnchor.constraint(equalTo: chartsView.rightAnchor),
            bandsView.topAnchor.constraint(equalTo: horizontalScrollView.topAnchor),
            bandsView.bottomAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor),
            bandsView.centerYAnchor.constraint(equalTo: horizontalScrollView.centerYAnchor),
            bandsView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            
            contentsTableView.leftAnchor.constraint(equalTo: contentsView.leftAnchor, constant: 16),
            contentsTableView.rightAnchor.constraint(equalTo: contentsView.rightAnchor, constant: -16),
            contentsTableView.topAnchor.constraint(equalTo: contentsView.topAnchor, constant: 56),
            contentsTableView.bottomAnchor.constraint(equalTo: contentsView.bottomAnchor, constant: -16),
            
            chartsTableView.leftAnchor.constraint(equalTo: chartsView.leftAnchor, constant: 16),
            chartsTableView.rightAnchor.constraint(equalTo: chartsView.rightAnchor, constant: -16),
            chartsTableView.topAnchor.constraint(equalTo: chartsView.topAnchor, constant: 56),
            chartsTableView.bottomAnchor.constraint(equalTo: chartsView.bottomAnchor, constant: -16),
            
            bandsTableView.leftAnchor.constraint(equalTo: bandsView.leftAnchor, constant: 16),
            bandsTableView.rightAnchor.constraint(equalTo: bandsView.rightAnchor, constant: -16),
            bandsTableView.topAnchor.constraint(equalTo: bandsView.topAnchor, constant: 56),
            bandsTableView.bottomAnchor.constraint(equalTo: bandsView.bottomAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraint)
    }
    @IBAction func contentsPageButtonTapped(_ sender: Any) {
        UIScrollView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x = 0
        }
    }
    @IBAction func chartsPageButtonTapped(_ sender: Any) {
        UIScrollView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x = UIScreen.main.bounds.width
        }
        
    }
    
    @IBAction func bandsPageButtonTapped(_ sender: Any) {
        UIScrollView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x = UIScreen.main.bounds.width * 2
        }
    }
}

extension BandViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView {
        case self.contentsTableView:
            return 200
        case self.chartsTableView:
            return 400
        case self.bandsTableView:
            return 250
        default:
            return 100
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case self.contentsTableView:
            let cell = tableView.reuse(BandContentsCell.self, input: (), for: indexPath)
            return cell
        case self.chartsTableView:
            let cell = tableView.reuse(TrackCell.self, input: (), for: indexPath)
            return cell
        case self.bandsTableView:
            let cell = tableView.reuse(BandCell.self, input: (), for: indexPath)
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension BandViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == horizontalScrollView {
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

