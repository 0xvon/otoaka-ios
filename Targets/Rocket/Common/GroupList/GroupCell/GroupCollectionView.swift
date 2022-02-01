//
//  GroupCollectionView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/02/01.
//

import UIKit
import ImagePipeline
import Endpoint

public final class GroupCollectionView: UICollectionView {
    public var groups: [GroupFeed] = []
    public var imagePipeline: ImagePipeline
    public enum Output {
        case groupTapped(GroupFeed)
        case followTapped(GroupFeed)
    }
    
    public init(groups: [GroupFeed], imagePipeline: ImagePipeline) {
        self.groups = groups
        self.imagePipeline = imagePipeline
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
        
        super.init(frame: .zero, collectionViewLayout: layout)
        setup()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func inject(groups: [GroupFeed]) {
        self.groups = groups
        reloadData()
    }
    
    func setup() {
        backgroundColor = .clear
        
        registerCellClass(GroupCollectionCell.self)
        delegate = self
        dataSource = self
        isPagingEnabled = false
        showsHorizontalScrollIndicator = false
    }
    private var listener: (Output) -> Void = { _ in }
    public func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}

extension GroupCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.groups.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var group = self.groups[indexPath.item]
        let cell = collectionView.dequeueReusableCell(GroupCollectionCell.self, input: (group: group, imagePipeline: imagePipeline, type: .normal), for: indexPath)
        cell.listen { [unowned self] output in
            switch output {
            case .selfTapped:
                listener(.groupTapped(group))
            case .likeButtonTapped:
                listener(.followTapped(group))
                group.isFollowing.toggle()
            case .listenButtonTapped: break
            }
        }
        return cell
    }
}

extension GroupCollectionView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width - 40, height: 200)
    }
}
