//
//  DatabaseRepresentation.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/11/25.
//

import Foundation

// Codableの代わりのProtocol
// MARK: - 理由: CodableとMessageTypeを組み合わせることができなかった
// MARK: - このProtocolを採択した構造体はFirestoreにjsonとしてデータを引き渡すことが容易である
// 各モデルでこのProtocolを採択することで、導入可能
protocol DatabaseRepresentation {
    var representation: [String: Any] { get }
}
