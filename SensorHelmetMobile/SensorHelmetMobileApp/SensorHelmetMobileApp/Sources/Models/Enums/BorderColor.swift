//
//  BorderColor.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/28.
//

import Foundation
import UIKit

//MARK: - 時間がたつにつれ、borderColorが周りながら、色を変更するようにしたい

enum BorderColor {
    static var gradientColors = [
        UIColor.systemBlue,
        UIColor.systemBlue.withAlphaComponent(0.7),
        UIColor.systemBlue.withAlphaComponent(0.4),
        UIColor.systemGreen.withAlphaComponent(0.3),
        UIColor.systemGreen.withAlphaComponent(0.7),
        UIColor.systemGreen.withAlphaComponent(0.3),
        UIColor.systemBlue.withAlphaComponent(0.4),
        UIColor.systemBlue.withAlphaComponent(0.7)
    ]
}

// NSNumber -> scalar numeric valueに変える
enum GradientConstants {
    static let gradientLocation = [Int](0..<BorderColor.gradientColors.count)
        .map { NSNumber(value: Double($0)) }

    static let cornerRadius = 8.0
    static let cornerWidth = 4.0
    //static let viewSize = CGSize(width: 100, height: 350)
}
