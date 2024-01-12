//
//  HelmetInfoModalViewController.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/12/03.
//

import UIKit

// MARK: - MapVCでhelmetannotationViewをクリックしたら、sheetPresentationとして表示する
// MARK: - SheetPresentationで表示させるVCは割と簡単なものだけを載せるつもりなので、Nibファイルなしで作成
class HelmetInfoModalViewController: UIViewController {
    
    @IBOutlet weak var helmetUserTableView: UITableView!
    // MARK: - InfoModel
    var helmetUserData = [InfoModel]()
    var helmetUserName: String = ""
    var helmetUserLocationName: String = ""
    var helmetConnectState: Bool = false
    
    // 画面遷移メソッド
    static func instantiate(with userName: String, placeName locationName: String, connectState isHelmetConnected: Bool) -> HelmetInfoModalViewController {
        let storyboard = UIStoryboard(name: "HelmetInfoModalView", bundle: nil)
        guard let controller = storyboard.instantiateViewController(
            withIdentifier: "HelmetInfoModalViewController"
        ) as? HelmetInfoModalViewController else {
            fatalError("HelmetInfoModalViewController could not be found.")
        }
        
        controller.fetchData(userName, locationName, isHelmetConnected)
        controller.loadViewIfNeeded()
        
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupController()
        setupNavigationBar()
        setupUI()
    }
}

// Functions & Logics
extension HelmetInfoModalViewController {
    func setupNavigationBar() {
        let dismiss = UIBarButtonItem(title: " 戻る", primaryAction: .init(handler: { [weak self] _Arg in
            self?.sheetPresentationController?.animateChanges {
                self?.dismiss(animated: true)
            }
        }))
        
        navigationItem.leftBarButtonItem = dismiss
    }
    
    func setupController() {
        confirmDelegates()
        registerCell()
    }
    
    // MARK: - Helmet Userのデータを同期させる
    // 一番最初に行うようにする
    func fetchData(_ userName: String, _ locationName: String, _ connectState: Bool) {
        self.helmetUserName = userName
        self.helmetUserLocationName = locationName
        self.helmetConnectState = connectState
    }
    
    func confirmDelegates() {
        helmetUserTableView.delegate = self
        helmetUserTableView.dataSource = self
    }
    
    func registerCell() {
        helmetUserTableView.register(
            UINib(
                nibName: "HelmetUserInfoTableViewCell",
                bundle: nil),
            forCellReuseIdentifier: "HelmetUserInfoTableViewCell"
        )
    }
    
    func setupUI() {
        view.backgroundColor = .systemBackground
        title = "ヘルメットユーザの情報"
    }
}

extension HelmetInfoModalViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.helmetConnectState {
            return 70
        } else {
            return 100
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.helmetConnectState {
            return 70
        } else {
            return 100
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HelmetUserInfoTableViewCell", for: indexPath) as? HelmetUserInfoTableViewCell else {
            print("HelmetUserInfoTableViewCell is not fetched successfully")
            return UITableViewCell()
        }
        // MARK: - ここでdelegateを受け取る
        // MARK: - delegateパータンが上手く処理されていなかった -> ?? 原因探し中
        cell.delegate = self
        
        cell.configure(
            placeName: self.helmetUserLocationName,
            userName: self.helmetUserName,
            isConnected: self.helmetConnectState
        )
        
//        cell.configurationUpdateHandler = { (cell, state) in
//            cell.selectionStyle = .none
//        }
        
        return cell
    }
//    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("Message機能不可")
    }
}

extension HelmetInfoModalViewController: HelmetUserInfoTableViewCellDelegate {
    func createChatRoomView(userName: String) {
        
        // MARK: - ChatViewControllerに遷移するように
        // MARK: - helmetユーザは自分を含め、2名しかいないことを前提として研究を進めた
//        let userData = helmetUserData.first!
        print("Message機能可能")
        print("Tap MessageButton with: ", userName)
        // MARK: - userDataをVCに引き渡し、他のユーザの動画リストやセンサー情報も閲覧できるようにする
    }
}
