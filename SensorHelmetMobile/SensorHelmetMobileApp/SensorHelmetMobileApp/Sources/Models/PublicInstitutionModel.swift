//
//  PublicInstitutionModel.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/26.
//

import Foundation

// MARK: - 災害が起きることを想定して、hard codingで任意のデータをlocal notificationしたい
struct PublicInstitution: Codable {
    var type: PublicInstitutionType
    var name: String?
    var image: String?
}

enum PublicInstitutionType: String, CaseIterable, Codable {
    case Government, FireStation, PoliceOffice, Hospital
}
