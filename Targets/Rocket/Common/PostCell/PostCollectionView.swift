//
//  PostCollectionView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/02/01.
//

import UIKit
import ImagePipeline
import Endpoint

public final class PostCollectionView: UICollectionView {
    public var posts: [PostSummary]
    public var user: User
    public var imagePipeline: ImagePipeline
    
    public init(posts: [PostSummary], user: User, imagePipeline: ImagePipeline) {
        self.posts = posts
        self.user = user
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
    
    public func inject(posts: [PostSummary]) {
        self.posts = posts
        reloadData()
    }
    
    func setup() {
        backgroundColor = .clear
        
        registerCellClass(PostCollectionCell.self)
        delegate = self
        dataSource = self
        isPagingEnabled = false
        showsHorizontalScrollIndicator = false
    }
    private var listener: (PostCellContent.Output, PostSummary) -> Void = { _,_  in }
    public func listen(_ listener: @escaping (PostCellContent.Output, PostSummary) -> Void) {
        self.listener = listener
    }
}

extension PostCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var post = self.posts[indexPath.item]
        let cell = collectionView.dequeueReusableCell(PostCollectionCell.self, input: (post: post, user: user, imagePipeline: imagePipeline), for: indexPath)
        cell.listen { [unowned self] output in
            self.listener(output, post)
            if output == .likeTapped {
                post.isLiked.toggle()
            }
        }
        return cell
    }
}

extension PostCollectionView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width - 40, height: 410)
    }
}
