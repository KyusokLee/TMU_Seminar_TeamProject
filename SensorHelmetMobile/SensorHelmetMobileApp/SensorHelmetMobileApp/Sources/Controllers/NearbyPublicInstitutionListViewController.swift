//
//  NearbyPublicInstitutionListViewController.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/21.
//

import UIKit
import FirebaseFirestore
import Firebase

// Life Cycle and Variables
final class NearbyPublicInstitutionListViewController: UIViewController {
    
    @IBOutlet weak var publicInstitutionListTableView: UITableView!
    
    var occurPlaceLocalNameEng: String?
    var publicInstitutionList: [PublicInstitution] = []
    let customFirestore = CustomFirestore()
    
    // MARK: - ユーザである場合の分岐はまだ実装してない
    // helmetユーザであるなら、helmet1かhelmet2を異なって行う
    // helmetユーザでない場合,nilとなり、公共機関であることを示す
    // MARK: - ChatRoomId -> helmet1とのチャットか、helmet2とのチャットかを分岐する
    var chatRoomId: String?
    var helmetNumber: String?
    // タップしたヘルメットユーザの変数
    
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
        
        setupController()
        
        // リアルタイムにデータベースの更新を行うため、Listenerを設定
        setupPublicInstitutionListListener()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        // ここにnavigationBarのUI Settingをせず、ViewDidLoadや、instantiateでnavigationBarのsettingを行うと, BarItemの表示も、受け取るデータも正常に受け取れてないまま画面を表示してしまう
        setNavigationBar()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // reloadしないとCellが反映されない
        self.publicInstitutionListTableView.reloadData()
    }
    
    deinit {
        customFirestore.removeListener()
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
    
//    // MARK: - Listenerを設定
//    func setupPublicInstitutionListListener() {
//        // 正常に持ってきた
//        fetchData(with: occurPlaceLocalNameEng ?? "") { [weak self] list in
//            self?.publicInstitutionList = list
//            print("Closure 内部 : \n", self?.publicInstitutionList)
//            print("Closure内部のPublicInstituionの数: ", self?.publicInstitutionList.count)
//
//        }
//
//        // MARK: - うまく処理されていなかった理由: Closureは外部が処理されたあとに、内部が処理されるので、print出力ではうまく表示されていないかもしれないが、実際は反映されているかもしれない
//
//        // MARK: - でも、ここでは、反映されていない
//        print("Closure 外部: \n", self.publicInstitutionList)
//        print("Closure外部のPublicInstituionの数: ", self.publicInstitutionList.count)
//    }
    
//    // MARK: - 公共機関のリストを持ってきて、反映させる
    func setupPublicInstitutionListListener() {
//        var list: [PublicInstitution] = []
        
        // MARK: - ここで公共機関リストを取得
        customFirestore.getInstitutionList(place: occurPlaceLocalNameEng ?? "") { [weak self] result in
            switch result {
            case .success(let institutions):
                // MARK: - 配列を引き渡す
                self?.updateCell(with: institutions)
//                for institution in institutions {
//                    print("name: ", institution.name ?? "")
//                    print("type: ", institution.type ?? "")
//                    list.append(institution)
//                }
//                print("Temp Listの数: ", list.count )
//                completion(list)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // FireStoreのDocument(PublicInstitutionList)に変更があるとき、呼び出すメソッド
    // MARK: -　最初のsnapshotである場合、.addedで指定したデータベースの全てのDocumentsが表示される
    func updateCell(with data: [(PublicInstitution, DocumentChangeType)]) {
        // 一つずつchannelのデータをaddedする
        data.forEach { (institutionChannel, documentChangeType) in
            switch documentChangeType {
            case .added:
                self.addPublicInstitutionListInTable(institutionChannel)
            case .modified:
                self.updatePublicInstitutionListInTable(institutionChannel)
            case .removed:
                self.removePublicInstitutionListInTable(institutionChannel)
            }
        }
        
    }
    
    // MARK: - Added Cell and Document Data setting firstly
    // Cellの追加などは行うつもりではないので、まずは最初にデータを持ってくること機能だけを実装
    // MARK: - ユーザ間の場合はそのチャットルームを生成する必要があると思う
    func addPublicInstitutionListInTable(_ institution: PublicInstitution) {
        if !publicInstitutionList.contains(institution) {
            // 配列にそのデータがない場合
            publicInstitutionList.append(institution)
        } else {
            // 配列にそのデータがある場合
        }
        
        guard let index = publicInstitutionList.firstIndex(of: institution) else { return }
        publicInstitutionListTableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    // MARK: - Update Cell
    // メッセージを受信したとき、メッセージを送信したときに該当Cellを一番上に持っていく
    func updatePublicInstitutionListInTable(_ institution: PublicInstitution) {
        guard let index = publicInstitutionList.firstIndex(of: institution) else { return }
        
        publicInstitutionList[index] = institution
        publicInstitutionListTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    // MARK: Remove Cell
    // MARK: - データの種類によって分岐する予定
    // 一つ一つのデータを削除する予定はない
    func removePublicInstitutionListInTable(_ institution: PublicInstitution) {
        print("Delete Event!")
    }
    
    func setupController() {
        registerCell()
        publicInstitutionListTableView.delegate = self
        publicInstitutionListTableView.dataSource = self
    }
    
    // MARK: - 場所の名前を特定し、dataをfirestoreから持ってくるように
    func configure(with placeName: String) {
        self.occurPlaceLocalNameEng = placeName
        // MARK: - helmetごとの分岐をしたいのであれば、ここを違くすればいい
        // MARK: - ここで公共機関であるかヘルメットユーザであるかを分岐しておく
        // MARK: - helmetNumberは""に変更したりして、公共機関の場合、ヘルメットユーザの場合のそれぞれの動きを試す
        self.helmetNumber = "helmet1"
        
        // MARK: - chatRoomID
        // MARK: - まずは動きを確認できるようにすることを目標としているので、chatRoomIDはhelmet1に固定する
        self.chatRoomId = "helmet1"
        // Helmet２の場合 -> helmet2
        // self.helmetNumber = "helmet2"
        
        // 公共機関の場合 -> ""
        // self.helmetNumber = ""
    }
        
    private func registerCell() {
        publicInstitutionListTableView.register(
            UINib(
                nibName: "PublicInstitutionTableViewCell",
                bundle: nil),
            forCellReuseIdentifier: "PublicInstitutionTableViewCell"
        )
    }
    
    @objc func dismissBarButtonAction() {
        self.dismiss(animated: true)
    }
}

extension NearbyPublicInstitutionListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return publicInstitutionList.count
    }
    
    // Sectionは一つ
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
        let publicInstitutionType = publicInstitutionList[indexPath.row].type ?? ""
        let occurPlace = self.occurPlaceLocalNameEng ?? ""
        // MARK: - ChatRoomNumみたいな変数を設けるべき
        // MARK: - ヘルメットを着用してないユーザなら、チャットができないようにする　→ 無分別なチャットを防ぎ、データ及びトラフィック量を減らす
        let chatRoomNumber = self.chatRoomId ?? ""
        // MARK: - ヘルメットユーザか公共機関であるかを分岐しておく
        // nil -> 公共機関である
        let userIdentifier = self.helmetNumber ?? ""
        
        let controller = ChatViewController.instantiate(with: publicInstitutionName, type: publicInstitutionType, occurPlace: occurPlace, chatRoomNum: chatRoomNumber, userId: userIdentifier)
        // MARK: - publicInstitutionNameがchannelを指す
//        let navigationController = UINavigationController(rootViewController: controller)
//        navigationController.modalPresentationCapturesStatusBarAppearance = true
//        navigationController.modalPresentationStyle = .fullScreen
        // fullScreenであるが、1つ前のViewのサイズに合わせてpushされる
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
