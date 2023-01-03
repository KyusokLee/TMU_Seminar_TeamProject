//
//  ViewController.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2022/12/12.
//

import UIKit
import FirebaseFirestore

// Firebaseのデータを読む
// Raspiの遠隔操作ができるように


class ViewController: UIViewController {
    
    @IBOutlet weak var readDataButton: UIButton! {
        didSet {
            readDataButton.setTitle("FireStoreからデータを読み込む", for: .normal)
        }
    }
    
    @IBOutlet weak var tempDataLabel: UILabel! {
        didSet {
            tempDataLabel.isHidden = true
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func getDataAction(_ sender: Any) {
        getData()
    }
    
    func getData() {
        Firestore.firestore().collection("Raspi").getDocuments { snapshot, error in
            if let error = error {
                print("Debug: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            var tempInfos: [tempInfoModel] = []
            let decoder = JSONDecoder()
            
            // Raspiで測定して、Firestoreに格納した温度のデータを読み込む
            for document in documents {
                do {
                    let data = document.data()
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let tempInfo = try decoder.decode(tempInfoModel.self, from: jsonData)
                    tempInfos.append(tempInfo)
                    self.tempDataLabel.text = "Temp: " + tempInfo.temp!
                    self.tempDataLabel.isHidden = false
                    
                } catch let error {
                    print("error: \(error)")
                }
            }
            
            
        }
    }
}

