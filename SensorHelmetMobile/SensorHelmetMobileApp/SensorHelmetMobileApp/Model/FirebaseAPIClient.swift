//
//  FirebaseAPIClient.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/02.
//

import Foundation

struct GoogleVisonAPIClient: GoogleVisonAPIClientProtocol {
    // typealiasの指定
//    typealias NetworkCompletion = (_ data: Data?, _ error: Error?) -> Void
    func send(base64String: String, completion: @escaping ((Data?, Error?) -> Void)) {
        // TODO: 課題2
        // ここでCloud Vision APIのリクエストを組み立て
        // URLSessionを使って通信をする
        // 通信が終わったらcompletionを呼ぶこと
        let request = buildRequest(with: base64String)
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }.resume()
    }
}

// requestをbuildするところは、extensionで作成した方がいいかも

private extension GoogleVisonAPIClient {
    func buildRequest(with base64String: String) -> URLRequest {
        // TODO: 課題2
        // ここでCloud Vision APIのリクエストを組み立て
        // URLSessionを使って通信をする
        // 通信が終わったらcompletionを呼ぶこと
        let googleApiKey = ""
        let url = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleApiKey)")!
        // 上記のsendのメソッドで DataTaskの completionを行うので、ここで再びif let bindingをする必要はない
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let params: [String: AnyObject] = [
            "requests": [
                "image": [
                    "content":base64String
                ],
                "features": [[
                    "type": "DOCUMENT_TEXT_DETECTION"
                ]]
            ] as AnyObject
        ]
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        return request
        
        // do catch 文を使うためには、throwsを使わないといけない
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
//            return request
//        } catch let e as NSError {
//            print("Error: \(e.localizedDescription)")
//        }
    }
}

protocol GoogleVisonAPIClientProtocol {
    func send(base64String: String, completion: @escaping ((Data?, Error?) -> Void))
}
