//
//  BandDetailHeaderView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import UIKit

final class BandDetailHeaderView: UIView {
    typealias Input = DependencyProvider
    
    var input: Input!
    
    private var horizontalScrollView: UIScrollView!
    private var bandInformationView: UIView!
    private var trackInformationView: UIView!
    private var biographyView: UIView!
    private var bandNameLabel: UILabel!
    private var mapBadgeView: BadgeView!
    private var dateBadgeView: BadgeView!
    private var productionBadgeView: BadgeView!
    private var labelBadgeView: BadgeView!
    private var bandImageView: UIImageView!
    private var arrowButton: UIButton!
    private var artworkImageView: UIImageView!
    private var playButton: Button!
    private var trackNameLabel: UILabel!
    private var releasedDataLabel: UILabel!
    private var seeMoreTracksButton: UIButton!
    private var stackView: UIStackView!
    private var twitterButton: UIButton!
    private var youtubeButton: UIButton!
    private var appleMusicButton: UIButton!
    private var spotifyButton: UIButton!
    private var biographyTextView: UITextView!
    
    init(input: Input) {
        self.input = input
        super.init(frame: .zero)
        self.inject(input: input)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
        
    func inject(input: Input) {
        self.input = input
        self.setup()
    }
    
    func setup() {
        backgroundColor = .clear
        let contentView = UIView(frame: self.frame)
        addSubview(contentView)
        
        contentView.backgroundColor = .clear
        contentView.layer.opacity = 0.8
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        bandImageView = UIImageView()
        bandImageView.translatesAutoresizingMaskIntoConstraints = false
        bandImageView.image = UIImage(named: "jacket")
        bandImageView.contentMode = .scaleAspectFill
        bandImageView.layer.opacity = 0.6
        addSubview(bandImageView)
        
        horizontalScrollView = UIScrollView()
        horizontalScrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(horizontalScrollView)
        horizontalScrollView.isPagingEnabled = true
        horizontalScrollView.isScrollEnabled = true
        horizontalScrollView.showsHorizontalScrollIndicator = false
        horizontalScrollView.showsVerticalScrollIndicator = false
        horizontalScrollView.contentSize = CGSize(width: UIScreen.main.bounds.width * 3, height: self.frame.height)
        horizontalScrollView.delegate = self
        
        bandInformationView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: self.frame.height))
        bandInformationView.backgroundColor = .clear
        horizontalScrollView.addSubview(bandInformationView)
        
        trackInformationView = UIView(frame: CGRect(x: UIScreen.main.bounds.width, y: 0, width: UIScreen.main.bounds.width, height: self.bounds.height))
        trackInformationView.backgroundColor = .clear
        horizontalScrollView.addSubview(trackInformationView)
        
        biographyView = UIView(frame: CGRect(x: UIScreen.main.bounds.width * 2, y: 0, width: UIScreen.main.bounds.width, height: self.bounds.height))
        biographyView.backgroundColor = .clear
        horizontalScrollView.addSubview(biographyView)
        
        bandNameLabel = UILabel()
        bandNameLabel.translatesAutoresizingMaskIntoConstraints = false
        bandNameLabel.text = "MY FIRST STORY"
        bandNameLabel.font = style.font.xlarge.get()
        bandNameLabel.textColor = style.color.main.get()
        bandNameLabel.lineBreakMode = .byWordWrapping
        bandNameLabel.numberOfLines = 0
        bandNameLabel.adjustsFontSizeToFitWidth = false
        bandNameLabel.sizeToFit()
        bandInformationView.addSubview(bandNameLabel)
        
        dateBadgeView = BadgeView(input: (text: "2011年", image: UIImage(named: "calendar")))
        bandInformationView.addSubview(dateBadgeView)
        
        mapBadgeView = BadgeView(input: (text: "東京", image: UIImage(named: "map")))
        bandInformationView.addSubview(mapBadgeView)
        
        labelBadgeView = BadgeView(input: (text: "Intact Records", image: UIImage(named: "record")))
        bandInformationView.addSubview(labelBadgeView)
        
        productionBadgeView = BadgeView(input: (text: "Japan Music Systems", image: UIImage(named: "production")))
        bandInformationView.addSubview(productionBadgeView)
        
        arrowButton = UIButton()
        arrowButton.translatesAutoresizingMaskIntoConstraints = false
        arrowButton.contentMode = .scaleAspectFit
        arrowButton.contentHorizontalAlignment = .fill
        arrowButton.contentVerticalAlignment = .fill
        arrowButton.setImage(UIImage(named: "arrow"), for: .normal)
        arrowButton.addTarget(self, action: #selector(nextPage), for: .touchUpInside)
        bandInformationView.addSubview(arrowButton)
        
        artworkImageView = UIImageView()
        artworkImageView.translatesAutoresizingMaskIntoConstraints = false
        artworkImageView.image = UIImage(named: "track")
        artworkImageView.layer.cornerRadius = 10
        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.clipsToBounds = true
        trackInformationView.addSubview(artworkImageView)
        
        playButton = Button(input: (text: "再生", image: UIImage(named: "play")))
        playButton.layer.cornerRadius = 18
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.listen {
            self.play()
        }
        trackInformationView.addSubview(playButton)
        
        trackNameLabel = UILabel()
        trackNameLabel.translatesAutoresizingMaskIntoConstraints = false
        trackNameLabel.text = "不可逆リプレイス"
        trackNameLabel.font = style.font.regular.get()
        trackNameLabel.textColor = style.color.main.get()
        trackInformationView.addSubview(trackNameLabel)
        
        releasedDataLabel = UILabel()
        releasedDataLabel.translatesAutoresizingMaskIntoConstraints = false
        releasedDataLabel.text = "2016年"
        releasedDataLabel.font = style.font.regular.get()
        releasedDataLabel.textColor = style.color.main.get()
        trackInformationView.addSubview(releasedDataLabel)
        
        seeMoreTracksButton = UIButton()
        seeMoreTracksButton.translatesAutoresizingMaskIntoConstraints = false
        seeMoreTracksButton.setTitle("もっと見る", for: .normal)
        seeMoreTracksButton.setTitleColor(style.color.main.get(), for: .normal)
        seeMoreTracksButton.titleLabel?.font = style.font.small.get()
        seeMoreTracksButton.addTarget(self, action: #selector(seeMoreButtonTapped(_:)), for: .touchUpInside)
        trackInformationView.addSubview(seeMoreTracksButton)
        
        stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        trackInformationView.addSubview(stackView)
        
        twitterButton = UIButton()
        twitterButton.translatesAutoresizingMaskIntoConstraints = false
        twitterButton.contentHorizontalAlignment = .fill
        twitterButton.contentVerticalAlignment = .fill
        twitterButton.setImage(UIImage(named: "twitter"), for: .normal)
        twitterButton.imageView?.contentMode = .scaleAspectFit
        twitterButton.addTarget(self, action: #selector(twitterButtonTapped(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(twitterButton)
        
        youtubeButton = UIButton()
        youtubeButton.translatesAutoresizingMaskIntoConstraints = false
        youtubeButton.contentHorizontalAlignment = .fill
        youtubeButton.contentVerticalAlignment = .fill
        youtubeButton.setImage(UIImage(named: "youtube"), for: .normal)
        youtubeButton.imageView?.contentMode = .scaleAspectFit
        youtubeButton.addTarget(self, action: #selector(youtubeButtonTapped(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(youtubeButton)
        
        appleMusicButton = UIButton()
        appleMusicButton.translatesAutoresizingMaskIntoConstraints = false
        appleMusicButton.contentHorizontalAlignment = .fill
        appleMusicButton.contentVerticalAlignment = .fill
        appleMusicButton.setImage(UIImage(named: "itunes"), for: .normal)
        appleMusicButton.imageView?.contentMode = .scaleAspectFit
        appleMusicButton.addTarget(self, action: #selector(appleMusicButtonTapped(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(appleMusicButton)
        
        spotifyButton = UIButton()
        spotifyButton.translatesAutoresizingMaskIntoConstraints = false
        spotifyButton.contentHorizontalAlignment = .fill
        spotifyButton.contentVerticalAlignment = .fill
        spotifyButton.setImage(UIImage(named: "spotify"), for: .normal)
        spotifyButton.imageView?.contentMode = .scaleAspectFit
        spotifyButton.addTarget(self, action: #selector(spotifyButtonTapped(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(spotifyButton)
        
        biographyTextView = UITextView()
        biographyTextView.translatesAutoresizingMaskIntoConstraints = false
        biographyTextView.isScrollEnabled = true
        biographyTextView.textColor = style.color.main.get()
        biographyTextView.backgroundColor = .clear
        biographyTextView.font = style.font.regular.get()
        biographyView.addSubview(biographyTextView)
        biographyTextView.text = "Kid'z(Dr.) / Hiro(Vo.) / Nob(Ba.) / Teru(Gu.) (L→R)\n\n2011年夏、東京渋谷で結成。\n\n2012年4月に1st FULL AL「MY FIRST STORY」でデビュー以降、確かな楽曲、ライブパフォーマンスが話題を呼び、全国の大型フェス出演や海外アーティストとの共演も数多く務め、着実に実力を付けた。\n\n2016年 4th FULL AL「ANTITHESE」をリリース。自身最高位であるオリコンウィークリー初登場４位を記録し、そのアルバムを携え、日本全国47都道府県を回るツアー。最終公演は日本武道館にて開催し、12,000人を動員しSOLD OUT。\n\n2017年''MMA'' TOURを開催。その最終公演として12月千葉 幕張メッセ 国際展示場9～11ホールにて開催し、外国人奏者による全曲フルオーケストラコンサートで、18,000人のオーディエンスは驚愕した。\n\n2018年、S･S･S TOURとして全国ライブハウスを回り、大阪、福岡、仙台、名古屋にて初のホールツアー。最終公演はこちらも初となる横浜アリーナ2days公演を行った。\n\n2019年、 「MY FIRST STORY TOUR 2019」として、ライブハウス・ホール編に加え、神戸ワールド記念ホール・さいたまスーパーアリーナにてアリーナツアーを開催。\n\nそして2020年、「MY FIRST STORY TOUR 2020」の開催が発表された。今年もライブハウス・ホールに加え、ファイナルシリーズとして初の東名阪3都市でのアリーナツアーが決定！\n\n絶えず進化を遂げる孤高のロックバンドMY FIRST STORYの躍進を見逃すわけにはいかないだろう。"
        
        let constraints = [
            topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            leftAnchor.constraint(equalTo: contentView.leftAnchor),
            rightAnchor.constraint(equalTo: contentView.rightAnchor),
            
            bandImageView.topAnchor.constraint(equalTo: topAnchor),
            bandImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bandImageView.leftAnchor.constraint(equalTo: leftAnchor),
            bandImageView.rightAnchor.constraint(equalTo: rightAnchor),
            
            horizontalScrollView.topAnchor.constraint(equalTo: topAnchor),
            horizontalScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalScrollView.leftAnchor.constraint(equalTo: leftAnchor),
            horizontalScrollView.rightAnchor.constraint(equalTo: rightAnchor),
            
            bandNameLabel.topAnchor.constraint(equalTo: bandInformationView.topAnchor, constant: 16),
            bandNameLabel.leftAnchor.constraint(equalTo: bandInformationView.leftAnchor, constant: 16),
            bandNameLabel.rightAnchor.constraint(equalTo: bandInformationView.rightAnchor, constant: -16),
            
            dateBadgeView.bottomAnchor.constraint(equalTo: bandInformationView.bottomAnchor, constant: -16),
            dateBadgeView.leftAnchor.constraint(equalTo: bandInformationView.leftAnchor, constant: 16),
            dateBadgeView.widthAnchor.constraint(equalToConstant: 160),
            dateBadgeView.heightAnchor.constraint(equalToConstant: 30),
            
            mapBadgeView.bottomAnchor.constraint(equalTo: dateBadgeView.topAnchor, constant: -8),
            mapBadgeView.leftAnchor.constraint(equalTo: bandInformationView.leftAnchor, constant: 16),
            mapBadgeView.widthAnchor.constraint(equalToConstant: 160),
            mapBadgeView.heightAnchor.constraint(equalToConstant: 30),
            
            labelBadgeView.bottomAnchor.constraint(equalTo: mapBadgeView.topAnchor, constant: -8),
            labelBadgeView.leftAnchor.constraint(equalTo: bandInformationView.leftAnchor, constant: 16),
            labelBadgeView.widthAnchor.constraint(equalToConstant: 160),
            labelBadgeView.heightAnchor.constraint(equalToConstant: 30),
            
            productionBadgeView.bottomAnchor.constraint(equalTo: labelBadgeView.topAnchor, constant: -8),
            productionBadgeView.leftAnchor.constraint(equalTo: bandInformationView.leftAnchor, constant: 16),
            productionBadgeView.widthAnchor.constraint(equalToConstant: 160),
            productionBadgeView.heightAnchor.constraint(equalToConstant: 30),
            
            arrowButton.rightAnchor.constraint(equalTo: bandInformationView.rightAnchor, constant: -16),
            arrowButton.bottomAnchor.constraint(equalTo: bandInformationView.bottomAnchor, constant: -16),
            arrowButton.widthAnchor.constraint(equalToConstant: 54),
            arrowButton.heightAnchor.constraint(equalToConstant: 28),
            
            artworkImageView.leftAnchor.constraint(equalTo: trackInformationView.leftAnchor, constant: 36),
            artworkImageView.topAnchor.constraint(equalTo: trackInformationView.topAnchor, constant: 48),
            artworkImageView.widthAnchor.constraint(equalToConstant: 120),
            artworkImageView.heightAnchor.constraint(equalToConstant: 120),
            
            playButton.leftAnchor.constraint(equalTo: artworkImageView.rightAnchor, constant: 24),
            playButton.topAnchor.constraint(equalTo: artworkImageView.topAnchor, constant: 8),
            playButton.widthAnchor.constraint(equalToConstant: 150),
            playButton.heightAnchor.constraint(equalToConstant: 36),
            
            trackNameLabel.leftAnchor.constraint(equalTo: playButton.leftAnchor),
            trackNameLabel.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 8),
            
            releasedDataLabel.leftAnchor.constraint(equalTo: playButton.leftAnchor),
            releasedDataLabel.topAnchor.constraint(equalTo: trackNameLabel.bottomAnchor, constant: 4),
            
            seeMoreTracksButton.topAnchor.constraint(equalTo: trackInformationView.topAnchor, constant: 16),
            seeMoreTracksButton.rightAnchor.constraint(equalTo: trackInformationView.rightAnchor, constant: -32),
            
            stackView.rightAnchor.constraint(equalTo: trackInformationView.rightAnchor, constant: -32),
            stackView.bottomAnchor.constraint(equalTo: trackInformationView.bottomAnchor, constant: -16),
            stackView.heightAnchor.constraint(equalToConstant: 24),
            
            twitterButton.widthAnchor.constraint(equalToConstant: 24),
            
            biographyTextView.topAnchor.constraint(equalTo: biographyView.topAnchor, constant: 16),
            biographyTextView.bottomAnchor.constraint(equalTo: biographyView.bottomAnchor, constant: -16),
            biographyTextView.rightAnchor.constraint(equalTo: biographyView.rightAnchor, constant: -16),
            biographyTextView.leftAnchor.constraint(equalTo: biographyView.leftAnchor, constant: 16),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    private func play() {
        print("play")
    }
    
    @objc private func nextPage() {
        UIView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x += UIScreen.main.bounds.width
        }
    }
    
    @objc private func seeMoreButtonTapped(_ sender: UIButton) {
        print("see more")
    }
    
    @objc private func twitterButtonTapped(_ sender: UIButton) {
        print("twitter")
    }
    
    @objc private func youtubeButtonTapped(_ sender: UIButton) {
        print("youtube")
    }
    
    @objc private func appleMusicButtonTapped(_ sender: UIButton) {
        print("itunes")
    }
    
    @objc private func spotifyButtonTapped(_ sender: UIButton) {
        print("spotify")
    }
}

extension BandDetailHeaderView: UIScrollViewDelegate {
}