//
//  Stack.swift
//  Unsplash App
//
//  Created by Arman Galstyan on 30.05.24.
//

import Foundation
import UIKit

func vStack(spacing: CGFloat = 0.0, alignment: UIStackView.Alignment = .fill, distribution: UIStackView.Distribution = .fill, views: [UIView]) -> UIStackView {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.spacing = spacing
    stackView.alignment = alignment
    stackView.distribution = distribution
    stackView.translatesAutoresizingMaskIntoConstraints = false
    views.forEach {
        stackView.addArrangedSubview($0)
    }
    return stackView
}

func hStack(spacing: CGFloat = 0.0, alignment: UIStackView.Alignment = .fill, distribution: UIStackView.Distribution = .fill, views: [UIView]) -> UIStackView {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.spacing = spacing
    stackView.alignment = alignment
    stackView.distribution = distribution
    stackView.translatesAutoresizingMaskIntoConstraints = false
    views.forEach {
        stackView.addArrangedSubview($0)
    }
    return stackView
}
