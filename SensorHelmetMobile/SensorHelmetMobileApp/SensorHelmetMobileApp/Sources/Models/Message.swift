//
//  Message.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/27.
//

import Foundation
import MessageKit
import UIKit
import FirebaseFirestore
import Firebase
import FirebaseFirestoreSwift

// MARK: - FireStoreを通してやりとりするメッセージのModelを定義
// iPアドレスをhelmet numberの代わりにするのも考え中

// MARK: - 方法: ラズパイのipアドレスをfirestoreに先に保存してNumbering作業を行うとスムーズになる可能性
// helmet Numberに関してはまだ確実な実装方法を探り中
// helmet NumberもStringとして定義することにした -> enum caseのrawValueを一つのタイプにした方が処理が楽なため
//struct Message: MessageType {
//    let id: String?
//    var messageId: String {
//        return id ?? UUID().uuidString
//    }
//
//    let content: String
//    let sentDate: Date
//    let sender: SenderType
//    var kind: MessageKind {
//        if let image = image {
//            let mediaItem = MediaItemImage(image: image)
//        } else {
//            return .text(content)
//        }
//    }
//
//    var image: UIImage?
//    var downloadURL: URL?
//
//
//
//
//
//
//
//}
//struct Message: MessageType {
//
//    let id: String?
//    var messageId: String {
//        return id ?? UUID().uuidString
//    }
//    let content: String
//    let sentDate: Date
//    let sender: SenderType
//    var kind: MessageKind {
//        if let image = image {
//            let mediaItem = ImageMediaItem(image: image)
//            return .photo(mediaItem)
//        } else {
//            return .text(content)
//        }
//    }
//
//    var image: UIImage?
//    var downloadURL: URL?
//
//    init(user: User, content: String) {
//        sender = Sender(senderId: user.uid, displayName: UserDefaultManager.displayName)
//        self.content = content
//        sentDate = Date()
//        id = nil
//    }
//
//    init(user: User, image: UIImage) {
//        sender = Sender(senderId: user.uid, displayName: UserDefaultManager.displayName)
//        self.image = image
//        sentDate = Date()
//        content = ""
//        id = nil
//    }
//
//    init?(document: QueryDocumentSnapshot) {
//        let data = document.data()
//        guard let sentDate = data["created"] as? Timestamp,
//              let senderId = data["senderId"] as? String,
//              let senderName = data["senderName"] as? String else { return nil }
//        id = document.documentID
//        self.sentDate = sentDate.dateValue()
//        sender = Sender(senderId: senderId, displayName: senderName)
//
//        if let content = data["content"] as? String {
//            self.content = content
//            downloadURL = nil
//        } else if let urlString = data["url"] as? String, let url = URL(string: urlString) {
//            downloadURL = url
//            content = ""
//        } else {
//            return nil
//        }
//    }
//
//}


// MARK: - helmetNum: そのチャットルームが誰とのチャットであるかを区分するためのhelmetID
// MARK: - id:　そのチャットルームの中で 公共機関のMessageなのか、helmetユーザのmessageなのかを定義

//struct Message: MessageType {
//
//    let id: String?
//    var messageId: String {
//        return id ?? UUID().uuidString
//    }
//    let content: String
//    let sentDate: Date
//    let sender: SenderType
//    var kind: MessageKind {
//        if let image = image {
//            let mediaItem = MediaItemImage(image: image)
//            return .photo(mediaItem)
//        } else {
//            return .text(content)
//        }
//    }
//
//    var image: UIImage?
//    var downloadURL: URL?
//
//    init(user: User, content: String) {
//        sender = Sender(senderId: user.uid, displayName: UserDefaultManager.displayName)
//        self.content = content
//        sentDate = Date()
//        id = nil
//    }
//
//    init(user: User, image: UIImage) {
//        sender = Sender(senderId: user.uid, displayName: UserDefaultManager.displayName)
//        self.image = image
//        sentDate = Date()
//        content = ""
//        id = nil
//    }
//
//    init?(document: QueryDocumentSnapshot) {
//        let data = document.data()
//        guard let sentDate = data["created"] as? Timestamp,
//              let senderId = data["senderId"] as? String,
//              let senderName = data["senderName"] as? String else { return nil }
//        id = document.documentID
//        self.sentDate = sentDate.dateValue()
//        sender = Sender(senderId: senderId, displayName: senderName)
//
//        if let content = data["content"] as? String {
//            self.content = content
//            downloadURL = nil
//        } else if let urlString = data["url"] as? String, let url = URL(string: urlString) {
//            downloadURL = url
//            content = ""
//        } else {
//            return nil
//        }
//    }
//
//}

// MARK: - senderTypeをインスタンスで受け取ったら、MessageType protocolを継承することができた
struct Message: MessageType {
    // ヘルメットの番号
    // MARK: - 相手にヘルメット番号がない場合　-> 公共機関として処理を行いたい
    // userID: -> helmetかInstitutionか
    var userId: String?
    var userName: String?
    // messageのid -> UUIDのような
    let id: String?
    
    // MARK: - 今回はAuthenticationを導入しなかったからUserオブジェクトがない
    // MARK: - そのため、senderIdがhelmetNumberとなる
    // MARK: - messageIdとsenderIdは別のもの -> messageId: message一個一個を分類する識別子
    // messageID?
    // threadの中に入るやつ
    var messageId: String {
        // idがすでにない場合は、UUIDをmessageIdとして挿入
        return id ?? UUID().uuidString
    }
    
    // 内容は必ずあるってことを想定
    let content: String
    // 送信した日付
    let sentDate: Date
    let sender: SenderType
    var kind: MessageKind {
        if let image = image {
            let mediaItem = MediaItemImage(image: image)
            return .photo(mediaItem)
        } else {
            return .text(content)
        }
    }
    
    // ユーザのProfile画像（今回は、helmetの画像）
    var image: UIImage?
    // ユーザが送った画像ファイルなど
    var downloadURL: URL?
    
    // MARK: - Authenticationの設定をしなかったから、helmetNumberでUserの分岐をしたい
    // 現状だと、displayNameとuidは一緒
    // MARK: - 今後修正すること: 他のUserとのチャット, 公共機関のIdの実現
    
    // MARK: - テキストのメッセージ
    init(userId: String, userName: String, content: String) {
        sender = Sender(senderId: userId, displayName: userName)
        self.content = content
        self.sentDate = Date()
        id = nil
    }
    
    // MARK: - 画像を送るメッセージ
    init(userId: String, userName: String, image: UIImage) {
        sender = Sender(senderId: userId, displayName: userName)
        self.image = image
        sentDate = Date()
        content = ""
        id = nil
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
//        let dateFormatter = DateFormatter()
//        dateFormatter.locale = Locale(identifier: "ja_JP")
        
        guard let sentDate = data["created"] as? Timestamp,
              let senderId = data["userId"] as? String,
              let senderName = data["userName"] as? String else { return nil }
        
        id = document.documentID
        self.sentDate = sentDate.dateValue()
        sender = Sender(senderId: senderId, displayName: senderName)
        
        if let content = data["content"] as? String {
            self.content = content
            downloadURL = nil
        } else if let urlString = data["url"] as? String,
                  let url = URL(string: urlString) {
            downloadURL = url
            content = ""
        } else {
            return nil
        }
    }
}
    
    
//    // MARK: - Data型をFireStoreに保存したらUnix Time Stamp型に変換する作業
//    private enum CodingKeys: String, CodingKey {
//        case helmetNumber
//        case id
//        case content
//        case sentDate
//    }
//
//    init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        helmetNumber = try values.decode(String.self, forKey: .helmetNumber)
//        id = try values.decode(String.self, forKey: .id)
//        content = try values.decode(String.self, forKey: .content)
//
//        let dataDouble = try values.decode(Double.self, forKey: .sentDate)
//        sentDate = Date(timeIntervalSince1970: dataDouble)
//    }

extension Message: DatabaseRepresentation {
    var representation: [String : Any] {
        var representation: [String: Any] = [
            "created": sentDate,
            "userId": sender.senderId,
            "userName": sender.displayName
        ]
        
        // 画像ファイルがあれば
        if let url = downloadURL {
            representation["url"] = url.absoluteString
        } else {
            representation["content"] = content
        }
        
        return representation
    }
}


// Messageを比較可能のModelとして定義
extension Message: Comparable {
    // 同じ値があるかどうかを比較するときに使用
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }

    // sort間数で使用
    // メッセージの生成時刻準備UIを表示するため
    static func < (lhs: Message, rhs: Message) -> Bool {
        return lhs.sentDate < rhs.sentDate
    }
}

//import Foundation
//import MessageKit
//import UIKit
//import Firebase
//
//struct Message: MessageType {
//
//    let id: String?
//    var messageId: String {
//        return id ?? UUID().uuidString
//    }
//    let content: String
//    let sentDate: Date
//    let sender: SenderType
//    var kind: MessageKind {
//        if let image = image {
//            let mediaItem = ImageMediaItem(image: image)
//            return .photo(mediaItem)
//        } else {
//            return .text(content)
//        }
//    }
//
//    var image: UIImage?
//    var downloadURL: URL?
//
//    init(user: User, content: String) {
//        sender = Sender(senderId: user.uid, displayName: UserDefaultManager.displayName)
//        self.content = content
//        sentDate = Date()
//        id = nil
//    }
//
//    init(user: User, image: UIImage) {
//        sender = Sender(senderId: user.uid, displayName: UserDefaultManager.displayName)
//        self.image = image
//        sentDate = Date()
//        content = ""
//        id = nil
//    }
//
//    init?(document: QueryDocumentSnapshot) {
//        let data = document.data()
//        guard let sentDate = data["created"] as? Timestamp,
//              let senderId = data["senderId"] as? String,
//              let senderName = data["senderName"] as? String else { return nil }
//        id = document.documentID
//        self.sentDate = sentDate.dateValue()
//        sender = Sender(senderId: senderId, displayName: senderName)
//
//        if let content = data["content"] as? String {
//            self.content = content
//            downloadURL = nil
//        } else if let urlString = data["url"] as? String, let url = URL(string: urlString) {
//            downloadURL = url
//            content = ""
//        } else {
//            return nil
//        }
//    }
//
//}
//
//extension Message: DatabaseRepresentation {
//    var representation: [String : Any] {
//        var representation: [String: Any] = [
//            "created": sentDate,
//            "senderId": sender.senderId,
//            "senderName": sender.displayName
//        ]
//
//        if let url = downloadURL {
//            representation["url"] = url.absoluteString
//        } else {
//            representation["content"] = content
//        }
//
//        return representation
//    }
//}
//
//extension Message: Comparable {
//  static func == (lhs: Message, rhs: Message) -> Bool {
//    return lhs.id == rhs.id
//  }
//
//  static func < (lhs: Message, rhs: Message) -> Bool {
//    return lhs.sentDate < rhs.sentDate
//  }
//}
