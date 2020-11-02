//
//  SearchViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/29.
//

import UIKit

final class SearchViewController: UIViewController, Instantiable {
    typealias Input = Void
    var dependencyProvider: DependencyProvider!
    
    enum Choice {
        case live
        case band
    }
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter
    }()
    
    private var choice: Choice = .live
    private var prefectures = Components().prefectures
    private var prefecturePicker: UIPickerView!
    private var prefectureTextFieldView: TextFieldView!
    private var dateTextFieldView: TextFieldView!
    private var bandSettingView: UIView!
    private var liveSettingView: UIView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var liveChoiceView: UIView!
    @IBOutlet weak var bandChoiceView: UIView!
    @IBOutlet weak var settingView: UIView!
    
    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        self.view.backgroundColor = style.color.background.get()
        
        prefecturePicker = UIPickerView()
        prefecturePicker.translatesAutoresizingMaskIntoConstraints = false
        prefecturePicker.dataSource = self
        prefecturePicker.delegate = self
        
        searchBar.delegate = self
        searchBar.barTintColor = style.color.background.get()
        searchBar.searchTextField.placeholder = "バンド・ライブを探す"
        searchBar.searchTextField.textColor = style.color.main.get()
        searchBar.showsSearchResultsButton = false
        
        let liveImageView = UIImageView()
        liveImageView.translatesAutoresizingMaskIntoConstraints = false
        liveImageView.image = UIImage(named: "selectedGuitarIcon")
        liveChoiceView.addSubview(liveImageView)
        
        let liveTextLabel = UILabel()
        liveTextLabel.translatesAutoresizingMaskIntoConstraints = false
        liveTextLabel.text = "ライブ"
        liveTextLabel.font = style.font.regular.get()
        liveTextLabel.textColor = style.color.main.get()
        liveChoiceView.addSubview(liveTextLabel)
        
        let liveChoiceButton = UIButton()
        liveChoiceButton.translatesAutoresizingMaskIntoConstraints = false
        liveChoiceButton.backgroundColor = .clear
        liveChoiceButton.addTarget(self, action: #selector(liveChoiceButtonTapped(_:)), for: .touchUpInside)
        liveChoiceView.addSubview(liveChoiceButton)
        
        let bandImageView = UIImageView()
        bandImageView.translatesAutoresizingMaskIntoConstraints = false
        bandImageView.image = UIImage(named: "selectedMusicIcon")
        bandChoiceView.addSubview(bandImageView)
        
        let bandTextLabel = UILabel()
        bandTextLabel.translatesAutoresizingMaskIntoConstraints = false
        bandTextLabel.text = "バンド"
        bandTextLabel.font = style.font.regular.get()
        bandTextLabel.textColor = style.color.main.get()
        bandChoiceView.addSubview(bandTextLabel)
        
        let bandChoiceButton = UIButton()
        bandChoiceButton.translatesAutoresizingMaskIntoConstraints = false
        bandChoiceButton.backgroundColor = .clear
        bandChoiceButton.addTarget(self, action: #selector(bandChoiceButtonTapped(_:)), for: .touchUpInside)
        bandChoiceView.addSubview(bandChoiceButton)
        
        bandSettingView = UIView()
        bandSettingView.backgroundColor = style.color.background.get()
        bandSettingView.translatesAutoresizingMaskIntoConstraints = false
        settingView.addSubview(bandSettingView)
        
        let hometownView = UIView()
        hometownView.translatesAutoresizingMaskIntoConstraints = false
        bandSettingView.addSubview(hometownView)
        
        let mapImageView = UIImageView()
        mapImageView.translatesAutoresizingMaskIntoConstraints = false
        mapImageView.image = UIImage(named: "map")
        hometownView.addSubview(mapImageView)
        
        prefectureTextFieldView = TextFieldView(input: "出身地")
        prefectureTextFieldView.selectInputView(inputView: prefecturePicker)
        prefectureTextFieldView.translatesAutoresizingMaskIntoConstraints = false
        prefectureTextFieldView.backgroundColor = .clear
        hometownView.addSubview(prefectureTextFieldView)
        
        liveSettingView = UIView()
        liveSettingView.backgroundColor = style.color.background.get()
        liveSettingView.translatesAutoresizingMaskIntoConstraints = false
        settingView.addSubview(liveSettingView)
        
        let calendarView = UIView()
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        liveSettingView.addSubview(calendarView)
        
        let calendarImageView = UIImageView()
        calendarImageView.translatesAutoresizingMaskIntoConstraints = false
        calendarImageView.image = UIImage(named: "calendar")
        calendarView.addSubview(calendarImageView)
        
//        dateTextFieldView = TextFieldView(input: dateFormatter.string(from: Date()))
//        dateTextFieldView.translatesAutoresizingMaskIntoConstraints = false
//        calendarView.addSubview(dateTextFieldView)
        
        let datePicker = UIDatePicker()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.date = Date()
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        datePicker.tintColor = style.color.main.get()
        datePicker.backgroundColor = .clear
//        datePicker.tintColor = style.color.main.get()
//        datePicker.backgroundColor = style.color.background.get()
//        dateTextFieldView.selectInputView(inputView: datePicker)
        
        calendarView.addSubview(datePicker)
        
        toggleSetting()
        
        let constraints = [
            liveImageView.widthAnchor.constraint(equalToConstant: 40),
            liveImageView.heightAnchor.constraint(equalToConstant: 40),
            liveImageView.centerXAnchor.constraint(equalTo: liveChoiceView.centerXAnchor),
            liveImageView.topAnchor.constraint(equalTo: liveChoiceView.topAnchor, constant: 32),
            
            liveTextLabel.topAnchor.constraint(equalTo: liveImageView.bottomAnchor, constant: 4),
            liveTextLabel.centerXAnchor.constraint(equalTo: liveImageView.centerXAnchor),
            
            liveChoiceButton.topAnchor.constraint(equalTo: liveChoiceView.topAnchor),
            liveChoiceButton.bottomAnchor.constraint(equalTo: liveChoiceView.bottomAnchor),
            liveChoiceButton.rightAnchor.constraint(equalTo: liveChoiceView.rightAnchor),
            liveChoiceButton.leftAnchor.constraint(equalTo: liveChoiceView.leftAnchor),
            
            bandImageView.widthAnchor.constraint(equalToConstant: 40),
            bandImageView.heightAnchor.constraint(equalToConstant: 40),
            bandImageView.centerXAnchor.constraint(equalTo: bandChoiceView.centerXAnchor),
            bandImageView.topAnchor.constraint(equalTo: bandChoiceView.topAnchor, constant: 32),
            
            bandTextLabel.topAnchor.constraint(equalTo: bandImageView.bottomAnchor, constant: 4),
            bandTextLabel.centerXAnchor.constraint(equalTo: bandImageView.centerXAnchor),
            
            bandChoiceButton.topAnchor.constraint(equalTo: bandChoiceView.topAnchor),
            bandChoiceButton.bottomAnchor.constraint(equalTo: bandChoiceView.bottomAnchor),
            bandChoiceButton.rightAnchor.constraint(equalTo: bandChoiceView.rightAnchor),
            bandChoiceButton.leftAnchor.constraint(equalTo: bandChoiceView.leftAnchor),
            
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

            prefectureTextFieldView.leftAnchor.constraint(equalTo: mapImageView.rightAnchor, constant: 16),
            prefectureTextFieldView.rightAnchor.constraint(equalTo: hometownView.rightAnchor, constant: -16),
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
            bandChoiceView.layer.borderWidth = 0
            liveChoiceView.layer.borderWidth = 1
            liveChoiceView.layer.borderColor = style.color.main.get().cgColor
            settingView.bringSubviewToFront(liveSettingView)
        case .band:
            liveChoiceView.layer.borderWidth = 0
            bandChoiceView.layer.borderWidth = 1
            bandChoiceView.layer.borderColor = style.color.main.get().cgColor
            settingView.bringSubviewToFront(bandSettingView)
        }
    }
    
    @objc private func liveChoiceButtonTapped(_ sender: Any) {
        toggleSetting(.live)
    }
    
    @objc private func bandChoiceButtonTapped(_ sender: Any) {
        toggleSetting(.band)
    }
    
    @objc private func datePickerValueChanged(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension SearchViewController: UISearchBarDelegate {
    
}

extension SearchViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return prefectures.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return prefectures[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        prefectureTextFieldView.setText(text: prefectures[row])
    }
}
