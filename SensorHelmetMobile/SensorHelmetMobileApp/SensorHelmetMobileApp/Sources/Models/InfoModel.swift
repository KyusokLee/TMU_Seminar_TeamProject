//
//  tempInfo.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/03.
//

import Foundation

struct InfoModel: Codable {
    var helmetId: String?
    var date: String?
    var time: String?
    var temp: String?
    var humid: String?
    var longitude: String?
    var latitude: String?
    var ip: String?
    var COGasPPM: String?
    var shelterLongitude: String?
    var shelterLatitude: String?
    var practiceLogitude: String?
    var practiceLatitude: String?
    
//    init(
//        helmetId: String?,
//        date: String?,
//        time: String?,
//        temp: String?,
//        humid: String?,
//        longitude: String?,
//        latitude: String?,
//        ip: String?,
//        COGasDensity: String?,
//        shelterLongitude: String?,
//        shelterLatitude: String?,
//        practiceLogitude: String?,
//        practiceLatitude: String?
//    ) {
//        self.helmetId = helmetId
//        self.date = date
//        self.time = time
//        self.temp = temp
//        self.humid = humid
//        self.longitude = longitude
//        self.latitude = latitude
//        self.ip = ip
//        self.COGasDensity = COGasDensity
//        self.shelterLongitude = shelterLongitude
//        self.shelterLatitude = shelterLatitude
//        self.practiceLogitude = practiceLogitude
//        self.practiceLatitude = practiceLatitude
//    }
    
    private enum CodingKeys: String, CodingKey {
        case helmetId
        case date
        case time
        case temp
        case humid
        case longitude
        case latitude
        case ip
        case COGasPPM
        case shelterLongitude = "destinationLong"
        case shelterLatitude = "destinationLati"
        case practiceLogitude = "pracLongi"
        case practiceLatitude = "pracLati"
    }
    
//    // Decoding処理をModelを立てるときにやってしまう
//    init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        helmetId = try values.decode(String.self, forKey: .helmetId)
//        date = try values.decode(String.self, forKey: .date)
//        time = try values.decode(String.self, forKey: .time)
//        temp = try values.decode(String.self, forKey: .temp)
//        humid = try values.decode(String.self, forKey: .humid)
//        longitude = try values.decode(String.self, forKey: .longitude)
//        latitude = try values.decode(String.self, forKey: .latitude)
//        ip = try values.decode(String.self, forKey: .ip)
//        COGasDensity = try values.decode(String.self, forKey: .COGasDensity)
//        shelterLongitude = try values.decode(String.self, forKey: .shelterLongitude)
//        shelterLatitude = try values.decode(String.self, forKey: .shelterLatitude)
//        practiceLogitude = try values.decode(String.self, forKey: .practiceLogitude)
//        practiceLatitude = try values.decode(String.self, forKey: .practiceLatitude)
//    }
}
