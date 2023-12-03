//
//  FirebaseStorageManager.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/11/29.
//

import Foundation
import FirebaseStorage
import UIKit

// MARK: - Storageのディレクトリ構成
// picturesまでは事前に指定した場合
// pictures/place/publicInstitutionのtype/chatRoomId/helmetNum(userIdのような識別)/imageName
// MARK: - 注意 -> PublicInstitution型をパラメータとして引き渡すのではなく、PublicInstitutionのTypeをString型としてパラメータで引き渡す

struct FirebaseStorageManager {
    static func uploadImage(image: UIImage, place: String, institutionType: String, chatRoomId: String, userId: String, completion: @escaping (URL?) -> Void) {
        guard let scaledImage = image.scaledToSafeUploadSize,
              let data = scaledImage.jpegData(compressionQuality: 0.4) else { return completion(nil) }
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        
        let imageName = UUID().uuidString + String(Date().timeIntervalSince1970)
        let collectionPath = "pictures/\(place)/\(institutionType)/\(chatRoomId)/\(String(describing: userId))/\(imageName)"
        // MARK: - FireStoreのDirectory構成と StorageのDirectory構成は異なるもの
        let imageReference = Storage.storage().reference().child(collectionPath)
        
        imageReference.putData(data, metadata: metaData) { _, _ in
            imageReference.downloadURL { url, _ in
                completion(url)
            }
        }
    }
       
    static func downloadImage(url: URL, completion: @escaping (UIImage?) -> Void) {
        let reference = Storage.storage().reference(forURL: url.absoluteString)
        // 高画質
        let megaByte = Int64(1 * 1024 * 1024)
           
        reference.getData(maxSize: megaByte) { data, error in
            guard let imageData = data else {
                completion(nil)
                return
            }
            completion(UIImage(data: imageData))
        }
    }
}
