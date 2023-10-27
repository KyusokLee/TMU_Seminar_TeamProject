//
//  DisasterModel.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/29.
//

import Foundation
// MARK: - 災害が起きることを想定して、hard codingで任意のデータをlocal notificationしたい
struct DisasterModel: Codable {
    var disasterType: String?
    var addressInfo: AddressInfo?
    var time: String?
    var description: String?
    var disasterLongitude: String?
    var disasterLatitude: String?
    var image: String?
}

struct AddressInfo: Codable {
    var city: String?
    var localName: String?
    var localNameEnglish: String?
}
