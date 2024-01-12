//
//  UICollectionViewCell+Utils.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2024/01/08.
//

import Foundation
import UIKit

extension UICollectionView {
    // CollectionViewにデータがない時、Labelを表示するためのView
    func setEmptyMessage(_ message: String) {
        let messageLabel: UILabel = {
            let label = UILabel()
            label.text = message
            label.textColor = .white
            label.numberOfLines = 0;
            label.textAlignment = .center;
            label.font = .systemFont(ofSize: 15, weight: .medium)
            label.sizeToFit()
            return label
        }()
        self.backgroundView = messageLabel;
    }
    // CollectionViewにデータがあるときは、backgroundViewで設定しておいたLabelをnilに変える処理をする
    func restore() {
        self.backgroundView = nil
    }
}
