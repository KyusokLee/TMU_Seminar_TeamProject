//
//  CustomFirestore.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/27.
//

import Foundation
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift

// MARK: - もともとは、ラズパイのBluetoothの繋ぎでmessage Idを分岐したかった(helmet1, helmet2,...)
// MARK: - 時間が足りなかったため、ip毎に message Idを区別させようと思ったが、後回しいにする
final class CustomFirestore {
    
    // リアルタイムな変更を反映させるためのListener
    private var documentListener: ListenerRegistration?
    private let storage = Storage.storage().reference()
    
    // MARK: - 公共リストを持ってくる
    // MARK: - ここがチャットルームに入るまえのChannelを指す
    // Channel自体はDocumentへ変更がないことを想定してモデルを作成した
    // Channelへメッセージが来たとき、一番上のCellで表示するためDocumentChangesをパラメータとして定義
    func getInstitutionList(place: String, completion: @escaping (Result<[(PublicInstitution, DocumentChangeType)], Error>) -> Void) {
        // Listという名前のCollectionのリストを全部表示する
        let collectionPath = "PublicInstitutionList/Near\(place)/List"
        let collectionListener = Firestore.firestore().collection(collectionPath)
        
        collectionListener.getDocuments { snapshot, error in
            if let error = error {
                print("Debug: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot else {
                print("Debug: Firestore Snapshot Error, \(String(describing: error?.localizedDescription))")
                completion(.failure(error!))
                return
            }
            
//            let decoder = JSONDecoder()
//            var institutionDatas: [PublicInstitution] = []
            // MARK: - 最初のsnapShotであるなら、.added changesとしてリストに表示される
            let result = snapshot.documentChanges
                .filter { PublicInstitution($0.document) != nil }
                .compactMap { (PublicInstitution($0.document)!, $0.type) }
            
            completion(.success((result)))
            
//            // documentsのIDを全部持ってくる
//            for document in documents {
//                do {
//                    // Stringであることを確認
//                    print("DocumentのID: ", document.documentID)
//                    // 各Document（ここでは公共機関）のデータを持ってくる
//                    let data = document.data()
//                    let jsonData = try JSONSerialization.data(withJSONObject: data)
//                    let institutionData = try decoder.decode(PublicInstitution.self, from: jsonData)
//                    institutionDatas.append(institutionData)
//                } catch let error {
//                    print("error: \(error)")
//                }
//            }
            
//            let decoder = JSONDecoder()
//            completion(.success(institutionDatas))
        }
    }
    
    
    // MARK: - Messageをsaveする方法
    // fieldに自動に生成されるIDを元に, messageを保存する
    // fireStoreに保存する送ったメッセージを保存するメソッド
    // MARK: - message.idはhelmetのidってこと(例: helmet1, helmet2...)
    func save(_ place: String, _ institutionType: String, _ chatRoomId: String, _ message: Message, completion: ((Error?) -> Void)? = nil) {
        // MARK: - Messagesの後にチャットをしている対象のIDを入れるべき
        // MARK: - つまり、公共機関がメッセージが送る場合もHelmetユーザのIDを入れるべきである
        // MARK: - message.chatRoomNameみたいなのを入れるべき
        let collectionPath = "PublicInstitutionList/Near\(place)/List/\(institutionType)/Messages/\(chatRoomId)/thread"
        let collectionListener = Firestore.firestore().collection(collectionPath)
        
//        guard let dictionary = message.representation else {
//            print("decode error")
//            return
//        }
        let messageData = message.representation
        collectionListener.addDocument(data: messageData) { error in
            completion?(error)
        }
    }
    
    // MARK: Message
    // メッセージのデータをリアルタイムに持ってくる
    func subscribe(_ place: String, _ institutionType: String, chatRoomId: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        // id: helmetの番号
        // MARK: - FireStoreのMessages Collectionに公共機関のTypeも設定することにした
        // 理由: -> 公共機関自ら送るメッセージも設定したいため、(全てのユーザーへのメッセージ告知を実装したかった)
        // MARK: - ChatRoomId -> チャット相手
        // MARK: - 公共機関の場合もチャット相手(Helmet1, Helmet2)をChatRoomIdとして使う
        // MARK: - 送信者を分別するのはMessageのUserId
        let collectionPath = "PublicInstitutionList/Near\(place)/List/\(institutionType)/Messages/\(chatRoomId)/thread"
        // MARK: - threadの後のdocumentにuuidが入る
        // 順番的に表す
        removeListener()
        // channel(list)をlistenさせる
        let collectionListener = Firestore.firestore().collection(collectionPath)
        
        documentListener = collectionListener
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    completion(.failure(error!))
                    return
                }
                
                var messages = [Message]()
                snapshot.documentChanges.forEach { change in
                    if let message = Message(document: change.document) {
                        if case .added = change.type {
                            messages.append(message)
                        }
                    }
                }
                completion(.success(messages))
            }
    }
                    
//                    switch change.type {
//                    case .added:
//                        do {
//                            if let message = try change.document.data(as: Message?.self) {
//                                messages.append(message)
//                            }
//                        } catch {
//                            completion(.failure(error))
//                        }
//                    default: break
//                    }
//                }
//                completion(.success(messages))
//            }
    
    // ListenerのSubscribeを解除するメソッド
    func removeListener() {
        documentListener?.remove()
    }
}
