//
//  PreviewWrapper.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import SwiftUI

protocol InputAppliable {
    associatedtype Input
    func inject(input: Input)
}

struct ViewWrapper<View>: UIViewRepresentable where View: UIView {
    typealias UIViewType = View

    private let view: View
    init(view: View) {
        self.view = view
    }

    func makeUIView(context: Context) -> View {
        view
    }

    func updateUIView(_ uiView: View, context: Context) {}
}
