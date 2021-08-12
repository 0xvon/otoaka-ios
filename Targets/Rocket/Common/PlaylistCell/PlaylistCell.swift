//
//  PlaylistCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/04/23.
//

import UIKit
import Endpoint
import ImagePipeline

class PlaylistCellContent: UIButton {
    typealias Input = (
        tracks: [Track],
        imagePipeline: ImagePipeline
    )
    var input: Input?
    
    enum Output {
        case playButtonTapped(Track)
        case trackTapped(Track)
    }
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var trackTableView: UITableView!
    
    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1.0 }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    func inject(input: Input) {
        self.input = input
        if let artwork = input.tracks.first?.artwork, let artworkURL = URL(string: artwork) {
            input.imagePipeline.loadImage(artworkURL, into: thumbnailImageView)
        }
        trackTableView.reloadData()
    }
    
    func setup() {
        self.backgroundColor = .clear
        self.layer.borderWidth = 1
        self.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        self.layer.cornerRadius = 10
        
        thumbnailImageView.layer.opacity = 0.3
        thumbnailImageView.layer.cornerRadius = 10
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.contentMode = .scaleAspectFill
        
        trackTableView.delegate = self
        trackTableView.dataSource = self
        trackTableView.registerCellClass(TrackCell.self)
        trackTableView.separatorStyle = .none
        trackTableView.backgroundColor = .clear
        trackTableView.showsVerticalScrollIndicator = true
        trackTableView.tableFooterView = UIView(frame: .zero)
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}

extension PlaylistCellContent: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let tracks = input?.tracks {
            return tracks.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = input!.tracks[indexPath.row]
        let cell = tableView.dequeueReusableCell(TrackCell.self, input: (track: track, imagePipeline: input!.imagePipeline), for: indexPath)
        cell.listen { [unowned self] output in
            switch output {
            case .playButtonTapped: self.listener(.playButtonTapped(track))
            case .groupTapped: break
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let track = input!.tracks[indexPath.row]
        self.listener(.trackTapped(track))
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
