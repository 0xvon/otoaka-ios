//
//  DetailFilterViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/11.
//

import UIKit
import Endpoint
import InternalDomain

final class DetailFilterViewController: UIViewController, Instantiable {
    typealias Input = Choice
    var dependencyProvider: LoggedInDependencyProvider!

    enum Choice {
        case live
        case band
    }

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter
    }()

    var choice: Choice
    let socialInputs: SocialInputs
    private var prefecturePicker: UIPickerView!
    private var prefectureTextFieldView: TextFieldView!
    private var dateTextFieldView: TextFieldView!
    private var bandSettingView: UIView!
    private var liveSettingView: UIView!
    private var verticalScrollView: UIScrollView!
    private var settingView: UIView!
    private var postButton: UIButton!

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.choice = input
        self.socialInputs = try! dependencyProvider.masterService.blockingMasterData()

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        
        verticalScrollView = UIScrollView()
        verticalScrollView.translatesAutoresizingMaskIntoConstraints = false
        verticalScrollView.backgroundColor = .clear
        self.view.addSubview(verticalScrollView)
        
        settingView = UIView()
        settingView.translatesAutoresizingMaskIntoConstraints = false
        settingView.backgroundColor = Brand.color(for: .background(.primary))
        verticalScrollView.addSubview(settingView)

        prefecturePicker = UIPickerView()
        prefecturePicker.translatesAutoresizingMaskIntoConstraints = false
        prefecturePicker.dataSource = self
        prefecturePicker.delegate = self

        bandSettingView = UIView()
        bandSettingView.backgroundColor = Brand.color(for: .background(.primary))
        bandSettingView.translatesAutoresizingMaskIntoConstraints = false
        settingView.addSubview(bandSettingView)

        let hometownView = UIView()
        hometownView.translatesAutoresizingMaskIntoConstraints = false
        bandSettingView.addSubview(hometownView)

        let mapImageView = UIImageView()
        mapImageView.translatesAutoresizingMaskIntoConstraints = false
        mapImageView.image = UIImage(named: "map")
        hometownView.addSubview(mapImageView)

        prefectureTextFieldView = TextFieldView(input: (section: "出身地", text: nil, maxLength: 20))
        prefectureTextFieldView.selectInputView(inputView: prefecturePicker)
        prefectureTextFieldView.translatesAutoresizingMaskIntoConstraints = false
        prefectureTextFieldView.backgroundColor = .clear
        hometownView.addSubview(prefectureTextFieldView)

        liveSettingView = UIView()
        liveSettingView.backgroundColor = Brand.color(for: .background(.primary))
        liveSettingView.translatesAutoresizingMaskIntoConstraints = false
        settingView.addSubview(liveSettingView)

        let calendarView = UIView()
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        liveSettingView.addSubview(calendarView)

        let calendarImageView = UIImageView()
        calendarImageView.translatesAutoresizingMaskIntoConstraints = false
        calendarImageView.image = UIImage(named: "calendar")
        calendarView.addSubview(calendarImageView)

        let datePicker = UIDatePicker()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.date = Date()
        datePicker.datePickerMode = .date
        datePicker.addTarget(
            self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        datePicker.tintColor = Brand.color(for: .text(.primary))
        datePicker.backgroundColor = .clear

        calendarView.addSubview(datePicker)

        toggleSetting()
        
        postButton = UIButton()
        postButton.translatesAutoresizingMaskIntoConstraints = false
        postButton.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        postButton.setTitle("OK", for: .normal)
        postButton.addTarget(self, action: #selector(post(_:)), for: .touchUpInside)
        postButton.titleLabel?.font = Brand.font(for: .largeStrong)

        let constraints = [
            verticalScrollView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            verticalScrollView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
            verticalScrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            verticalScrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            verticalScrollView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            settingView.topAnchor.constraint(equalTo: verticalScrollView.topAnchor),
            settingView.rightAnchor.constraint(equalTo: verticalScrollView.rightAnchor),
            settingView.leftAnchor.constraint(equalTo: verticalScrollView.leftAnchor),
            settingView.bottomAnchor.constraint(equalTo: verticalScrollView.bottomAnchor),
            settingView.centerXAnchor.constraint(equalTo: verticalScrollView.centerXAnchor),
            settingView.heightAnchor.constraint(equalToConstant: 900),
            
            bandSettingView.leftAnchor.constraint(equalTo: settingView.leftAnchor),
            bandSettingView.rightAnchor.constraint(equalTo: settingView.rightAnchor),
            bandSettingView.topAnchor.constraint(equalTo: settingView.topAnchor),
            bandSettingView.bottomAnchor.constraint(equalTo: settingView.bottomAnchor),

            calendarImageView.widthAnchor.constraint(equalToConstant: 30),
            calendarImageView.heightAnchor.constraint(equalToConstant: 30),
            calendarImageView.centerYAnchor.constraint(equalTo: calendarView.centerYAnchor),
            calendarImageView.leftAnchor.constraint(equalTo: calendarView.leftAnchor, constant: 16),

            datePicker.leftAnchor.constraint(equalTo: calendarImageView.rightAnchor, constant: 16),
            datePicker.rightAnchor.constraint(equalTo: calendarView.rightAnchor, constant: -16),
            datePicker.centerYAnchor.constraint(equalTo: calendarView.centerYAnchor),

            calendarView.leftAnchor.constraint(equalTo: liveSettingView.leftAnchor),
            calendarView.rightAnchor.constraint(equalTo: liveSettingView.rightAnchor),
            calendarView.topAnchor.constraint(equalTo: liveSettingView.topAnchor),
            calendarView.heightAnchor.constraint(equalToConstant: 60),

            mapImageView.widthAnchor.constraint(equalToConstant: 30),
            mapImageView.heightAnchor.constraint(equalToConstant: 30),
            mapImageView.centerYAnchor.constraint(equalTo: hometownView.centerYAnchor),
            mapImageView.leftAnchor.constraint(equalTo: hometownView.leftAnchor, constant: 16),

            prefectureTextFieldView.leftAnchor.constraint(
                equalTo: mapImageView.rightAnchor, constant: 16),
            prefectureTextFieldView.rightAnchor.constraint(
                equalTo: hometownView.rightAnchor, constant: -16),
            prefectureTextFieldView.centerYAnchor.constraint(equalTo: hometownView.centerYAnchor),
            prefectureTextFieldView.heightAnchor.constraint(equalToConstant: 30),

            hometownView.leftAnchor.constraint(equalTo: bandSettingView.leftAnchor),
            hometownView.rightAnchor.constraint(equalTo: bandSettingView.rightAnchor),
            hometownView.topAnchor.constraint(equalTo: bandSettingView.topAnchor),
            hometownView.heightAnchor.constraint(equalToConstant: 60),

            liveSettingView.leftAnchor.constraint(equalTo: settingView.leftAnchor),
            liveSettingView.rightAnchor.constraint(equalTo: settingView.rightAnchor),
            liveSettingView.topAnchor.constraint(equalTo: settingView.topAnchor),
            liveSettingView.bottomAnchor.constraint(equalTo: settingView.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    private func toggleSetting(_ choice: Choice = .live) {
        self.choice = choice

        switch self.choice {
        case .live:
            settingView.bringSubviewToFront(liveSettingView)
        case .band:
            settingView.bringSubviewToFront(bandSettingView)
        }
    }
    
    @objc private func datePickerValueChanged(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func post(_ sender: Any) {
        print("filter")
    }
}

extension DetailFilterViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return socialInputs.prefectures.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
        -> String?
    {
        return socialInputs.prefectures[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        prefectureTextFieldView.setText(text: socialInputs.prefectures[row])
    }
}
