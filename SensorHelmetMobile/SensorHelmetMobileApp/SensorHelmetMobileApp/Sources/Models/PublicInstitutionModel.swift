//
//  PublicInstitutionModel.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/26.
//

import Foundation
import FirebaseFirestore

// MARK: - 災害が起きることを想定して、hard codingで任意のデータをlocal notificationしたい
// Codable
//struct PublicInstitution: Codable {
//    var type: String?
//    var name: String?
//}

struct PublicInstitution {
    // MARK: - Typeがあるばら、nameは絶対あると想定した
    var type: String?
    let name: String
    
    init(type: String?, name: String) {
        self.type = type
        self.name = name
    }
    
    
    init?(_ document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let type = data["type"] as? String,
              let name = data["name"] as? String else { return nil }
        
        self.type = type
        self.name = name
    }
}

extension PublicInstitution: DatabaseRepresentation {
    var representation: [String : Any] {
        var institution = [String: Any]()
        
        if let type = type {
            institution["type"] = type
            institution["name"] = name
        }
        
        return institution
    }
}

// データベースのデータ更新に伴うリスト更新(ソートなど)を行うためのComparable
extension PublicInstitution: Comparable {
    static func == (lhs: PublicInstitution, rhs: PublicInstitution) -> Bool {
        return lhs.type == rhs.type
    }
    
    static func < (lhs: PublicInstitution, rhs: PublicInstitution) -> Bool {
        return lhs.name < rhs.name
    }
}
