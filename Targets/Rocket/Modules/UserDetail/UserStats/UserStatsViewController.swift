//
//  UserStatsViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/11/02.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import InternalDomain
import Charts

final class UserStatsViewController: UIViewController, Instantiable {
    typealias Input = User
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: UserStatsViewModel
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var verticalScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    public lazy var scrollStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()
    
    private let watchingCountSectionHeader = SummarySectionHeader(title: "ライブ参戦数")
    private lazy var watchingChartView: LineChartView = {
        let chart = LineChartView()
        chart.translatesAutoresizingMaskIntoConstraints = false
        chart.setViewPortOffsets(left: 24, top: 24, right: 24, bottom: 24)
        chart.setYAxisMinWidth(.left, width: 20)
        chart.backgroundColor = .clear
        chart.chartDescription?.enabled = false
        chart.dragEnabled = false
        chart.setScaleEnabled(false)
        chart.pinchZoomEnabled = true
        chart.legend.enabled = false
        chart.rightAxis.enabled = false
        
        chart.xAxis.enabled = true
        chart.xAxis.axisLineWidth = 0
        chart.xAxis.labelFont = Brand.font(for: .smallStrong)
        chart.xAxis.labelTextColor = Brand.color(for: .text(.primary))
        chart.xAxis.labelPosition = .top
        chart.xAxis.valueFormatter = XAxisFormatter()
        
        chart.leftAxis.enabled = false
        
        NSLayoutConstraint.activate([
            chart.heightAnchor.constraint(equalToConstant: 224),
        ])
        return chart
    }()
    private lazy var watchingChartViewWrapper: UIView = Self.addPadding(to: self.watchingChartView)
    private lazy var watchingCountStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 24
        stackView.distribution = .fillEqually
        stackView.addArrangedSubview(watchingCountSummaryView)
        stackView.addArrangedSubview(ticketPriceSummaryView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.heightAnchor.constraint(equalToConstant: 72)
        ])
        return stackView
    }()
    private lazy var watchingCountStackViewWrapper: UIView = Self.addPadding(to: self.watchingCountStackView)
    private lazy var watchingCountSummaryView: StatsSummaryView = {
        let view = StatsSummaryView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var ticketPriceSummaryView: StatsSummaryView = {
        let view = StatsSummaryView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let frequentlyWatchingGroupSectionHeader = SummarySectionHeader(title: "よく参戦するアーティスト")
    private lazy var frequentlyWatchingGroupContent: WatchRankingCollectionView = {
        let content = WatchRankingCollectionView(groups: [], imagePipeline: dependencyProvider.imagePipeline)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 200)
        ])
        return content
    }()
    private lazy var frequentlyWatchingGroupContentWrapper: UIView = Self.addPadding(to: self.frequentlyWatchingGroupContent)
    
    private static func addPadding(to view: UIView) -> UIView {
        let paddingView = UIView()
        paddingView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: paddingView.leftAnchor, constant: 16),
            paddingView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 16),
            view.topAnchor.constraint(equalTo: paddingView.topAnchor),
            view.bottomAnchor.constraint(equalTo: paddingView.bottomAnchor),
        ])
        return paddingView
    }
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = UserStatsViewModel(dependencyProvider: dependencyProvider, input: input)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
        viewModel.viewDidLoad()
    }
    
    override func loadView() {
        view = verticalScrollView
        view.backgroundColor = .clear
        view.addSubview(scrollStackView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: scrollStackView.topAnchor),
            view.bottomAnchor.constraint(equalTo: scrollStackView.bottomAnchor),
            view.leftAnchor.constraint(equalTo: scrollStackView.leftAnchor),
            view.rightAnchor.constraint(equalTo: scrollStackView.rightAnchor),
        ])
        
        scrollStackView.addArrangedSubview(watchingCountSectionHeader)
        NSLayoutConstraint.activate([
            watchingCountSectionHeader.heightAnchor.constraint(equalToConstant: 64),
            watchingCountSectionHeader.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        watchingChartViewWrapper.isHidden = true
        scrollStackView.addArrangedSubview(watchingChartViewWrapper)
        watchingCountStackViewWrapper.isHidden = true
        scrollStackView.addArrangedSubview(watchingCountStackViewWrapper)
        
        scrollStackView.addArrangedSubview(frequentlyWatchingGroupSectionHeader)
        NSLayoutConstraint.activate([
            frequentlyWatchingGroupSectionHeader.heightAnchor.constraint(equalToConstant: 64),
            frequentlyWatchingGroupSectionHeader.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        frequentlyWatchingGroupContentWrapper.isHidden = true
        scrollStackView.addArrangedSubview(frequentlyWatchingGroupContentWrapper)
        
        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        scrollStackView.addArrangedSubview(bottomSpacer) // Spacer
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 64),
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] output in
            switch output {
            case .didGetLiveTransition(let transition):
                var entries = [ChartDataEntry]()
                print(transition)
                zip(transition.yearLabel, transition.liveParticipatingCount).forEach {
                    guard let year = Double($0.0) else { return }
                    if !transition.yearLabel.contains(String(Int(year - 1))) {
                        entries.append(ChartDataEntry(x: year - 1, y: 0))
                    }
                    entries.append(ChartDataEntry(x: year, y: Double($0.1)))
                }
                let data = LineChartDataSet(entries: entries)
                data.mode = .cubicBezier
                data.drawCirclesEnabled = true
                data.lineWidth = 5
                data.circleRadius = 5
                data.circleHoleRadius = 2.5
                data.setColor(Brand.color(for: .brand(.primary)))
                data.setCircleColor(Brand.color(for: .brand(.primary)))
                data.circleHoleColor = Brand.color(for: .brand(.primary))
                data.highlightColor = Brand.color(for: .brand(.primary))
                data.drawValuesEnabled = true
                data.valueTextColor = Brand.color(for: .text(.primary))
                data.valueFont = Brand.font(for: .smallStrong)
                data.valueFormatter = ValueFormatter()
                
                watchingChartViewWrapper.isHidden = false
                watchingChartView.data = LineChartData(dataSet: data)
                watchingChartView.xAxis.setLabelCount(entries.count, force: true)
                watchingChartView.leftAxis.axisMaximum = Double(transition.liveParticipatingCount.max() ?? 5) * 1.5
                watchingChartView.leftAxis.axisMinimum = -1
                watchingChartView.setNeedsDisplay()
                
                let watchingCount: Int = transition.liveParticipatingCount.reduce(0, +)
                watchingCountStackViewWrapper.isHidden = false
                watchingCountSummaryView.update(input: (
                    title: "総ライブ参戦数",
                    count: watchingCount,
                    unit: "回"
                ))
                ticketPriceSummaryView.update(input: (
                    title: "推定チケット総額",
                    count: watchingCount * 5000,
                    unit: "円"
                ))
            case .didGetFrequentlyWathingGroups(let groups):
                frequentlyWatchingGroupContentWrapper.isHidden = false
                frequentlyWatchingGroupContent.inject(group: groups)
            case .reportError(let err):
                print(String(describing: err))
                showAlert()
            }
        })
        .store(in: &cancellables)
        
        watchingCountSectionHeader.listen { [unowned self] in
            let vc = LiveListViewController(dependencyProvider: dependencyProvider, input: .likedLive(viewModel.state.user.id))
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        frequentlyWatchingGroupSectionHeader.listen { [unowned self] in
            let vc = GroupListViewController(dependencyProvider: dependencyProvider, input: .frequenlyWatchingGroups(viewModel.state.user.id))
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        frequentlyWatchingGroupContent.listen { [unowned self] group in
            let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: group.group)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    class XAxisFormatter: NSObject, IAxisValueFormatter {
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            return "'\(String(Int(value)).suffix(2))"
        }
    }
    
    class ValueFormatter: NSObject, IValueFormatter {
        func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
            return "\(Int(value))回"
        }
    }
}

extension UserStatsViewController: PageContent {
    var scrollView: UIScrollView {
        _ = view
        return self.verticalScrollView
    }
}
