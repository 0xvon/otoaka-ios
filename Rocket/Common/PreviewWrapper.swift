//
//  PreviewWrapper.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import SwiftUI

struct ViewControllerWrapper<ViewController>: UIViewControllerRepresentable
where ViewController: Instantiable, ViewController: UIViewController {
    let dependencyProvider: ViewController.Provider
    let input: ViewController.Input

    func makeUIViewController(context: Context) -> ViewController {
        ViewController(dependencyProvider: dependencyProvider, input: input)
    }
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        
    }
}

protocol InputAppliable {
    associatedtype Input
    func inject(input: Input)
}

struct ViewWrapper<View>: UIViewRepresentable
where View: UIView, View: InputAppliable {
    typealias UIViewType = View
    let input: View.Input
    
    init(input: View.Input) {
        self.input = input
    }
    
    func makeUIView(context: Context) -> View {
        View()
    }
    
    func updateUIView(_ uiView: View, context: Context) {
        uiView.inject(input: input)
    }
}

struct TableCellWrapper<View>: UIViewRepresentable
where View: ReusableCell, View: UITableViewCell {
    typealias UIViewType = View
    
    let input: View.Input
    
    func makeUIView(context: Context) -> View {
        View(style: .default, reuseIdentifier: View.reusableIdentifier)
    }
    
    func updateUIView(_ cell: View, context: Context) {
        cell.inject(input: input)
    }
}
