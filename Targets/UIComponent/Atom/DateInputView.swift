//
//  DateInputView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/01/03.
//

import UIKit

public final class DateInputView: UIView {
    private lazy var sectionLabel: UILabel = {
        let section = UILabel()
        section.translatesAutoresizingMaskIntoConstraints = false
        section.text = ""
        section.font = Brand.font(for: .medium)
        section.textColor = Brand.color(for: .text(.toggle))
        return section
    }()
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.minimumDate = Date()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerMode = .dateAndTime
        datePicker.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        datePicker.addTarget(
            self, action: #selector(didChangeDatePickerValue(_:)), for: .valueChanged)
        datePicker.tintColor = Brand.color(for: .text(.primary))
        datePicker.backgroundColor = .clear
        return datePicker
    }()
    private lazy var underLine: UIView = {
        let underLine = UIView()
        underLine.translatesAutoresizingMaskIntoConstraints = false
        return underLine
    }()
    
    public init(section: String) {
        super.init(frame: .zero)
        
        setup()
        inject(section: section)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
    }
    
    public var date: Date {
        get { datePicker.date }
        set { datePicker.date = newValue }
    }
    
    public var maximumDate: Date? {
        get { datePicker.minimumDate }
        set { datePicker.minimumDate = newValue }
    }
    
    public func inject(section: String, date: Date = Date()) {
        sectionLabel.text = section
        datePicker.date = date
    }
    
    func setup() {
        self.backgroundColor = .clear
        
        addSubview(sectionLabel)
        NSLayoutConstraint.activate([
            sectionLabel.leftAnchor.constraint(equalTo: leftAnchor),
            sectionLabel.topAnchor.constraint(equalTo: topAnchor),
            sectionLabel.rightAnchor.constraint(equalTo: rightAnchor),
            sectionLabel.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        addSubview(datePicker)
        NSLayoutConstraint.activate([
            datePicker.leftAnchor.constraint(equalTo: leftAnchor),
            datePicker.rightAnchor.constraint(equalTo: rightAnchor),
            datePicker.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor),
            datePicker.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        addSubview(underLine)
        underLineColor()
        NSLayoutConstraint.activate([
            underLine.leftAnchor.constraint(equalTo: leftAnchor),
            underLine.rightAnchor.constraint(equalTo: rightAnchor),
            underLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            underLine.heightAnchor.constraint(equalToConstant: 1),
        ])
    }
    
    @objc private func didChangeDatePickerValue(_ sender: UIDatePicker) {
        self.listener()
    }
    
    private var listener: () -> Void = {}
    public func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
    
    func underLineColor() {
        underLine.backgroundColor = Brand.color(for: .text(.toggle))
    }
}

#if PREVIEW
import SwiftUI

struct DateInputView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ViewWrapper(view: {
                let dateInputView = DateInputView(section: "開演時間")
                return dateInputView
            }())
            .previewLayout(.fixed(width: 320, height: 60))
        }
        .background(Color.black)
    }
}
#endif
