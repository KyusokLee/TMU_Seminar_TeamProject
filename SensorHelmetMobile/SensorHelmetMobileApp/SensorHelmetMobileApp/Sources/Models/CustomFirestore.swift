//
//  CustomFirestore.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/27.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

final class CustomFirestore {
    
    // リアルタイムな変更を反映させるためのListener
    private var documentListener: ListenerRegistration?
    
    // MARK: - 公共リストを持ってくる
    // MARK: - ここがチャットルームに入るまえのChannelを指す
    func getInstitutionList(place: String, completion: @escaping (Result<[PublicInstitution], Error>) -> Void) {
        // Listという名前のCollectionのリストを全部表示する
        let collectionPath = "PublicInstitutionList/Near\(place)/List"
        let collectionListener = Firestore.firestore().collection(collectionPath)
        
        collectionListener.getDocuments { snapshot, error in
            if let error = error {
                print("Debug: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                return
            }
            
            let decoder = JSONDecoder()
            var institutionDatas: [PublicInstitution] = []
            
            // documentsのIDを全部持ってくる
            for document in documents {
                do {
                    // Stringであることを確認
                    print("DocumentのID: ", document.documentID)
                    // 各Document（ここでは公共機関）のデータを持ってくる
                    let data = document.data()
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let institutionData = try decoder.decode(PublicInstitution.self, from: jsonData)
                    institutionDatas.append(institutionData)
                } catch let error {
                    print("error: \(error)")
                }
            }
            
//            let decoder = JSONDecoder()
            completion(.success(institutionDatas))
        }
    }
    
    
    // MARK: - Messageをsaveする方法
    // fieldに自動に生成されるIDを元に, messageを保存する
    // fireStoreに保存する送ったメッセージを保存するメソッド
    // MARK: - message.idはhelmetのidってこと(例: helmet1, helmet2...)
    func save(_ place: String, _ institutionType: String, _ institutionName: String, _ message: Message, completion: ((Error?) -> Void)? = nil) {
        let collectionPath = "PublicInstitutionList/Near\(place)/List/\(institutionType)/Messages/\(String(describing: message.id))/thread"
        let collectionListener = Firestore.firestore().collection(collectionPath)
        
        guard let dictionary = message.asDictionary else {
            print("decode error")
            return
        }
        
        collectionListener.addDocument(data: dictionary) { error in
            completion?(error)
        }
    }
    
    // メッセージのデータをリアルタイムに持ってくる
    func subscribe(_ place: String, _ institutionType: String, _ institutionName: String, id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        let collectionPath = "PublicInstitutionList/Near\(place)/List/\(institutionType)/Messages/\(id)/thread"
        // MARK: - threadの後のdocumentにuuidが入る
        // 順番的に表す
        removeListener()
        let collectionListener = Firestore.firestore().collection(collectionPath)
        
        documentListener = collectionListener
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    completion(.failure(error!))
                    return
                }
                
                var messages = [Message]()
                snapshot.documentChanges.forEach { change in
                    switch change.type {
                    case .added, .modified:
                        do {
                            if let message = try change.document.data(as: Message?.self) {
                                messages.append(message)
                            }
                        } catch {
                            completion(.failure(error))
                        }
                    default: break
                    }
                }
                completion(.success(messages))
            }
    }
    
    // ListenerのSubscribeを解除するメソッド
    func removeListener() {
        documentListener?.remove()
    }
}
