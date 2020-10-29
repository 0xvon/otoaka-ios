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
    @IBOutlet weak var livePageTitleView: TitleLabelView!
    @IBOutlet weak var chartsPageTitleView: TitleLabelView!
    @IBOutlet weak var bandsPageTitleView: TitleLabelView!
    @IBOutlet weak var horizontalScrollView: UIScrollView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var contentsPageButton: UIButton!
    @IBOutlet weak var livePageButton: UIButton!
    @IBOutlet weak var chartsPageButton: UIButton!
    @IBOutlet weak var bandsPageButton: UIButton!
    
    private var contentsTableView: UITableView!
    private var liveTableView: UITableView!
    private var chartsTableView: UITableView!
    private var bandsTableView: UITableView!
    private var iconMenu: UIBarButtonItem!
    
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
        horizontalScrollView.contentSize.width = UIScreen.main.bounds.width * 4
    }
    
    func setup() {
        horizontalScrollView.delegate = self
        horizontalScrollView.backgroundColor = style.color.background.get()
        
        searchBar.barTintColor = style.color.background.get()
        searchBar.searchTextField.placeholder = "バンド・ライブを探す"
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
        
        let liveView = UIView()
        liveView.translatesAutoresizingMaskIntoConstraints = false
        liveView.backgroundColor = style.color.background.get()
        horizontalScrollView.addSubview(liveView)
        
        liveTableView = UITableView()
        liveTableView.translatesAutoresizingMaskIntoConstraints = false
        liveTableView.showsVerticalScrollIndicator = false
        liveTableView.backgroundColor = style.color.background.get()
        liveTableView.delegate = self
        liveTableView.dataSource = self
        liveTableView.register(UINib(nibName: "LiveCell", bundle: nil), forCellReuseIdentifier: "LiveCell")
        liveView.addSubview(liveTableView)
        
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
        livePageTitleView.inject(input: (title: "LIVE", font: style.font.regular.get(), color: style.color.main.get()))
        livePageTitleView.bringSubviewToFront(livePageButton)
        chartsPageTitleView.inject(input: (title: "CHARTS", font: style.font.regular.get(), color: style.color.main.get()))
        chartsPageTitleView.bringSubviewToFront(chartsPageButton)
        bandsPageTitleView.inject(input: (title: "BANDS", font: style.font.regular.get(), color: style.color.main.get()))
        bandsPageTitleView.bringSubviewToFront(bandsPageButton)
        
        let icon: UIButton = UIButton(type: .custom)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        icon.setImage(UIImage(named: "band"), for: .normal)
        icon.addTarget(self, action: #selector(iconTapped(_:)), for: .touchUpInside)
        icon.imageView?.layer.cornerRadius = 20
        
        iconMenu = UIBarButtonItem(customView: icon)
        self.navigationItem.leftBarButtonItem = iconMenu
        
        let constraint = [
            contentsView.leftAnchor.constraint(equalTo: horizontalScrollView.leftAnchor),
            contentsView.topAnchor.constraint(equalTo: horizontalScrollView.topAnchor),
            contentsView.bottomAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor),
            contentsView.centerYAnchor.constraint(equalTo: horizontalScrollView.centerYAnchor),
            contentsView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            
            liveView.leftAnchor.constraint(equalTo: contentsView.rightAnchor),
            liveView.topAnchor.constraint(equalTo: horizontalScrollView.topAnchor),
            liveView.bottomAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor),
            liveView.centerYAnchor.constraint(equalTo: horizontalScrollView.centerYAnchor),
            liveView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            
            chartsView.leftAnchor.constraint(equalTo: liveView.rightAnchor),
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
            
            liveTableView.leftAnchor.constraint(equalTo: liveView.leftAnchor, constant: 16),
            liveTableView.rightAnchor.constraint(equalTo: liveView.rightAnchor, constant: -16),
            liveTableView.topAnchor.constraint(equalTo: liveView.topAnchor, constant: 56),
            liveTableView.bottomAnchor.constraint(equalTo: liveView.bottomAnchor, constant: -16),
            
            chartsTableView.leftAnchor.constraint(equalTo: chartsView.leftAnchor, constant: 16),
            chartsTableView.rightAnchor.constraint(equalTo: chartsView.rightAnchor, constant: -16),
            chartsTableView.topAnchor.constraint(equalTo: chartsView.topAnchor, constant: 56),
            chartsTableView.bottomAnchor.constraint(equalTo: chartsView.bottomAnchor, constant: -16),
            
            bandsTableView.leftAnchor.constraint(equalTo: bandsView.leftAnchor, constant: 16),
            bandsTableView.rightAnchor.constraint(equalTo: bandsView.rightAnchor, constant: -16),
            bandsTableView.topAnchor.constraint(equalTo: bandsView.topAnchor, constant: 56),
            bandsTableView.bottomAnchor.constraint(equalTo: bandsView.bottomAnchor, constant: -16),
            
            iconMenu.customView!.widthAnchor.constraint(equalToConstant: 40),
            iconMenu.customView!.heightAnchor.constraint(equalToConstant: 40),
        ]
        NSLayoutConstraint.activate(constraint)
    }
    @IBAction func contentsPageButtonTapped(_ sender: Any) {
        UIScrollView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x = 0
        }
    }
    
    @IBAction func livePageButtonTapped(_ sender: Any) {
        UIScrollView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x = UIScreen.main.bounds.width
        }
    }
    
    @IBAction func chartsPageButtonTapped(_ sender: Any) {
        UIScrollView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x = UIScreen.main.bounds.width * 2
        }
        
    }
    
    @IBAction func bandsPageButtonTapped(_ sender: Any) {
        UIScrollView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x = UIScreen.main.bounds.width * 3
        }
    }
    
    @objc private func iconTapped(_ sender: Any) {
        let vc = AccountViewController(dependencyProvider: self.dependencyProvider, input: ())
        present(vc, animated: true, completion: nil)
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
        case self.liveTableView:
            return 300
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
        case self.liveTableView:
            let cell = tableView.reuse(LiveCell.self, input: Live(id: "123", title: "BANGOHAN TOUR 2020", type: .battles, host_id: "12345", open_at: "明日", start_at: "12時", end_at: "14時"), for: indexPath)
            cell.listen { [weak self] in
                self?.listenButtonTapped(cellIndex: indexPath.section)
            }
            cell.buyTicket { [weak self] in
                self?.buyTicketButtonTapped(cellIndex: indexPath.section)
            }
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
        switch tableView {
        case self.bandsTableView:
            let vc = BandDetailViewController(dependencyProvider: self.dependencyProvider, input: ())
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            print("hello")
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func listenButtonTapped(cellIndex: Int) {
        print("listen")
    }
    
    private func buyTicketButtonTapped(cellIndex: Int) {
        print("buy ticket")
    }
}

extension BandViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == horizontalScrollView {
            let pageIndex: Int = min(Int((scrollView.contentOffset.x + UIScreen.main.bounds.width / 2) / UIScreen.main.bounds.width), 3)
            var titleViews: [TitleLabelView] = [contentsPageTitleView, livePageTitleView, chartsPageTitleView, bandsPageTitleView]
            titleViews[pageIndex].changeStyle(font: style.font.xlarge.get(), color: style.color.main.get())
            titleViews.remove(at: pageIndex)
            titleViews.forEach { $0.changeStyle(font: style.font.regular.get(), color: style.color.main.get()) }
            pageTitleStackViewLeadingConstraint.constant = CGFloat(16 - (scrollView.contentOffset.x / UIScreen.main.bounds.width * 60))
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

