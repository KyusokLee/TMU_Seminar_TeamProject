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
    
    @IBOutlet weak var presentMapButton: UIButton! {
        didSet {
            presentMapButton.setTitle("Apple MapでGPS表示", for: .normal)
        }
    }
    
    @IBOutlet weak var readDataButton: UIButton! {
        didSet {
            readDataButton.setTitle("FireStoreからデータを読み込む", for: .normal)
        }
    }
    
    @IBOutlet weak var curDateLabel: UILabel! {
        didSet {
            curDateLabel.isHidden = true
        }
    }
    
    
    @IBOutlet weak var dateLabel: UILabel! {
        didSet {
            dateLabel.isHidden = true
        }
    }
    
    @IBOutlet weak var timeLabel: UILabel! {
        didSet {
            timeLabel.isHidden = true
        }
    }
    
    @IBOutlet weak var tempLabel: UILabel!{
        didSet {
            tempLabel.isHidden = true
        }
    }
    
    @IBOutlet weak var humidLabel: UILabel! {
        didSet {
            humidLabel.isHidden = true
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func presentMapButtonAction(_ sender: Any) {
        print("apple map display!")
        
        let appleMapVC = UIStoryboard(name: "MapView", bundle:nil).instantiateViewController(withIdentifier: "MapVC") as! MapVC
                
        appleMapVC.modalPresentationStyle = .currentContext
        
        self.present(appleMapVC, animated: true) {
            print("complete to display GPS of Raspi")
        }
    }
    
    
    @IBAction func getDataAction(_ sender: Any) {
        DispatchQueue.main.async {
            self.curDateLabel.isHidden = true
            self.dateLabel.isHidden = true
            self.timeLabel.isHidden = true
            self.tempLabel.isHidden = true
            self.humidLabel.isHidden = true
            
            self.curDateLabel.text = "ボタンクリック時間: " + "yyyy-MM-dd HH:mm:ss".stringFromDate()
            self.getData()
        }
    }
    
    func getData() {
        Firestore.firestore().collection("Raspi").getDocuments { snapshot, error in
            if let error = error {
                print("Debug: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            var infoDatas: [InfoModel] = []
            let decoder = JSONDecoder()
            
            // Raspiで測定して、Firestoreに格納した温度のデータを読み込む
            for document in documents {
                do {
                    let data = document.data()
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let infoData = try decoder.decode(InfoModel.self, from: jsonData)
                    infoDatas.append(infoData)
                    self.dateLabel.text = "日付: " + infoData.date!
                    self.timeLabel.text = "時間: " + infoData.time!
                    self.tempLabel.text = "気温: " + infoData.temp!
                    self.humidLabel.text = "湿度: " + infoData.humid!
                    
                    self.dateLabel.isHidden = false
                    self.timeLabel.isHidden = false
                    self.tempLabel.isHidden = false
                    self.humidLabel.isHidden = false
                    
                } catch let error {
                    print("error: \(error)")
                }
            }
            
            self.curDateLabel.isHidden = false
        }
    }
}

