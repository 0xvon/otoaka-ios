//
//  UserStoryCarouselView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/11/01.
//

import UIKit
import ImagePipeline
import Endpoint

public final class StoryCollectionView: UICollectionView {
    public var items: StoryCollectionViewDataSource
    public var imagePipeline: ImagePipeline
    
    public enum StoryCollectionViewDataSource {
        case users([User])
        case groups([Group])
        case lives([Live])
    }
    public enum Output {
        case user(User)
        case group(Group)
        case live(Live)
    }
    
    public init(dataSource: StoryCollectionViewDataSource, imagePipeline: ImagePipeline) {
        self.items = dataSource
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
    
    public func inject(dataSource: StoryCollectionViewDataSource) {
        items = dataSource
        reloadData()
        switch dataSource {
        case .users(let array):
            setCollectionViewBackgroundView(isDisplay: array.isEmpty)
        case .groups(let array):
            setCollectionViewBackgroundView(isDisplay: array.isEmpty)
        case .lives(let array):
            setCollectionViewBackgroundView(isDisplay: array.isEmpty)
        }
    }
    
    func setup() {
        backgroundColor = .clear
        
        registerCellClass(StoryCaroucel.self)
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

extension StoryCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch items {
        case .users(let array):
            return array.count
        case .groups(let array):
            return array.count
        case .lives(let array):
            return array.count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch items {
        case .users(let users):
            let user = users[indexPath.item]
            return collectionView.dequeueReusableCell(StoryCaroucel.self, input: (imageUrl: user.thumbnailURL.flatMap(URL.init(string:)), imagePipeline: imagePipeline), for: indexPath)
        case .groups(let groups):
            let group = groups[indexPath.item]
            return collectionView.dequeueReusableCell(StoryCaroucel.self, input: (imageUrl: group.artworkURL, imagePipeline: imagePipeline), for: indexPath)
        case .lives(let lives):
            let live = lives[indexPath.item]
            return collectionView.dequeueReusableCell(StoryCaroucel.self, input: (imageUrl: live.artworkURL ?? live.hostGroup.artworkURL, imagePipeline: imagePipeline), for: indexPath)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch items {
        case .users(let users):
            let user = users[indexPath.item]
            self.listener(.user(user))
        case .groups(let groups):
            let group = groups[indexPath.item]
            self.listener(.group(group))
        case .lives(let lives):
            let live = lives[indexPath.item]
            self.listener(.live(live))
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func setCollectionViewBackgroundView(isDisplay: Bool = false) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .friend, actionButtonTitle: nil)
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        self.backgroundView = isDisplay ? emptyCollectionView : nil
        if let backgroundView = self.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: topAnchor),
                backgroundView.widthAnchor.constraint(equalTo: widthAnchor),
            ])
        }
    }
}

extension StoryCollectionView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 50, height: 50)
    }
}
