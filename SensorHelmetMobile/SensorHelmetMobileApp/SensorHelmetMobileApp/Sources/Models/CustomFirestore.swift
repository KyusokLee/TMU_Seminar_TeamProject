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
    
    // MARK: - Messageをsaveする方法
    // fieldに自動に生成されるIDを元に, messageを保存する
    // fireStoreに保存する送ったメッセージを保存するメソッド
    func save(_ place: String, _ institutionType: String, _ institutionName: String, _ message: Message, completion: ((Error?) -> Void)? = nil) {
        let collectionPath = "PublicInstitutionList/\(message.id)/thread"
        let collectionListener = Firestore.firestore().collection(collectionPath)
        
        guard let dictionary = message.asDictionary else {
            print("decode error")
            return
        }
        collectionListener.addDocument(data: dictionary) { error in
            completion?(error)
        }
    }

    func subscribe(id: String, completion: @escaping (Result<[Message], FirestoreError>) -> Void) {
        let collectionPath = "channels/\(id)/thread"
        removeListener()
        let collectionListener = Firestore.firestore().collection(collectionPath)
        
        documentListener = collectionListener
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    completion(.failure(FirestoreError.firestoreError(error)))
                    return
                }
                
                var messages = [Message]()
                snapshot.documentChanges.forEach { change in
                    switch change.type {
                    case .added, .modified:
                        do {
                            if let message = try change.document.data(as: Message.self) {
                                messages.append(message)
                            }
                        } catch {
                            completion(.failure(.decodedError(error)))
                        }
                    default: break
                    }
                }
                completion(.success(messages))
            }
    }
    
    func removeListener() {
        documentListener?.remove()
    }
}
