//
//  ViewController.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2022/12/12.
//

import UIKit
import FirebaseFirestore
import UserNotifications

// Firebaseのデータを読む
// Raspiの遠隔操作ができるように
// storyboardでNavigationController実装
// TODO: Local Push Alarmを通して、災害が起きたというのをalarmで送りたい!
// TODO: - メモリのdeinitの部分を解決する必要がある

class ViewController: UIViewController {
    
    @IBOutlet weak var raspberryPiImageView: UIImageView! {
        didSet {
            raspberryPiImageView.contentMode = .scaleAspectFit
        }
    }
    
    @IBOutlet weak var presentVideoListButton: UIButton! {
        didSet {
            var config = UIButton.Configuration.filled()
            config.buttonSize = .medium
            config.baseBackgroundColor = UIColor.systemRed.withAlphaComponent(0.85)
            config.baseForegroundColor = UIColor.white
            config.imagePlacement = NSDirectionalRectEdge.leading
            // buttonのimageをwithConfigurationと同時に作らないと、buttonの中にimage部分の枠が含まれてしまう
            config.image = UIImage(systemName: "list.and.film",
                                   withConfiguration: UIImage.SymbolConfiguration(scale: .large))
            config.imagePadding = 10
            config.contentInsets = NSDirectionalEdgeInsets.init(top: 10, leading: 10, bottom: 10, trailing: 10)
            config.cornerStyle = .medium
            config.titleAlignment = .center
            config.attributedTitle = AttributedString("動画リストを取得", attributes: AttributeContainer([
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .medium)]))
            presentVideoListButton.layer.cornerRadius = 8
            presentVideoListButton.configuration = config
        }
    }
    
    @IBOutlet weak var bluetoothButton: UIButton! {
        didSet {
            var config = UIButton.Configuration.filled()
            config.buttonSize = .medium
            config.baseBackgroundColor = UIColor.systemBlue
            config.baseForegroundColor = UIColor.white
            config.imagePlacement = NSDirectionalRectEdge.leading
            // buttonのimageをwithConfigurationと同時に作らないと、buttonの中にimage部分の枠が含まれてしまう
            config.image = UIImage(systemName: "antenna.radiowaves.left.and.right.circle",
                                   withConfiguration: UIImage.SymbolConfiguration(scale: .large))
            config.imagePadding = 10
            config.contentInsets = NSDirectionalEdgeInsets.init(top: 10, leading: 10, bottom: 10, trailing: 10)
            config.cornerStyle = .medium
            config.titleAlignment = .center
            config.attributedTitle = AttributedString("Bluetooth 探索", attributes: AttributeContainer([
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .medium)]))
            bluetoothButton.layer.cornerRadius = 8
            bluetoothButton.configuration = config
        }
    }
    
    @IBOutlet weak var presentMapButton: UIButton! {
        didSet {
            var config = UIButton.Configuration.filled()
            config.buttonSize = .medium
            config.baseBackgroundColor = UIColor(rgb: 0x4CAF50)
            config.baseForegroundColor = UIColor.white
            config.imagePlacement = NSDirectionalRectEdge.leading
            // buttonのimageをwithConfigurationと同時に作らないと、buttonの中にimage部分の枠が含まれてしまう
            config.image = UIImage(systemName: "location.magnifyingglass",
                                   withConfiguration: UIImage.SymbolConfiguration(scale: .large))
            config.imagePadding = 10
            config.contentInsets = NSDirectionalEdgeInsets.init(top: 10, leading: 10, bottom: 10, trailing: 10)
            config.cornerStyle = .medium
            config.titleAlignment = .center
            config.attributedTitle = AttributedString("地図で経路を表示", attributes: AttributeContainer([
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .medium)]))
            presentMapButton.layer.cornerRadius = 8
            presentMapButton.configuration = config
        }
    }
    
    @IBOutlet weak var readDataButton: UIButton! {
        didSet {
            var config = UIButton.Configuration.filled()
            config.buttonSize = .medium
            config.baseBackgroundColor = UIColor(rgb: 0xFF9800).withAlphaComponent(0.8)
            config.baseForegroundColor = UIColor.white
            config.imagePlacement = NSDirectionalRectEdge.leading
            // buttonのimageをwithConfigurationと同時に作らないと、buttonの中にimage部分の枠が含まれてしまう
            config.image = UIImage(systemName: "rectangle.and.text.magnifyingglass",
                                   withConfiguration: UIImage.SymbolConfiguration(scale: .large))
            config.imagePadding = 10
            config.contentInsets = NSDirectionalEdgeInsets.init(top: 10, leading: 10, bottom: 10, trailing: 10)
            config.cornerStyle = .medium
            config.titleAlignment = .center
            config.attributedTitle = AttributedString("センサーデータを取得", attributes: AttributeContainer([
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .medium)]))
            readDataButton.layer.cornerRadius = 8
            readDataButton.configuration = config
        }
    }
    
    @IBOutlet weak var curDateLabel: UILabel! {
        didSet {
            curDateLabel.font = .systemFont(ofSize: 15, weight: .medium)
            curDateLabel.textColor = UIColor.black.withAlphaComponent(0.85)
            curDateLabel.textAlignment = .center
            curDateLabel.layer.borderColor = UIColor.systemGray3.cgColor
            curDateLabel.layer.borderWidth = 2
            curDateLabel.layer.cornerRadius = 8
            curDateLabel.isHidden = true
        }
    }
    
    @IBOutlet weak var dateLabel: UILabel! {
        didSet {
            dateLabel.isHidden = true
            dateLabel.font = .systemFont(ofSize: 17, weight: .medium)
        }
    }
    
    @IBOutlet weak var timeLabel: UILabel! {
        didSet {
            timeLabel.isHidden = true
            timeLabel.font = .systemFont(ofSize: 17, weight: .medium)
        }
    }
    
    @IBOutlet weak var tempLabel: UILabel!{
        didSet {
            tempLabel.isHidden = true
            tempLabel.font = .systemFont(ofSize: 17, weight: .medium)
        }
    }
    
    @IBOutlet weak var humidLabel: UILabel! {
        didSet {
            humidLabel.isHidden = true
            humidLabel.font = .systemFont(ofSize: 17, weight: .medium)
        }
    }
    
    @IBOutlet weak var longitudeLabel: UILabel! {
        didSet {
            longitudeLabel.isHidden = true
            longitudeLabel.font = .systemFont(ofSize: 17, weight: .medium)
        }
    }
    
    @IBOutlet weak var latitudeLabel: UILabel! {
        didSet {
            latitudeLabel.isHidden = true
            latitudeLabel.font = .systemFont(ofSize: 17, weight: .medium)
        }
    }
    
    @IBOutlet weak var ipLabel: UILabel! {
        didSet {
            ipLabel.isHidden = true
            ipLabel.font = .systemFont(ofSize: 17, weight: .medium)
        }
    }
    
    var longitudeInfo: Double = 0.0
    var latitudeInfo: Double = 0.0
    var shelterLongitude: Double = 0.0
    var shelterLatitude: Double = 0.0
    // MARK: - ⚠️演習のための位置情報
    var pracLongitudeInfo: Double = 0.0
    var pracLatitudeInfo: Double = 0.0
    // 配列型のModelにしたため、firstで受け取る予定
    // 1つだけ受け取るつもり
    var disaster: DisasterModel?
    var disasterLongitude: Double = 0.0
    var disasterLatitude: Double = 0.0
    let notificationCenter = UNUserNotificationCenter.current()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationController()
        self.bluetoothButton.isUserInteractionEnabled = false
        setImageView()
        // alarmの権限を得る
        requestNotificationAuthorization()
        disasterOccurred()
    }
    
    func setImageView() {
        if let image = redrawImage() {
            DispatchQueue.main.async {
                self.raspberryPiImageView.image = image
            }
        }
    }
    
    // Local Pushの権限のrequest
    func requestNotificationAuthorization() {
        let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: authOptions) { success, error in
            if let error = error {
                print(error.localizedDescription)
            }
            // alarm設定されたら、以下の処理を行う
            print("Permission granted: \(success)")
            
        }
    }
    
    // Local push alarmを送信するメソッド
    func sendDisasterNotification(seconds: Double) {
        notificationCenter.removeAllPendingNotificationRequests()
        print("Send Notification!")

        let content = UNMutableNotificationContent()
        if let disasterType = disaster?.disasterType,
           let city = disaster?.addressInfo?.city,
           let localName = disaster?.addressInfo?.localName,
           let description = disaster?.description {
            content.title = "⚠️\(disasterType)が発生しました!"
            content.body = "\(city)、\(localName)の付近で\n\(description)しました。"
        }
        
        
//        // repeatはfalseにしておく
//        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.hour, .minute], from: <#Date#>), repeats: false)
        
        // Time InterValを用いた triggerを実装
        // viewが表示されて15秒の後、表示されるように！
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        print("send Alarm!")
        notificationCenter.add(request) { (error) in
            if let error = error {
                // handle errors
                print(error.localizedDescription)
            }
        }

        // MARK: - UserDefaultsを用いたKeyの設定
//        if UserDefaults.standard.bool(forKey: "DisasterAlarm") {
//            print("send Alarm!")
//            notificationCenter.add(request) { (error) in
//                if let error = error {
//                    // handle errors
//                    print(error.localizedDescription)
//                }
//            }
//        }
    }
    
    // MARK: - 任意のタイミングを設定して、任意の災害が起きたことを想定する
    // 最初から災害のデータを持つように任意で設定　-> 今後、apiやserver alarm送信機能を導入したい
    func disasterOccurred() {
        guard let path = Bundle.main.path(forResource: "mock", ofType: "json") else {
            fatalError("ファイルが見つからない")
        }
  
        guard let jsonString = try? String(contentsOfFile: path) else {
            fatalError("String型に変換できない")
        }

        // Decoding
        let decoder = JSONDecoder()
        let data = jsonString.data(using: .utf8)
       
        // Mock.jsonにデータ以外のStringが入るとdecodeが正常に行われない
        if let data = data,
           let disasters = try? decoder.decode([DisasterModel].self, from: data) {
            print("災害: ", disasters.first?.disasterType ?? "")
            // disasterにdecoding dataを入れる
            if let disaster = disasters.first {
                self.disaster = disaster
                // 災害地の位置情報を入れる
                self.disasterLongitude = Double(disaster.disasterLongitude!) ?? 0.0
                self.disasterLatitude = Double(disaster.disasterLatitude!) ?? 0.0
                print(self.disaster!)
                // 20秒後、実装
                self.sendDisasterNotification(seconds: 10)
            }
        } else {
            print("変換に失敗")
        }
        
        print(self.disasterLongitude)
        print(self.disasterLatitude)
        
        // MARK: - Encodingに関するコード
        // 今回は、使わない
//        let dataModel = DisasterModel(name: "sample", addressInfo: .init(contry: "contry", city: "city"), image: "03")
//        let encoder = JSONEncoder()
//        if let jsonData = try? encoder.encode(dataModel),
//           let jsonString = String(data: jsonData, encoding: .utf8) {
//            print(jsonString)
//        }
    }
    
    func redrawImage() -> UIImage? {
        let customImage = UIImage(named: "RaspberryPiOfficialLogo")
        let newImageRect = CGRect(x: 0, y: 0, width: 200, height: 200)
        UIGraphicsBeginImageContext(CGSize(width: 200, height: 200))
        customImage?.draw(in: newImageRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysOriginal)
        UIGraphicsEndImageContext()
        
        return newImage
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
            //🔥元々のやつ
            appleMapVC.destinationLocation.longitude = longitudeInfo
            appleMapVC.destinationLocation.latitude = latitudeInfo
//            // MARK: - ⚠️練習のためのもの
//            appleMapVC.destinationLocation.longitude = pracLongitudeInfo
//            appleMapVC.destinationLocation.latitude = pracLatitudeInfo
            
            appleMapVC.shelterLocation.longitude = shelterLongitude
            appleMapVC.shelterLocation.latitude = shelterLatitude
            
            // MARK: - 災害の情報があれば
            if let disaster = self.disaster {
                print(disaster)
                appleMapVC.disasterLocation.longitude = disasterLongitude
                appleMapVC.disasterLocation.latitude = disasterLatitude
                appleMapVC.disaster = disaster
            }
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
            self.curDateLabel.text = "データ取得時間: " + "yyyy年MM月dd日 HH時mm分ss秒".stringFromDate()
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
                    
                    // MARK: - ⚠️演習のためのもの
                    self.pracLongitudeInfo = Double(infoData.practiceLogitude!)!
                    self.pracLatitudeInfo = Double(infoData.practiceLatitude!)!
                
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

