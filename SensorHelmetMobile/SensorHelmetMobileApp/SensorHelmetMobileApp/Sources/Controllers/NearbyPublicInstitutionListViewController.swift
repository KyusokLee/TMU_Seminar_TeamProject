//
//  NearbyPublicInstitutionListViewController.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/21.
//

import UIKit
import FirebaseFirestore

// Life Cycle and Variables
final class NearbyPublicInstitutionListViewController: UIViewController {
    
    @IBOutlet weak var publicInstitutionListTableView: UITableView!
    
    var publicInstitutionModel: PublicInstitution?
    var publicInstitutionList: [String] = []
    
    // カメラをVCへの画面遷移メソッド
    static func instantiate() -> NearbyPublicInstitutionListViewController {
        let storyboard = UIStoryboard(name: "NearbyPublicInstitutionListView", bundle: nil)
        guard let controller = storyboard.instantiateViewController(
            withIdentifier: "NearbyPublicInstitutionListViewController"
        ) as? NearbyPublicInstitutionListViewController else {
            fatalError("NearbyPublicInstitutionListViewController could not be found.")
        }
        
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
        registerCell()
        
        publicInstitutionListTableView.delegate = self
        publicInstitutionListTableView.dataSource = self

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

// MARK: - Logic and Function
private extension NearbyPublicInstitutionListViewController {
    private func setNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        self.navigationItem.title = "近くの公共機関"
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        appearance.titleTextAttributes = textAttributes
        
        let dismissBarButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark")?.withTintColor(UIColor.black, renderingMode: .alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(dismissBarButtonAction)
        )
        self.navigationController?.navigationBar.topItem?.leftBarButtonItem = dismissBarButton
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    // MARK: - 災害が起きた場所のアルファベットからデータを認識させて、firestoreからその場所のデータと一致するdocumentを読み込むようにしたい
    private func getNearbyInstitutionList() {
        // firestoreからデータを読み込む
        Firestore.firestore().collection("PublicInstitutionList").getDocuments { snapshot, error in
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
                    self.COGasDensityLabel.text = "COガス密度: " + infoData.COGasDensity!
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
                    self.COGasDensityLabel.isHidden = false
                    
                } catch let error {
                    print("error: \(error)")
                }
            }
            
            self.curDateLabel.isHidden = false
        }
    }
    
    private func registerCell() {
        publicInstitutionListTableView.register(UINib(nibName: "PublicInstitutionTableViewCell", bundle: nil), forCellReuseIdentifier: "PublicInstitutionTableViewCell")
    }
    
    @objc func dismissBarButtonAction() {
        self.dismiss(animated: true)
    }
}

extension NearbyPublicInstitutionListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return publicInstitutionList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PublicInstitutionTableViewCell", for: indexPath) as? PublicInstitutionTableViewCell else {
            return UITableViewCell()
        }
        
        // MARK: - 公共機関の名前が入る
        cell.configure(institutionType: <#T##String#>, institutionName: <#T##String#>)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
    }
    
    
}
