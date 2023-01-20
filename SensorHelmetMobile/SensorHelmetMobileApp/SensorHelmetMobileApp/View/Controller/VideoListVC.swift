//
//  VideoListVC.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/11.
//

import UIKit
import FirebaseStorage

class VideoListVC: UIViewController {
    
    typealias StorageCompletion = (_ fileList: [String], _ urlList: [String]) -> Void
    @IBOutlet weak var videoListTableView: UITableView!
    
    // ただのstorage設定
    let storage = Storage.storage()
    // Storageの指定 (今回は、pathも一緒に指定)
    let storageReference = Storage.storage().reference().child("videos")
    // Storageから持ってきたビデオファイル(Name)を格納する配列
    var videoList: [String] = []
    // urlごとのファイルを格納する配列
    var videoUrlList: [String] = []
    // 画面をDragをすると、Cellが際反映されるように
    let refreshControl = UIRefreshControl()
    
    //⚠️ファイルリストの読み込みを行う間に、ユーザの認識touchを受け取らないように
//    var isLoading = true
//    var isLoadFinished = false
    
    // custom loadingViewを定義
    private let loadingView: LoadingView = {
        let view = LoadingView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // 初期設定として、loadingをtrueに
        view.isLoading = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationController()
        registerCell()
        
        videoListTableView.delegate = self
        videoListTableView.dataSource = self
        
        initRefresh()
        
        self.view.addSubview(loadingView)
        setLoadingViewConstraints()
        // viewに入るとdataを読み込むように
        getAllFileListProgress()
    }
    
    func initRefresh() {
        refreshControl.addTarget(self, action: #selector(refreshTable(refresh:)), for: .valueChanged)
            
        refreshControl.backgroundColor = .systemBackground
        refreshControl.tintColor = .systemGray
        refreshControl.attributedTitle = NSAttributedString(string: "引っ張って更新")
        
        videoListTableView.refreshControl = refreshControl
    }
        
    @objc func refreshTable(refresh: UIRefreshControl) {
        print("更新　スタート！")
        
        self.loadingView.isLoading = true
        getAllFileListProgress()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.videoListTableView.reloadData()
            refresh.endRefreshing()
        }
    }
    
    func setLoadingViewConstraints() {
        NSLayoutConstraint.activate([
            self.loadingView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.loadingView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.loadingView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.loadingView.topAnchor.constraint(equalTo: self.view.topAnchor)
        ])
    }
    
    func registerCell() {
        videoListTableView.register(UINib(nibName: "VideoListTableViewCell", bundle: nil), forCellReuseIdentifier: "VideoListTableViewCell")
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
        self.navigationItem.title = "動画リスト"
    }
    
    func getAllFileListProgress() {
        if loadingView.isLoading {
            DispatchQueue.main.async {
                self.getListFromStorage { fileList, urlList in
                    self.videoList = fileList
                    self.videoUrlList = urlList
                    self.loadingView.isLoading = false
                    self.videoListTableView.reloadData()
                }
            }
            
        } else {
            return
        }
    }
    
    func getListFromStorage(completion: @escaping StorageCompletion) {
        guard self.loadingView.isLoading else {
            return
        }
        
        storageReference.listAll { (result, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            if let result = result {
                var fileList = [String]()
                var urlList = [String]()
                
                for item in result.items {
                    print("item: ", item.name)
                    fileList.append(item.name)
                    urlList.append(item.fullPath)
                }
                
                completion(fileList, urlList)
            }
        }
    }

}

extension VideoListVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "VideoListTableViewCell", for: indexPath) as? VideoListTableViewCell else {
            return UITableViewCell()
        }
        
        // videoListにStringが入る
        cell.configure(fileName: videoList[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let videoDetailVC = UIStoryboard(name: "VideoDetailView", bundle:nil).instantiateViewController(withIdentifier: "VideoDetailVC") as! VideoDetailVC
        
        videoDetailVC.fileName = videoList[indexPath.row]
        videoDetailVC.urlString = videoUrlList[indexPath.row]
        print(videoDetailVC.urlString)
        self.navigationController?.pushViewController(videoDetailVC, animated: true)
    }
}


// ✍️Windowsを用いたloadingViewの実装
//    // getAllFileList()でファイルリストの読み込みが全部終わるまで、loadingViewを表示する
//    func showLoadingView(load getList: Bool) {
//        // loadがtrueのときのみ、以下の処理を行う
//        guard getList else {
//            return
//        }
//
//        print("showLoadingView!")
//
//        let scenes = UIApplication.shared.connectedScenes
//        let windowScene = scenes.first as? UIWindowScene
//        let window = windowScene?.windows.first
//
//        if let hasLoadingView = self.loadingView {
//            window?.addSubview(hasLoadingView)
//        } else {
//            let loadingView = UIView(frame: UIScreen.main.bounds)
//            loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
//
//            let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
//            activityIndicator.center = loadingView.center
//            activityIndicator.color = UIColor.white
//            activityIndicator.style = UIActivityIndicatorView.Style.large
//            activityIndicator.hidesWhenStopped = true
//            activityIndicator.startAnimating()
//
//            loadingView.addSubview(activityIndicator)
//
//            let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
//            titleLabel.center = CGPoint(x: activityIndicator.frame.origin.x + activityIndicator.frame.size.width / 2, y: activityIndicator.frame.origin.y + 90)
//            titleLabel.textColor = UIColor.white
//            titleLabel.textAlignment = .center
//            titleLabel.text = "ただいま、リストを読み込んでいます..."
//            loadingView.addSubview(titleLabel)
//            print("リスト読み込み中")
//
//            window?.addSubview(loadingView)
//            self.loadingView = loadingView
//        }
//    }
