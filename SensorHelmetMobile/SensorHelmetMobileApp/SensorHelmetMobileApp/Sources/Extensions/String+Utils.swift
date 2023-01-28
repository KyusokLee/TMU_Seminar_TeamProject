//
//  StringExtension.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/04.
//

import Foundation

extension String {
    func stringFromDate() -> String {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = self
        dateFormatter.locale = Locale(identifier: "ja_JP")
        return dateFormatter.string(from: now)
    }
}
