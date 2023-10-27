//
//  Message.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/27.
//

import Foundation
// MARK: - FireStoreを通してやりとりするメッセージのModelを定義
// iPアドレスをhelmet numberの代わりにするのも考え中

// MARK: - 方法: ラズパイのipアドレスをfirestoreに先に保存してNumbering作業を行うとスムーズになる可能性
// helmet Numberに関してはまだ確実な実装方法を探り中
struct Message: Codable {
    var helmetNumber: Int?
    var id: String?
    var content: String?
    var sentDate: Date
    
    init(helmetNumber: Int, id: String, content: String) {
        self.helmetNumber = helmetNumber
        self.id = id
        self.content = content
        self.sentDate = Date()
    }
    // MARK: - Data型をFireStoreに保存したらUnix Time Stamp型に変換する作業
    private enum CodingKeys: Int, String, CodingKey {
        case helmetNumber
        case id
        case content
        case sentDate
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        helmetNumber = try values.decode(Int.self, forKey: .helmetNumber)
        id = try values.decode(String.self, forKey: .id)
        content = try values.decode(String.self, forKey: .content)
        
        let dataDouble = try values.decode(Double.self, forKey: .sentDate)
        sentDate = Date(timeIntervalSince1970: dataDouble)
    }
}
