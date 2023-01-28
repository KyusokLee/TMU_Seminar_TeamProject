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
            fileNameLabel.adjustsFontForContentSizeCategory = true
            fileNameLabel.textAlignment = .center
            fileNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        }
    }
    @IBOutlet weak var playButton: UIButton! {
        didSet {
            let imageConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
            let image = UIImage(systemName: "play.circle", withConfiguration: imageConfig)?.withRenderingMode(.alwaysTemplate)
            playButton.setImage(image, for: .normal)
            playButton.tintColor = UIColor.systemBlue.withAlphaComponent(0.85)
            playButton.backgroundColor = UIColor.white
//            playButton.setTitle("Play", for: .normal)
        }
    }
    
    @IBOutlet weak var pauseButton: UIButton! {
        didSet {
            let imageConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
            let image = UIImage(systemName: "pause.circle", withConfiguration: imageConfig)?.withRenderingMode(.alwaysTemplate)
            pauseButton.setImage(image, for: .normal)
            pauseButton.tintColor = UIColor.systemRed.withAlphaComponent(0.9)
            pauseButton.backgroundColor = UIColor.white
            // 最初は、isEnabled状態に
            pauseButton.isEnabled = false
        }
    }
    
    lazy var progressBar: UISlider = {
        let slider = UISlider()
        slider.tintColor = .systemRed
        slider.addTarget(self, action: #selector(didChangedProgressBar(_ :)), for: .valueChanged)
        //slider.addTarget(self, action: #selector(didTouchExit(_ :)), for: .touchCancel)
        slider.translatesAutoresizingMaskIntoConstraints = false
        
        return slider
    }()
    
    var player: AVPlayer?
    var fileName: String = ""
    // videoがあるfullPathのurlString
    var urlString: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(progressBar)
        setProgressBarConstraints()
        setNavigationController()
        configure()
        print("present VideoDetailVC")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadVideoURL(urlString: urlString) { url in
            self.makePlayerAndPlay(url: url)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.player?.cancelPendingPrerolls()
    }
    
    func configure() {
        fileNameLabel.text = "ファイル名: \(fileName)"
    }
    
    func setProgressBarConstraints() {
        self.progressBar.leadingAnchor.constraint(equalTo: self.videoContainer.leadingAnchor, constant: 15).isActive = true
        self.progressBar.trailingAnchor.constraint(equalTo: self.videoContainer.trailingAnchor, constant: -15).isActive = true
        self.progressBar.bottomAnchor.constraint(equalTo: self.videoContainer.bottomAnchor, constant: -20).isActive = true
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
    
    // 動画の再生barの実装
    @objc func didChangedProgressBar(_ sender: UISlider) {
//        guard let duration = player?.currentItem?.duration else { return }
//        let value = Float64(sender.value) * CMTimeGetSeconds(duration)
//
//        let seekTime = CMTime(value: CMTimeValue(value), timescale: 1)
//
//        player?.seek(to: seekTime)
        let rate = player?.rate
        // いったんplayerをとめる
        player?.rate = 0
        // 指定した時間へ移動
        // MARK: - ⚠️途中の段階: pause後にreplayする機能を実装
        self.player?.seek(to: CMTime(seconds: Double(sender.value), preferredTimescale: Int32(NSEC_PER_SEC)), completionHandler: { _ in
            self.player?.rate = rate!
            print("Change progress bar")
        })
    }
    
//    @objc func didTouchExit(_ sender: UISlider) {
//        print("指を離れました!")
//        if player?.rate == 0 {
//            self.player?.play()
//        }
//    }
    
    // videoファイルを動画として再生
    func getVideo() {
    // gs://
    }
    
    func downloadData() {
        // Storageの指定
        
    }
    
    // スライドしたところに合わせて、再生される動画も調整
    // currentTimeで0.001秒間隔で生成されるCMTimeをずっと読み込む
    // durationで、動画の総再生時間を取得
    // CMTimeGetSecondsで秒単位のfloat型を返す
    func updateSlider(_ currentTime: CMTime) {
        if let currentItem = player?.currentItem {
            let duration = currentItem.duration
            if CMTIME_IS_INVALID(duration) {
                return
            }
            
            let elapsedTimeSecondsFloat = CMTimeGetSeconds(currentTime)
            let totalTimeSecondsFloat = CMTimeGetSeconds(duration)
            
            progressBar.value = Float(elapsedTimeSecondsFloat / totalTimeSecondsFloat)
            print("時間: ", progressBar.value)
        }
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
            
//            let interval = CMTime(seconds: 0.001, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
//            player?.addPeriodicTimeObserver(forInterval:interval, queue: DispatchQueue.main, using: { [weak self] currentTime in
//                self?.updateSlider(currentTime)
//            })
            if player?.currentItem?.status == .readyToPlay {
                progressBar.minimumValue = 0
                progressBar.maximumValue = Float(CMTimeGetSeconds(self.player?.currentItem?.duration ?? CMTimeMake(value: 1, timescale: 1)))
            }
            
            let interval = CMTimeMakeWithSeconds(1, preferredTimescale: Int32(NSEC_PER_SEC))
            // MARK: - observerの追加
            player?.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] elapsedSeconds in
                let elapsedTimeSecondsFloat = CMTimeGetSeconds(elapsedSeconds)
                // Double型
//                let newElapsedTimeSecondsString = String(format: "%.2f", elapsedTimeSecondsFloat)
//                let newElapsedTimeSecondsFloat = Float(newElapsedTimeSecondsString)
                
                let totalTimeSecondsFloat = CMTimeGetSeconds(self?.player?.currentItem?.duration ?? CMTimeMake(value: 1, timescale: 1))
                print("type: ", type(of: elapsedTimeSecondsFloat))
                print(elapsedTimeSecondsFloat, totalTimeSecondsFloat)
//                print(newElapsedTimeSecondsFloat)
//                self?.progressBar.value = newElapsedTimeSecondsFloat! / Float(totalTimeSecondsFloat)
                self?.updateSlider(elapsedSeconds)
            })
                
            // 字幕もupdateする間数
            // self?.updateRemainingText(currentTime)
            //playerのデータを受け取ったとき、勝手に再生されないように、初めからpause()状態になるようにする
            self.player?.pause()
        }
    }
    
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        if sender.isEnabled {
            sender.isEnabled = false
            self.pauseButton.isEnabled = true
        } else {
            sender.isEnabled = true
            self.pauseButton.isEnabled = false
        }
        
        self.player?.play()
    }
    
    @IBAction func pauseButtonAcition(_ sender: UIButton) {
        if sender.isEnabled {
            sender.isEnabled = false
            self.playButton.isEnabled = true
        } else {
            sender.isEnabled = true
            self.playButton.isEnabled = true
        }
        
        self.player?.pause()
    }
    
}
