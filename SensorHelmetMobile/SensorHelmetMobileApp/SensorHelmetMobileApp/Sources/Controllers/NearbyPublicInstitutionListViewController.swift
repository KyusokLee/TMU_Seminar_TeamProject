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
    
    var occurPlaceLocalNameEng: String?
    var publicInstitutionList: [PublicInstitution] = []
    let customFirestore = CustomFirestore()
    
    // 画面遷移メソッド
    static func instantiate(with placeName: String) -> NearbyPublicInstitutionListViewController {
        let storyboard = UIStoryboard(name: "NearbyPublicInstitutionListView", bundle: nil)
        guard let controller = storyboard.instantiateViewController(
            withIdentifier: "NearbyPublicInstitutionListViewController"
        ) as? NearbyPublicInstitutionListViewController else {
            fatalError("NearbyPublicInstitutionListViewController could not be found.")
        }
        
        controller.configure(with: placeName)
        controller.loadViewIfNeeded()
        
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell()
        
        publicInstitutionListTableView.delegate = self
        publicInstitutionListTableView.dataSource = self

        // Do any additional setup after loading the view.
        closurePrac()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        // ここにnavigationBarのUI Settingをせず、ViewDidLoadや、instantiateでnavigationBarのsettingを行うと, BarItemの表示も、受け取るデータも正常に受け取れてないまま画面を表示してしまう
        setNavigationBar()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        printList()
        self.publicInstitutionListTableView.reloadData()
    }
}

// MARK: - Logic and Function
extension NearbyPublicInstitutionListViewController {
    private func setNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        // アラームが表示されていないのにも関わらず　Toyodaの地名が入ってしまった
        if let locationNameEng = occurPlaceLocalNameEng {
            self.navigationItem.title = "\(locationNameEng)駅近くの公共機関"
        } else {
            self.navigationItem.title = "近くの公共機関"
        }
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
    
    // MARK: - practice
    func closurePrac() {
        // 正常に持ってきた
        fetchData(with: occurPlaceLocalNameEng ?? "") { [weak self] list in
            self?.publicInstitutionList = list
            print("클로저 내부 : \n", self?.publicInstitutionList)
            print("클로저 내부에서 PublicInstituion 요소 수: ", self?.publicInstitutionList.count)
            
            // MARK: - ここではちゃんと反映されている
            
        }
        
        // MARK: - うまく処理されていなかった理由: Closureは外部が処理されたあとに、内部が処理されるので、print出力ではうまく表示されていないかもしれないが、実際は反映されているかもしれない
        
        // MARK: - でも、ここでは、反映されていない
        print("클로저 외부: \n", self.publicInstitutionList)
        print("클로저 외부에서 PublicInstituion 요소 수: ", self.publicInstitutionList.count)
    }
    
    // MARK: - 処理確認のためのprint文間数
    func printList() {
        // MARK: - でも、ここでは、反映されていない
        print("프린트 함수: \n", self.publicInstitutionList)
        print("프린트 함수에서 PublicInstituion 요소 수: ", self.publicInstitutionList.count)
    }
    
//    // MARK: - 公共機関のリストを持ってきて、反映させる
    func fetchData(with placeName: String, completion: @escaping ([PublicInstitution]) -> Void) {
        var list: [PublicInstitution] = []
        
        customFirestore.getInstitutionList(place: placeName) { [weak self] result in
            
            switch result {
            case .success(let institutions):
                
                for institution in institutions {
                    print("name: ", institution.name ?? "")
                    print("type: ", institution.type ?? "")
                    list.append(institution)
                }
                print("Temp Listの数: ", list.count )
                completion(list)
            case .failure(let error):
                print(error)
                completion([])
            }
        }
    }
    
    // MARK: - 場所の名前を特定し、dataをfirestoreから持ってくるように
    func configure(with placeName: String) {
        occurPlaceLocalNameEng = placeName
    }
    
    // MARK: - 災害が起きた場所のアルファベットからデータを認識させて、firestoreからその場所のデータと一致するdocumentを読み込むようにしたい
//    private func getNearbyInstitutionList() {
//        // firestoreからデータを読み込む
//        Firestore.firestore().collection("PublicInstitutionList").getDocuments { snapshot, error in
//            if let error = error {
//                print("Debug: \(error.localizedDescription)")
//                return
//            }
//
//            guard let documents = snapshot?.documents else { return }
//
//            var infoDatas: [InfoModel] = []
//            let decoder = JSONDecoder()
//
//            // Raspiで測定して、Firestoreに格納した温度のデータを読み込む
//            for document in documents {
//                do {
//                    let data = document.data()
//                    let jsonData = try JSONSerialization.data(withJSONObject: data)
//                    let infoData = try decoder.decode(InfoModel.self, from: jsonData)
//                    print(infoData)
//                    infoDatas.append(infoData)
//                    self.dateLabel.text = "日付: " + infoData.date!
//                    self.timeLabel.text = "時間: " + infoData.time!
//                    self.tempLabel.text = "気温: " + infoData.temp!
//                    self.humidLabel.text = "湿度: " + infoData.humid!
//                    self.longitudeLabel.text = "経度: " + infoData.longitude!
//                    self.latitudeLabel.text = "緯度: " + infoData.latitude!
//                    self.ipLabel.text = "IPアドレス: " + infoData.ip!
//                    self.COGasDensityLabel.text = "COガス密度: " + infoData.COGasDensity!
//                    // 以下の処理で渡す
//                    self.longitudeInfo = Double(infoData.longitude!)!
//                    self.latitudeInfo = Double(infoData.latitude!)!
//                    self.shelterLongitude = Double(infoData.shelterLongitude!)!
//                    self.shelterLatitude = Double(infoData.shelterLatitude!)!
//
//                    // MARK: - ⚠️演習のためのもの
//                    self.pracLongitudeInfo = Double(infoData.practiceLogitude!)!
//                    self.pracLatitudeInfo = Double(infoData.practiceLatitude!)!
//
//                    self.dateLabel.isHidden = false
//                    self.timeLabel.isHidden = false
//                    self.tempLabel.isHidden = false
//                    self.humidLabel.isHidden = false
//                    self.longitudeLabel.isHidden = false
//                    self.latitudeLabel.isHidden = false
//                    self.ipLabel.isHidden = false
//                    self.COGasDensityLabel.isHidden = false
//
//                } catch let error {
//                    print("error: \(error)")
//                }
//            }
//
//            self.curDateLabel.isHidden = false
//        }
//    }
    
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PublicInstitutionTableViewCell", for: indexPath) as? PublicInstitutionTableViewCell else {
            return UITableViewCell()
        }
        
        let type = publicInstitutionList[indexPath.row].type ?? ""
        let name = publicInstitutionList[indexPath.row].name ?? ""
        
        // MARK: - 公共機関の名前が入る
        cell.configure(institutionType: type, institutionName: name)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let publicInstitutionName = publicInstitutionList[indexPath.row].name ?? ""
        let controller = MessagesViewController.instantiate(with: publicInstitutionName)
        controller.institutionName = publicInstitutionName
//        controller.configure(with: occurPlaceEnglish ?? "")
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationCapturesStatusBarAppearance = true
        navigationController.modalPresentationStyle = .fullScreen
        // fullScreenであるが、1つ前のViewのサイズに合わせてpushされる
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
