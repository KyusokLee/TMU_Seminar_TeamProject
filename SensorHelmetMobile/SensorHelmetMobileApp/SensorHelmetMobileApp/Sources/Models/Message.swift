//
//  Message.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/27.
//

import Foundation
import MessageKit
// MARK: - FireStoreを通してやりとりするメッセージのModelを定義
// iPアドレスをhelmet numberの代わりにするのも考え中

// MARK: - 方法: ラズパイのipアドレスをfirestoreに先に保存してNumbering作業を行うとスムーズになる可能性
// helmet Numberに関してはまだ確実な実装方法を探り中
// helmet NumberもStringとして定義することにした -> enum caseのrawValueを一つのタイプにした方が処理が楽なため
struct Message: MessageType {
    let id: String?
    var messageId: String {
        return id ?? UUID().uuidString
    }
    
    let content: String
    let sentDate: Date
    let sender: SenderType
    var kind: MessageKind {
        if let image = image {
            let mediaItem = MediaItemImage(image: image)
        } else {
            return .text(content)
        }
    }
    
    var image: UIImage?
    var downloadURL: URL?
    
    
    
    
    
    
    
}

extension Message: Codable {
    var helmetNumber: String?
    var id: String?
    var content: String?
    var sentDate: Date
    
    init(helmetNumber: String, id: String, content: String) {
        self.helmetNumber = helmetNumber
        self.id = id
        self.content = content
        self.sentDate = Date()
    }
    // MARK: - Data型をFireStoreに保存したらUnix Time Stamp型に変換する作業
    private enum CodingKeys: String, CodingKey {
        case helmetNumber
        case id
        case content
        case sentDate
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        helmetNumber = try values.decode(String.self, forKey: .helmetNumber)
        id = try values.decode(String.self, forKey: .id)
        content = try values.decode(String.self, forKey: .content)
        
        let dataDouble = try values.decode(Double.self, forKey: .sentDate)
        sentDate = Date(timeIntervalSince1970: dataDouble)
    }
}

// Messageを比較可能のModelとして定義
extension Message: Comparable {
    // 同じ値があるかどうかを比較するときに使用
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }

    // sort間数で使用
    static func < (lhs: Message, rhs: Message) -> Bool {
        return lhs.sentDate < rhs.sentDate
    }
}
