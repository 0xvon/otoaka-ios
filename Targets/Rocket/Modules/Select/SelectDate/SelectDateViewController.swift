//
//  SelectDateViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/09/11.
//

import UIKit
import FSCalendar

final class SelectDateViewController: UIViewController {
    let dependencyProvider: LoggedInDependencyProvider
    
    private var datesRange: [Date] = []
    
    private lazy var calendar: FSCalendar = {
        let calendar = FSCalendar()
        calendar.translatesAutoresizingMaskIntoConstraints = false
        calendar.dataSource = self
        calendar.delegate = self
        calendar.allowsMultipleSelection = true
        
        calendar.appearance.weekdayTextColor = Brand.color(for: .brand(.primary))
        calendar.appearance.headerTitleColor = Brand.color(for: .brand(.primary))
        calendar.appearance.todayColor = .clear
        calendar.appearance.borderSelectionColor = Brand.color(for: .brand(.primary))
        calendar.appearance.selectionColor = .clear
        
        calendar.appearance.headerDateFormat = "yyyy年MM月"
        calendar.calendarWeekdayView.weekdayLabels[0].text = "日"
        calendar.calendarWeekdayView.weekdayLabels[1].text = "月"
        calendar.calendarWeekdayView.weekdayLabels[2].text = "火"
        calendar.calendarWeekdayView.weekdayLabels[3].text = "水"
        calendar.calendarWeekdayView.weekdayLabels[4].text = "木"
        calendar.calendarWeekdayView.weekdayLabels[5].text = "金"
        calendar.calendarWeekdayView.weekdayLabels[6].text = "土"
        return calendar
    }()
    
    private lazy var selectButton: PrimaryButton = {
        let button = PrimaryButton(text: "OK")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 25
        button.isEnabled = true
        button.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
        return button
    }()
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "日程を選択"
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        view.addSubview(calendar)
        NSLayoutConstraint.activate([
            calendar.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
            calendar.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
            calendar.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 24),
            calendar.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.width)
        ])
        
        view.addSubview(selectButton)
        NSLayoutConstraint.activate([
            selectButton.topAnchor.constraint(equalTo: calendar.bottomAnchor, constant: 24),
            selectButton.heightAnchor.constraint(equalToConstant: 50),
            selectButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            selectButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    @objc private func selectButtonTapped() {
        self.listener((datesRange.first, datesRange.last))
        self.navigationController?.popViewController(animated: true)
    }
    
    private var listener: ((Date?, Date?)) -> Void = { _ in }
    func listen(_ listener: @escaping ((Date?, Date?)) -> Void) {
        self.listener = listener
    }
}

extension SelectDateViewController: FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        return Brand.color(for: .text(.primary))
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        if datesRange.isEmpty {
            datesRange = [date]
        } else if datesRange.count == 1 {
            datesRange.append(date)
            datesRange = datesRange.sorted { $0 < $1 }
        } else {
            datesRange = []
        }
        calendarSelection()
        calendar.setCurrentPage(date, animated: true)
    }
    
    func calendar(_ calendar: FSCalendar, didDeselect date: Date, at monthPosition: FSCalendarMonthPosition) {
        datesRange = []
        calendarSelection()
    }
    
    func calendarSelection() {
        if datesRange.isEmpty {
            calendar.selectedDates.forEach { calendar.deselect($0) }
        } else {
            guard let fromDate = datesRange.first else { return }
            let range = range(from: fromDate, to: datesRange.last ?? fromDate)
            range.forEach { calendar.select($0) }
        }
    }
    
    func range(from: Date, to: Date) -> [Date] {
        if from > to { return [Date]() }
        var tempDate = from
        var array = [tempDate]
        while tempDate < to {
            tempDate = Calendar.current.date(byAdding: .day, value: 1, to: tempDate)!
            array.append(tempDate)
        }
        return array
    }
}
