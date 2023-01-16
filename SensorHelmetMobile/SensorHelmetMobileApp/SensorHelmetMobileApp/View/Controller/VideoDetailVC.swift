//
//  VideoDetailVC.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/11.
//

import UIKit
// 動画の再生のためのimport
import AVFoundation
import AVKit
import FirebaseStorage

//動画を最終的に再生するViewController

class VideoDetailVC: UIViewController {
    
    @IBOutlet weak var videoContainer: UIView!
    
    @IBOutlet weak var fileNameLabel: UILabel! {
        didSet {
            fileNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        }
    }
    @IBOutlet weak var playButton: UIButton! {
        didSet {
            playButton.setTitle("Play", for: .normal)
        }
    }
    
    @IBOutlet weak var pauseButton: UIButton! {
        didSet {
            pauseButton.setTitle("Pause", for: .normal)
        }
    }
    
    var player: AVPlayer?
    var fileName: String = ""
    // videoがあるfullPathのurlString
    var urlString: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationController()
        configure()
        print("present VideoDetailVC")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadVideoURL(urlString: urlString) { url in
            self.makePlayerAndPlay(url: url)
        }
    }
    
    func configure() {
        fileNameLabel.text = fileName
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
        self.navigationItem.title = "動画詳細"
    }
    
    // videoファイルを動画として再生
    func getVideo() {
    // gs://
    }
    
    func downloadData() {
        // Storageの指定
        
    }
    
//    //Firestoreからvideoをダウンロードする
//    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
//        let reference = storage.child(path)
//
//        reference.downloadURL(completion: { url, error in
//            guard let url = url, error == nil else {
//                completion(.failure(StorageError.cancelled))
//                return
//            }
//            completion(.success(url))
//        })
//    }
    
    // Local Fileとしてダウンロード
    func loadVideoURL(urlString: String, completion: @escaping (URL?) -> Void) {
        let storageReference = Storage.storage().reference().child(urlString)
//        let metaData = StorageMetadata()
//        metaData.contentType = "video/mp4"
//        let megaByte = Int64(1 * 10)
        let tmpFileURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("video").appendingPathExtension("mp4")
        storageReference.write(toFile: tmpFileURL) { url, error in
            if let error = error {
                print(error.localizedDescription)
                completion(nil)
            } else {
                // localUrlが生成される
                print(url!)
                completion(url)
            }
        }
        
        
//        storageReference.getData(maxSize: megaByte) { data, error in
//            guard let videoData = data else {
//                completion(nil)
//                return
//            }
            
//            let tmpFileURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("video").appendingPathExtension("mp4")
//            let wasFileWritten = (try? videoData.write(to: tmpFileURL, options: [.atomic])) != nil
            
//            if !wasFileWritten {
//                print("File was NOT Written")
//            }
    }
    
    func makePlayerAndPlay(url: URL?) {
        // ただのURLだと、Optionalであるため、安全なOptional Unwrappingである　if let Optional Bindingを用いる
        if let hasURL = url {
//            let filePath = Bundle.main.path(forResource: nil, ofType: "mp4")!
//
//
//            // 📚playerオブジェクト生成
//            self.player = AVPlayer(url: URL(filePath: filePath))
            self.player = AVPlayer(url: hasURL)
            // AVPlayerLayer: playerの大きさなどのPlayerに関する枠を管理するオブジェクト
            // これをすることで、playerがようやく大きさという特性を与えることができる
            let playerLayer = AVPlayerLayer(player: player)
            // AVPlayerLayerは、ViewじゃなくCGLayer型,つまり addSubviewができない
            //そのため、layer.addSubplayerを使う
                
            videoContainer.layer.addSublayer(playerLayer)
            //📚Layerは、AutoLayoutの概念がない
            //まだ、Layerの大きさの設定をする
            playerLayer.frame = videoContainer.bounds
                
            //playerのデータを受け取ったとき、勝手に再生されないように、初めからpause()状態になるようにする
            self.player?.play()
        }
    }
    
    
    @IBAction func playButtonAction(_ sender: Any) {
        self.player?.play()
    }
    
    @IBAction func pauseButtonAcition(_ sender: Any) {
        self.player?.pause()
    }
    
}
