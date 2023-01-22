//
//  tempInfo.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/03.
//

import Foundation

struct InfoModel: Codable {
    var date: String?
    var time: String?
    var temp: String?
    var humid: String?
    var longitude: String?
    var latitude: String?
    var ip: String?
    var shelterLongitude: String?
    var shelterLatitude: String?
    var practiceLogitude: String?
    var practiceLatitude: String?
    
    enum CodingKeys: String, CodingKey {
        case date
        case time
        case temp
        case humid
        case longitude
        case latitude
        case ip
        case shelterLongitude = "destinationLong"
        case shelterLatitude = "destinationLati"
        case practiceLogitude = "pracLongi"
        case practiceLatitude = "pracLati"
    }
}
