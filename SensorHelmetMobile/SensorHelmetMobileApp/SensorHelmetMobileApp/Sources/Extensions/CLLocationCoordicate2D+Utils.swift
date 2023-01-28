//
//  CLLocationCoordicate2D+Utils.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/19.
//

import UIKit
import CoreLocation

extension CLLocationCoordinate2D {
    func distance(to targetLocation: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: targetLocation.latitude, longitude: targetLocation.longitude)
        
        return from.distance(from: to)
    }
    
    func distanceText(to targetLocation: CLLocationCoordinate2D) -> String {
        let rawDistance = distance(to: targetLocation)
        // 1km未満は四捨五入で10m単位
        if rawDistance < 1000 {
            let roundedDistance = (rawDistance / 10).rounded() * 10
            return "目的地までの距離: \(Int(roundedDistance))m"
        }
        // 1km以上は四捨五入で0.1km単位
        let roundedDistance = (rawDistance / 100).rounded() * 100
        return "目的地までの距離: \(roundedDistance / 1000)km"
    }
}
