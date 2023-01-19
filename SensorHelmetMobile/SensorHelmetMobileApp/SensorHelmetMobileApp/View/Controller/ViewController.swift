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
// storyboardでNavigationController実装


class ViewController: UIViewController {
    
    @IBOutlet weak var presentVideoListButton: UIButton! {
        didSet {
            presentVideoListButton.setTitle("Storageから動画リストを読み込む", for: .normal)
        }
    }
    
    @IBOutlet weak var bluetoothButton: UIButton! {
        didSet {
            bluetoothButton.setTitle("Bluetooth 探索", for: .normal)
        }
    }
    
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
    
    @IBOutlet weak var longitudeLabel: UILabel! {
        didSet {
            longitudeLabel.isHidden = true
        }
    }
    
    @IBOutlet weak var latitudeLabel: UILabel! {
        didSet {
            latitudeLabel.isHidden = true
        }
    }
    
    @IBOutlet weak var ipLabel: UILabel! {
        didSet {
            ipLabel.isHidden = true
        }
    }
    
    var longitudeInfo: Double = 0.0
    var latitudeInfo: Double = 0.0
    var shelterLongitude: Double = 0.0
    var shelterLatitude: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationController()
    }
    
    func setNavigationController() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(rgb: 0x64B5F6)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        self.navigationItem.backButtonTitle = "Back"
        self.navigationController?.navigationBar.tintColor = UIColor.black
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationController?.navigationBar.compactAppearance = appearance
        self.navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
        
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationItem.title = "Home View"
    }
    
    @IBAction func bluetoothButtonAction(_ sender: Any) {
        let serialVC = UIStoryboard.init(name: "SerialView", bundle: nil).instantiateViewController(withIdentifier: "SerialVC")
        self.present(serialVC, animated: true, completion: nil)
    }
    
    
    @IBAction func presentMapButtonAction(_ sender: Any) {
        print("apple map display!")
        
        let appleMapVC = UIStoryboard(name: "MapView", bundle:nil).instantiateViewController(withIdentifier: "MapVC") as! MapVC
        
        // longitudeとlatitudeがisHiddenじゃないとき、その位置情報をmapに表示できるように
        if !self.longitudeLabel.isHidden && !self.latitudeLabel.isHidden {
            appleMapVC.destinationLocation.longitude = longitudeInfo
            appleMapVC.destinationLocation.latitude = latitudeInfo
            appleMapVC.shelterLocation.longitude = shelterLongitude
            appleMapVC.shelterLocation.latitude = shelterLatitude
        } else {
            // alert 表示する
            print("No presented data with location data!")
            self.present(presentAlertView(), animated: true)
            
            return
        }
        
        appleMapVC.modalPresentationStyle = .currentContext
        
        self.present(appleMapVC, animated: true) {
            print("complete to display GPS of Raspi")
        }
    }
    
    func presentAlertView() -> UIAlertController {
        let alert = UIAlertController(title: nil, message: "確認できる位置情報がありません。データベースからデータを受け取った後、試してください。", preferredStyle: .alert)
        
        let alertAction = UIAlertAction(title: "確認", style: .default) { _ in
            print("No location data")
        }
        
        alert.addAction(alertAction)
        
        return alert
    }
    
    
    @IBAction func getDataAction(_ sender: Any) {
        DispatchQueue.main.async {
            self.curDateLabel.isHidden = true
            self.dateLabel.isHidden = true
            self.timeLabel.isHidden = true
            self.tempLabel.isHidden = true
            self.humidLabel.isHidden = true
            self.longitudeLabel.isHidden = true
            self.latitudeLabel.isHidden = true
            self.ipLabel.isHidden = true
            
            self.curDateLabel.text = "ボタンクリック時間: " + "yyyy-MM-dd HH:mm:ss".stringFromDate()
            self.getData()
        }
    }
    
    // navigation controllerを pushでpresentさせる
    @IBAction func presentVideoListBtnAction(_ sender: Any) {
        let videoListVC = UIStoryboard(name: "VideoListView", bundle:nil).instantiateViewController(withIdentifier: "VideoListVC") as! VideoListVC
        self.navigationController?.pushViewController(videoListVC, animated: true)
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
                    print(infoData)
                    infoDatas.append(infoData)
                    self.dateLabel.text = "日付: " + infoData.date!
                    self.timeLabel.text = "時間: " + infoData.time!
                    self.tempLabel.text = "気温: " + infoData.temp!
                    self.humidLabel.text = "湿度: " + infoData.humid!
                    self.longitudeLabel.text = "経度: " + infoData.longitude!
                    self.latitudeLabel.text = "緯度: " + infoData.latitude!
                    self.ipLabel.text = "IPアドレス: " + infoData.ip!
                    // 以下の処理で渡す
                    self.longitudeInfo = Double(infoData.longitude!)!
                    self.latitudeInfo = Double(infoData.latitude!)!
                    self.shelterLongitude = Double(infoData.shelterLongitude!)!
                    self.shelterLatitude = Double(infoData.shelterLatitude!)!
                
                    self.dateLabel.isHidden = false
                    self.timeLabel.isHidden = false
                    self.tempLabel.isHidden = false
                    self.humidLabel.isHidden = false
                    self.longitudeLabel.isHidden = false
                    self.latitudeLabel.isHidden = false
                    self.ipLabel.isHidden = false
                    
                } catch let error {
                    print("error: \(error)")
                }
            }
            
            self.curDateLabel.isHidden = false
        }
    }
}

