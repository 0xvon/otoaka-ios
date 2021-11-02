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
    private lazy var scrollStackView: UIStackView = {
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
        chart.backgroundColor = Brand.color(for: .background(.primary))
        chart.chartDescription?.enabled = false
        chart.dragEnabled = false
        chart.setScaleEnabled(true)
        chart.pinchZoomEnabled = false
        chart.maxHighlightDistance = 300
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
            chart.heightAnchor.constraint(equalToConstant: 300),
        ])
        return chart
    }()
    private lazy var watchingChartViewWrapper: UIView = Self.addPadding(to: self.watchingChartView)
    
    private lazy var watchingCountStaciView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
    }()
    
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
        view.backgroundColor = Brand.color(for: .background(.primary))
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
                let entries = zip(transition.yearLabel, transition.liveParticipatingCount).map { ChartDataEntry(x: Double($0.0)!, y: Double($0.1)) }
                let data = LineChartDataSet(entries: entries)
                data.mode = .cubicBezier
                data.drawCirclesEnabled = true
                data.lineWidth = 5
                data.circleRadius = 5
                data.circleHoleRadius = 2.5
                data.setColor(Brand.color(for: .text(.toggle)))
                data.setCircleColor(Brand.color(for: .text(.toggle)))
                data.circleHoleColor = Brand.color(for: .text(.toggle))
                data.highlightColor = Brand.color(for: .text(.toggle))
                data.drawValuesEnabled = true
                data.valueTextColor = Brand.color(for: .text(.primary))
                data.valueFont = Brand.font(for: .smallStrong)
                data.valueFormatter = ValueFormatter()
                
                watchingChartViewWrapper.isHidden = false
                watchingChartView.data = LineChartData(dataSet: data)
                watchingChartView.xAxis.setLabelCount(transition.yearLabel.count, force: true)
                watchingChartView.leftAxis.axisMaximum = Double(transition.liveParticipatingCount.max() ?? 5) + 10
                watchingChartView.leftAxis.axisMinimum = 0
                watchingChartView.setNeedsDisplay()
            case .didGetFrequentlyWathingGroups(let groups): break
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
    }
    
    class XAxisFormatter: NSObject, IAxisValueFormatter {
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            return "\(Int(value))年"
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
