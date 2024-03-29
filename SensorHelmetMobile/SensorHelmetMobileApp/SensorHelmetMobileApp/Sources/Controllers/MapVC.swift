//
//  MapVC.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/04.
//

import UIKit
import MapKit
import CoreLocation
import CoreLocationUI
import FirebaseFirestore

// Apple Mapを用いた経路探索と現在位置の取得
// TODO: Helmetの場所にある程度近づけると、Helmetのannotationを消し、避難所のannotationを立てる
// MARK: - ⚠️maps short session requested but session sharing is not enabledエラーを修正中
// MARK: - ✍️実装中: 緯度と経度を用いたreverseGeocodeLocationで、住所名を持ってくる

// TODO: 1. 最初から、helmetがある目的地までのとこを表示
// TODO: 2. ヘルメットを装着していない状態なら、避難所までの経路は表示されないように
// TODO: 3 - 1. ヘルメット解除する場合を想定して、destinationLocationをcurrentLocationに変える作業をする
// TODO: 3 - 2. これに関しては、ずっと位置情報をupdateするのではなく、解除ボタンを押したときだけ、destinationLocationをfetchする作業をする
// TODO: 3 - 3. どうせ、ヘルメットを装着しているのであれば、Firestoreに格納される経度と緯度は、現在地にfetchされるはず

// TODO: 4. ヘルメットユーザ間、または、ヘルメットユーザと官公庁の間の情報共有のために、情報発信できる入力フォマットも作成する
// TODO: 4 - 1. 仕様としては、入力したものはfirebaseのfirestoreのデータベース上に情報を格納すること

// MARK: Variables and Life Cycle
final class MapVC: UIViewController {
    
    private var mapView: MKMapView = MKMapView()
    private var timer: Timer?
    
    deinit {
      self.timer?.invalidate()
      self.timer = nil
    }
    
    // Firestoreから受け取る
    // MARK: 現在の位置情報を受け取るための変数を定義
    var currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    var destinationLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    var shelterLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    // 災害地の位置
    var disasterLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    // target
    var targetLocationCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    var locations: [CLLocation] = []
    // geoCodingを行うからここで定義
    let geoCoder = CLGeocoder()
    // MARK: - 正直localeのコードをJapanにしなくていいけど、localeの定義を行う
    // GeoCodingを行うとき、使うつもり
    let locale = Locale(identifier: "ja_JP")
    // 最初に目的地までの経路を表示したか否かのFlag
    var didShowRouteToDestination: Bool = false
    // navigateRouteBtnを押したか否かのFlag
    var didTapNavigateButton: Bool = false
    // cancel Buttonを押したか否かのFlag
    var didTapCancelNavigateButton: Bool = false
    // helmetを装着したか
    var didGetHelmet: Bool = false
    // helmetを解除したか
    var didTakeOffHelmet: Bool = false
    // 初期の設定を表示したかどうか
    var didShowFirstAnnotaionAndRegion: Bool = false
    // annotation pin番後別にrouteの色を変えたい
    var annotationViewPinNumber = 0
    // routeのoverlayを変えたかどうか
    var willChangeOverlay: Bool = false
    // targetDestinationをcurrentのとこに既に設定したかどうかのBool
    var didResetHelmetLocation: Bool = false
    // Disasterのモデルを渡す
    var disaster: DisasterModel?
    
    // MARK: - 複数のhelmetユーザの位置を表示するためには、InfoModelを格納するlistが必修
    // MARK: - HomeViewでただ、持ってくるつもり
    var helmetSensorData: [InfoModel] = []
    
    // 前の位置記録を保存
    var previousCoordinate: CLLocationCoordinate2D?
    // 移動先の位置記録を保存
    var followCoordinate: CLLocationCoordinate2D?
    
    private let loadingView: LoadingView = {
        let view = LoadingView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // 初期設定として、loadingをtrueに
        view.isLoading = true
        return view
    }()
    
    // リアルタイムな現在位置情報をmanageするための変数
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        return manager
    }()
    
    // Segment Controllerを実装(徒歩, 車, 電車等の移動)
    lazy var transportationSegmentedController: UISegmentedControl = {
        let walkImage = UIImage(systemName: "figure.walk")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        let carImage = UIImage(systemName: "car.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        // MARK: - 公共交通機関のcaseは消す予定
//        let publicTransImage = UIImage(systemName: "tram.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        let items: [UIImage] = [walkImage!, carImage!]
        let segmentedController = UISegmentedControl(items: items)
        // MARK: - それぞれのImageをTapしたときのActionはSegmentedControllerのAddTargetで行う
        segmentedController.addTarget(nil, action: #selector(didChangeValue(segment:)), for: .valueChanged)
        // default Indexの設定
        segmentedController.selectedSegmentIndex = 0
        segmentedController.translatesAutoresizingMaskIntoConstraints = false
        return segmentedController
    }()
    
    // 経路までのnavigatorのButtonを表示
    lazy var showRouteButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.buttonSize = .medium
        config.baseBackgroundColor = UIColor.white
        config.baseForegroundColor = UIColor.systemBlue
        config.imagePlacement = NSDirectionalRectEdge.trailing
        // buttonのimageをwithConfigurationと同時に作らないと、buttonの中にimage部分の枠が含まれてしまう
        config.image = UIImage(systemName: "arrow.uturn.left.circle.fill",
                               withConfiguration: UIImage.SymbolConfiguration(scale: .large))
        config.imagePadding = 3
        config.contentInsets = NSDirectionalEdgeInsets.init(top: 10, leading: 10, bottom: 10, trailing: 3)
        config.cornerStyle = .capsule
        config.titleAlignment = .center
        config.attributedTitle = AttributedString("経路に戻る", attributes: AttributeContainer([
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .medium)]))
        button.addTarget(nil, action: #selector(showRouteButtonAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration = config
        button.layer.shadowOpacity = 0.4
        button.layer.shadowRadius = 20
        button.layer.shadowOffset = CGSize(width: 4, height: 10)
        button.layer.shadowColor = UIColor.black.cgColor
        return button
    }()
    
    //MARK: - distanceLabelの上にクリックした住所を表示したい
    lazy var addressLabel: UILabel = {
        let label = UILabel()
        label.text = "住所を表示"
        //住所の場合は、fontを濃くする
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.systemGray3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var distanceLabel: UILabel = {
        let label = UILabel()
        label.text = "距離を表示"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.systemGray3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var expectedTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "所要時間を表示"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.systemGray3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // サーバ側にメッセージを送信するボタン
    lazy var sendMessageToServerButton: UIButton = {
        let button = UIButton()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 45, weight: .medium)
        let image = UIImage(
            systemName: "paperplane.circle.fill",
            withConfiguration: imageConfig
        )?.withTintColor(
            .systemGreen.withAlphaComponent(0.7),
            renderingMode: .alwaysOriginal
        )
        button.setImage(image, for: .normal)
        button.addTarget(nil, action: #selector(sendMessageButtonAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
//        button.layer.shadowOpacity = 0.4
//        button.layer.shadowRadius = 20
//        button.layer.shadowOffset = CGSize(width: 4, height: 10)
//        button.layer.shadowColor = UIColor.black.cgColor
        return button
    }()
    
    lazy var helmetNoticeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor(rgb: 0xF57C00)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var getHelmetButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.buttonSize = .large
        config.baseBackgroundColor = UIColor.clear
//        config.baseBackgroundColor = UIColor(rgb: 0x06C755).withAlphaComponent(0.5)
        config.baseForegroundColor = UIColor.white
        config.imagePlacement = NSDirectionalRectEdge.leading
        // Imageを再設定して、buttonに適用する
        let customImage = UIImage(named: "helmetBasic.png")
        let newImageRect = CGRect(x: 0, y: 0, width: 30, height: 30)
        UIGraphicsBeginImageContext(CGSize(width: 30, height: 30))
        customImage?.draw(in: newImageRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysOriginal).withTintColor(UIColor(rgb: 0xF57C00))
        UIGraphicsEndImageContext()
        config.image = newImage!
        config.imagePadding = 10
        config.contentInsets = NSDirectionalEdgeInsets.init(top: 10, leading: 0, bottom: 10, trailing: 10)
        config.attributedTitle = AttributedString("ヘルメットを装着", attributes: AttributeContainer([
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .medium), NSAttributedString.Key.foregroundColor: UIColor(rgb: 0x06C755).withAlphaComponent(0.85)]))
        //NSAttributedString.Key.foregroundColor: UIColor.whiteをまたすると、もっと白くなってしまう
        config.titleAlignment = .center
        //config.cornerStyle = .medium
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(nil, action: #selector(helmetButtonAction), for: .touchUpInside)
        // GradientsのBorderを与える
        config.background.cornerRadius = GradientConstants.cornerRadius
        button.configuration = config
        //button.layer.cornerRadius = GradientConstants.cornerRadius
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    lazy var takeOffHelmetButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.buttonSize = .large
        config.baseBackgroundColor = UIColor.white
        config.baseForegroundColor = UIColor.systemGray2
        config.imagePlacement = NSDirectionalRectEdge.leading
        config.image = UIImage(systemName: "power.circle.fill",
                               withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(UIColor.systemRed.withAlphaComponent(0.7), renderingMode: .alwaysOriginal)
        config.imagePadding = 10
        config.contentInsets = NSDirectionalEdgeInsets.init(top: 10, leading: 0, bottom: 10, trailing: 10)
        config.background.strokeColor = UIColor.systemRed.withAlphaComponent(0.7)
        config.background.strokeWidth = 3
        config.cornerStyle = .medium
        config.attributedTitle = AttributedString("ヘルメット解除", attributes: AttributeContainer([
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .medium)]))
        config.titleAlignment = .center
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(nil, action: #selector(takeOffHelmetButtonAction), for: .touchUpInside)
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    //現在の位置を中央にする
    lazy var locationButton: CLLocationButton = {
        let button = CLLocationButton()
        let buttonRect = CGRect(x: 0, y: 0, width: 50, height: 50)
        button.icon = .arrowOutline
        button.tintColor = UIColor.systemBlue
        button.backgroundColor = UIColor.white
        button.frame = buttonRect
        button.cornerRadius = button.frame.width / 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(nil, action: #selector(moveToCurrentLocation), for: .touchUpInside)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
        getLocationUsagePermission()
//        view.addSubview(dismissButton)
//        view.addSubview(cancelNavitageRouteButton)
        view.addSubview(transportationSegmentedController)
        view.addSubview(addressLabel)
        view.addSubview(distanceLabel)
        view.addSubview(expectedTimeLabel)
        view.addSubview(sendMessageToServerButton)
        view.addSubview(helmetNoticeLabel)
        view.addSubview(getHelmetButton)
        view.addSubview(takeOffHelmetButton)
        //setDismissBtnConstraints()
//        setCancelNavigateBtnConstraints()
        setSegmentedControllerConstraints()
        //self.didChangeValue(segment: self.transportationSegmentedController)
        setAddressLabelConstraints()
        setDistanceLabelConstraints()
        setExpectedTimeLabelConstraints()
        setSendMessageButtonConstraints()
        setHelmetNoticeLabelConstraints()
        setGetHelmetButtonConstraints()
        setTakeOffHelmetButtonConstraints()
        self.getHelmetButton.isHidden = true
        self.takeOffHelmetButton.isHidden = true
//        removeGetHelmetButtonConstraints()
        mapView.frame = view.bounds
        mapView.showsUserLocation = true
        // 交通情報の表示（リアルタイムの混雑状況）
        mapView.showsTraffic = true
        
        // mapViewにCustomAnnotationViewを登録
        mapView.register(
            CustomAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: CustomAnnotationView.identifier
        )
        mapView.addSubview(locationButton)
        setLocationButtonConstraints()
        mapView.addSubview(showRouteButton)
        setShowRouteBtnConstraints()
        // mapView.bringSubviewToFront(locationButton)
        mapView.setUserTrackingMode(.follow, animated: true)
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        // addMapViewTapGesture()
        view.addSubview(mapView)
        // mapViewの上にButtonを表示させる方法 (AppleのHIGに望ましくない)
        // view.bringSubviewToFront(dismissButton)
        setMapViewConstraints()
        
        self.view.addSubview(loadingView)
        setLoadingViewConstraints()
        self.view.isUserInteractionEnabled = false
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        self.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(false, animated: false)
//        setNavigationBar()
//        self.loadViewIfNeeded()
//    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.locationManager.stopUpdatingLocation()
    }
}

// MARK: - Logic and Function
// ここにコードを再分配すること
private extension MapVC {
    private func setNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        self.navigationItem.title = "Map View"
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
    
    // Buttonのborderをanimateさせる
    func animateBorderGradation() {
        // 1. BorderLineだけに色を入れるため、CAShapeLayerインスタンスを生成
        let shape = CAShapeLayer()
        shape.path = UIBezierPath(
            roundedRect: self.getHelmetButton.bounds.insetBy(dx: GradientConstants.cornerWidth, dy: GradientConstants.cornerWidth),
            cornerRadius: self.getHelmetButton.configuration?.background.cornerRadius ?? 0.8
        ).cgPath
        
        shape.lineWidth = GradientConstants.cornerWidth
        shape.cornerRadius = GradientConstants.cornerRadius
        shape.strokeColor = UIColor.white.cgColor
        shape.fillColor = UIColor.clear.cgColor
        
        // 2. conic グラデーション効果を与えるため、CAGradientLayerインスタンスを生成した上に、maskにCAShapeLayerを代入
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: self.getHelmetButton.bounds.width, height: self.getHelmetButton.bounds.height)
        gradient.type = .conic
        gradient.colors = BorderColor.gradientColors.map(\.cgColor) as [Any]
        gradient.locations = GradientConstants.gradientLocation
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.mask = shape
        gradient.cornerRadius = GradientConstants.cornerRadius
        self.getHelmetButton.layer.addSublayer(gradient)
      
        // 3. 毎0.2秒ごとに、まるでCirculat queueのように色を変えながら動くように実装
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            gradient.removeAnimation(forKey: "myAnimation")
            let previous = BorderColor.gradientColors.map(\.cgColor)
            let last = BorderColor.gradientColors.removeLast()
            BorderColor.gradientColors.insert(last, at: 0)
            let lastColors = BorderColor.gradientColors.map(\.cgColor)
            let colorsAnimation = CABasicAnimation(keyPath: "colors")
            colorsAnimation.fromValue = previous
            colorsAnimation.toValue = lastColors
            colorsAnimation.repeatCount = 1
            colorsAnimation.duration = 0.2
            colorsAnimation.isRemovedOnCompletion = false
            colorsAnimation.fillMode = .both
            gradient.add(colorsAnimation, forKey: "myAnimation")
        }
    }
    
    // 最初の地域設定
    func setCenterRegion(center: CLLocationCoordinate2D, target: CLLocationCoordinate2D) {
        // Region(地域)を設定
        let coordinate = CLLocationCoordinate2DMake((center.latitude + target.latitude) / 2, (center.longitude + target.longitude) / 2)
        // Mapで表示した地域のHeightとwidthを設定
        
        var latitudeDegree: CLLocationDegrees?
        var longitudeDegree: CLLocationDegrees?
        
        if center.distance(to: target) > 100 && center.distance(to: target) <= 10000 {
            latitudeDegree = 0.1
            longitudeDegree = 0.1
        } else if center.distance(to: target) <= 100 {
            latitudeDegree = 0.007
            longitudeDegree = 0.007
        } else if center.distance(to: target) >= 35000 {
            latitudeDegree = 0.45
            longitudeDegree = 0.45
        } else {
            latitudeDegree = 0.35
            longitudeDegree = 0.35
        }
        
        let span = MKCoordinateSpan(latitudeDelta: latitudeDegree!, longitudeDelta: longitudeDegree!)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        mapView.setRegion(region, animated: true)
    }
    
    func getDistance(from curLocate: CLLocationCoordinate2D, to targetLocate: CLLocationCoordinate2D) {
        let rawDistance = curLocate.distance(to: targetLocate)
        print("distance: \(rawDistance)")
        
        // TODO: 🔥100m以内であれば、Helmetの装着したかを表示し、ボタンを押したら、避難所への経路を表示
        if rawDistance <= 100 {
            let distance = String(format: "%.1f", rawDistance)
            self.distanceLabel.text = "目的地までの距離: \(distance)m"
            self.helmetNoticeLabel.text = "近くにヘルメットがあります"
            
            if getHelmetButton.isHidden {
                self.getHelmetButton.isHidden = false
                DispatchQueue.main.async {
                    self.animateBorderGradation()
                }
            }
        } else {
            self.distanceLabel.text = curLocate.distanceText(to: targetLocate)
            
            if didGetHelmet {
                self.helmetNoticeLabel.text = "ヘルメット装着中"
                self.helmetNoticeLabel.textColor = UIColor(rgb: 0x4CAF50)
            } else {
                self.helmetNoticeLabel.text = ""
                self.helmetNoticeLabel.textColor = UIColor(rgb: 0xF57C00)
            }
            
            if !getHelmetButton.isHidden {
                self.getHelmetButton.isHidden = true
            }
        }
        
        self.distanceLabel.textColor = UIColor.black
        self.distanceLabel.font = .systemFont(ofSize: 17, weight: .heavy)
    }
    
    func getLocationUsagePermission() {
        // アプリの使用中のみ位置情報サービスの利用許可を求める
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    // Geocoderで住所名を取得するメソッド
    func getPlaceName(target location: CLLocation, completion: @escaping( (String?) -> () )) {
        geoCoder.reverseGeocodeLocation(location, preferredLocale: locale) { placemarks, error in
            if let targetPlacemark = placemarks?.first {
                // 住所
                var placeName = ""
                if let todohuken = targetPlacemark.administrativeArea {
                    placeName += todohuken
                }
                
                if let shikutyoson = targetPlacemark.locality {
                    placeName += shikutyoson
                }
                
                if let withChome = targetPlacemark.thoroughfare {
                    placeName += withChome
                } else if let withOutChome = targetPlacemark.subLocality {
                    placeName += withOutChome
                }
                
                if let banchi = targetPlacemark.subThoroughfare {
                    placeName += banchi
                }
                
                completion(placeName)
            } else if let error = error {
                print(error.localizedDescription)
                completion(nil)
            } else {
                completion(nil)
            }
        }
    }
    
    //TODO: 🔥最初に現在地と目的地のピンを立てるだけ
    func showAnnotations(curLocate: CLLocationCoordinate2D, targetLocate: CLLocationCoordinate2D) {
        let sourcePlacemark = MKPlacemark(coordinate: curLocate, addressDictionary: nil)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        
        let destinationPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: destinationLocation.latitude, longitude: destinationLocation.longitude), addressDictionary: nil)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        let directionsRequest = MKDirections.Request()
        // 移動手段の設定
        // default: 徒歩
        directionsRequest.transportType = .walking
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destinationMapItem
        let direction = MKDirections(request: directionsRequest)
        
        // ずっと計算して経路を表示するやつ
        direction.calculate { [weak self] response, error in
            guard let response = response, let route = response.routes.first else {
                return
            }
            
            if self!.didTapCancelNavigateButton {
                direction.cancel()
            }
            
            DispatchQueue.main.async {
                self?.mapView.addOverlay(route.polyline, level: .aboveRoads)
            }
        }
    }
    
    func calculateTime(curLocate: CLLocationCoordinate2D, targetLocate: CLLocationCoordinate2D) {
        // 計算中でなかったら、計算をstart
        print("timeを計算")
        let sourcePlacemark = MKPlacemark(coordinate: curLocate, addressDictionary: nil)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        
        let destinationPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: targetLocate.latitude, longitude: targetLocate.longitude), addressDictionary: nil)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let directionsRequest = MKDirections.Request()
        directionsRequest.transportType = .walking
        // 出発地
        directionsRequest.source = sourceMapItem
        // 目的地
        directionsRequest.destination = destinationMapItem
        // 出発地から目的地までのDirection Requestを送る
        let direction = MKDirections(request: directionsRequest)
        direction.calculate { [weak self] response, error in
            // routeをひとつにするか複数にするかをここで設定
            guard let response = response, let route = response.routes.first else {
                return
            }
            
            let timeFormatString = self?.formatTime(route.expectedTravelTime)
            print(timeFormatString!)
            DispatchQueue.main.async {
                self?.expectedTimeLabel.text = "予想所要時間: " + (timeFormatString ?? "")
                self?.expectedTimeLabel.textColor = UIColor.black
                self?.expectedTimeLabel.font = .systemFont(ofSize: 17, weight: .heavy)
            }
        }
        direction.cancel()
    }
    
    // TODO: リアルタイムな移動経路の計算
    // 現在位置からtarget位置までの経路表示
    // 移動手段を変えるたびにこの間数を呼び出すので、前に描かれたoverlayのremoveの作業が必須
    func calculateDirection(curLocate: CLLocationCoordinate2D, targetLocate: CLLocationCoordinate2D, transportIndex: Int) {
        // 現在位置から目的地までの方向を計算する
        let sourcePlacemark = MKPlacemark(coordinate: curLocate, addressDictionary: nil)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: targetLocate.latitude, longitude: targetLocate.longitude), addressDictionary: nil)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        let directionsRequest = MKDirections.Request()
        // MARK: - 到着予想時間だけが変換される
        if transportIndex == 0 {
            directionsRequest.transportType = .walking
        } else if transportIndex == 1 {
            directionsRequest.transportType = .automobile
        } else if transportIndex == 2 {
            //　電車やバスなどの交通手段は反映されなかった
            directionsRequest.transportType = .transit
        }
        // 出発地
        directionsRequest.source = sourceMapItem
        // 目的地
        directionsRequest.destination = destinationMapItem
        // 出発地から目的地までのDirection Requestを送る
        let direction = MKDirections(request: directionsRequest)
        let overlays = mapView.overlays
        
        // 計算中でなかったら、計算をstart
        direction.calculate { [weak self] response, error in
            // routeをひとつにするか複数にするかをここで設定
            guard let response = response, let route = response.routes.first else {
                return
            }
            
            let timeFormatString = self?.formatTime(route.expectedTravelTime)
            print("時間: \(timeFormatString ?? "" )")
            DispatchQueue.main.async {
                self?.expectedTimeLabel.text = "予想所要時間: " + (timeFormatString ?? "")
                self?.expectedTimeLabel.textColor = UIColor.black
                self?.expectedTimeLabel.font = .systemFont(ofSize: 17, weight: .heavy)
                
                if let firstOverlay = overlays.first {
                    self?.mapView.removeOverlay(firstOverlay)
                    self?.mapView.addOverlay(route.polyline, level: .aboveRoads)
                    // 現在位置と目的地までの経路を表示するとき、animation効果を与えるかどうかの設定
                    self?.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                    // MARK: - routeを交換するより、removeの後addした方が処理が早かった
                    //self?.mapView.exchangeOverlay(firstOverlay, with: route.polyline)
                } else {
                    self?.mapView.addOverlay(route.polyline, level: .aboveRoads)
                    self?.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                }
                // MARK: - loadingをfalseに
                self?.loadingView.isLoading = false
                // MARK: - viewのuseractionをtrueに
                self?.view.isUserInteractionEnabled = true
            }
            // 計算が終わった後の処理
            print("計算終わり")
        }
    }
    
    // 前の移動経路を保存して、線をつなぐ
    func connectOverlayWithPreviousCoordinate(coordinate: CLLocationCoordinate2D) {
        if let previousCoordinate = self.previousCoordinate {
            var points: [CLLocationCoordinate2D] = []
            let previousPoint = CLLocationCoordinate2DMake(previousCoordinate.latitude, previousCoordinate.longitude)
            let currentPoint: CLLocationCoordinate2D = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude)
            
            points.append(previousPoint)
            points.append(currentPoint)
            let lineDraw = MKPolyline(coordinates: points, count:points.count)
            
            if self.mapView.overlays.contains(where: {$0 as! NSObject == lineDraw}) {
                self.mapView.removeOverlay(lineDraw)
            } else {
                self.mapView.addOverlay(lineDraw)
            }
        }
        
        self.previousCoordinate = coordinate
    }
    
    // Custom Pinを立てる
    func setAnnotation(pinTag: Int, latitudeValue: CLLocationDegrees, longitudeValue: CLLocationDegrees, delta span :Double) {
        
        // var mapAnnotations = self.mapView.annotations
        let pin = CustomAnnotation(pinImageTag: pinTag, coordinate: CLLocationCoordinate2D(latitude: latitudeValue, longitude: longitudeValue))
        // 災害があるなら
        if let disaster = self.disaster {
            let disasterPin = CustomAnnotation(pinImageTag: 2, coordinate: CLLocationCoordinate2D(latitude: Double(disaster.disasterLatitude!)!, longitude: Double(disaster.disasterLongitude!)!))
            
            print("disaster has!")
            // Annotationの除去と追加を同時にすることで、目的地の更新が自然的となる
            DispatchQueue.main.async {
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.addAnnotation(pin)
                self.mapView.addAnnotation(disasterPin)
            }
        } else {
            // Annotationの除去と追加を同時にすることで、目的地の更新が自然的となる
            DispatchQueue.main.async {
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.addAnnotation(pin)
            }
        }
    }
    
    //災害があるときのDisaster Annotation
    func setDisasterAnnotation(pinTag: Int, latitudeValue: CLLocationDegrees, longitudeValue: CLLocationDegrees, delta span :Double) {
        guard let disaster = self.disaster else {
            return
        }
        
        let disasterPin = CustomAnnotation(pinImageTag: 2, coordinate: CLLocationCoordinate2D(latitude: Double(disaster.disasterLatitude!)!, longitude: Double(disaster.disasterLongitude!)!))
        
        DispatchQueue.main.async {
            self.mapView.addAnnotation(disasterPin)
        }
    }
    
    
    func showRequestLocationServiceAlert() -> UIAlertController {
        let requestLocationServiceAlert = UIAlertController(title: "位置情報利用", message: "位置サービスを利用できません。デバイスの '設定 -> 個人情報保護'で位置サービスを有効にしてください。", preferredStyle: .alert)
        let goSetting = UIAlertAction(title: "設定に移動", style: .destructive) { _ in
            if let appSetting = URL(string: UIApplication.openSettingsURLString){
                UIApplication.shared.open(appSetting)
            }
        }
              
        let cancel = UIAlertAction(title: "キャンセル", style: .default)
        requestLocationServiceAlert.addAction(cancel)
        requestLocationServiceAlert.addAction(goSetting)
        
        return requestLocationServiceAlert
    }
    
    func showHelmetUserInfoSheet() {
        let placeName = addressLabel.text
        var removedPlaceName = ""
        
        if let originalName = placeName {
            // 前から4文字消す
            removedPlaceName = String(originalName.dropFirst(4))
        } else {
            removedPlaceName = ""
        }
        
        // MARK: - sheetPresantationControllerに載せたいVCをここで指定
        // MARK: - connectStateにdidGetHelmetを引き渡すつもり
        let controller = HelmetInfoModalViewController.instantiate(with: "helmet1", placeName: removedPlaceName, connectState: true)
        controller.view.backgroundColor = UIColor.white

        // MARK: - navigationBarをcustomするため
        // navigationControllerにsheetPresentationControllerを導入すればdetentsも設定した通り、表示できた
        let navigationController = UINavigationController(rootViewController: controller)
        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [
                .custom(resolver: { context in
                    0.25 * context.maximumDetentValue
                }),
                .medium()
            ]
//            sheet.largestUndimmedDetentIdentifier = .medium
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.preferredCornerRadius = 24
        }
        
        self.present(navigationController, animated: true, completion: nil)
    }
    
//    func addMapViewTapGesture() {
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapMapView(_ :)))
//        mapView.addGestureRecognizer(tapGesture)
//    }
    
    func setMapViewConstraints() {
        // safeArealayoutのtopAnchorは、navigationBarの領域を除外した一番の上のtopAnchorを指す
        mapView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive =  true
        mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        // MARK: - MapViewのbottomAnchorのconstraintsをsegmentedControllerに合わせるつもり
        mapView.bottomAnchor.constraint(equalTo: self.transportationSegmentedController.topAnchor, constant: -10).isActive = true
    }
    
    func setLocationButtonConstraints() {
        self.locationButton.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor, constant: -30).isActive = true
        self.locationButton.rightAnchor.constraint(equalTo: self.mapView.rightAnchor, constant: -6).isActive = true
    }
    
    // 経路に戻るボタンをMapViewの中に入れる予定
    func setShowRouteBtnConstraints() {
        self.showRouteButton.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor, constant: -15).isActive = true
        self.showRouteButton.leadingAnchor.constraint(equalTo: self.mapView.leadingAnchor, constant: 120).isActive = true
        self.showRouteButton.trailingAnchor.constraint(equalTo: self.mapView.trailingAnchor, constant: -120).isActive = true
    }
    
    // MARK: - SegmentedControllerのConstraintsの設定
    func setSegmentedControllerConstraints() {
        self.transportationSegmentedController.bottomAnchor.constraint(equalTo: self.addressLabel.topAnchor, constant: -10).isActive = true
        self.transportationSegmentedController.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20).isActive = true
        self.transportationSegmentedController.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20).isActive = true
    }
    
    // MARK: - addressLabelのConstraintsをSegmentedControllerに合わせる予定
    func setAddressLabelConstraints() {
        self.addressLabel.bottomAnchor.constraint(equalTo: self.distanceLabel.topAnchor, constant: -5).isActive = true
        self.addressLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        self.addressLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
    }
    
    func setDistanceLabelConstraints() {
        self.distanceLabel.topAnchor.constraint(equalTo: self.addressLabel.bottomAnchor, constant: 5).isActive = true
        self.distanceLabel.bottomAnchor.constraint(equalTo: self.expectedTimeLabel.topAnchor, constant: -5).isActive = true
        self.distanceLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        self.distanceLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
    }
    
    func setExpectedTimeLabelConstraints() {
        self.expectedTimeLabel.topAnchor.constraint(equalTo: self.distanceLabel.bottomAnchor, constant: 5).isActive = true
        self.expectedTimeLabel.bottomAnchor.constraint(equalTo: self.helmetNoticeLabel.topAnchor, constant: -5).isActive = true
        self.expectedTimeLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        self.expectedTimeLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
    }
    
    // MARK: - サーバ側にメッセージを送信するボタン
    func setSendMessageButtonConstraints() {
        self.sendMessageToServerButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -23).isActive = true
        self.sendMessageToServerButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -23).isActive = true
    }
    
    func setHelmetNoticeLabelConstraints() {
        self.helmetNoticeLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.helmetNoticeLabel.topAnchor.constraint(equalTo: self.expectedTimeLabel.bottomAnchor, constant: 5).isActive = true
        self.helmetNoticeLabel.bottomAnchor.constraint(equalTo: self.getHelmetButton.topAnchor, constant: -5).isActive = true
    }
    
    func setGetHelmetButtonConstraints() {
        self.getHelmetButton.topAnchor.constraint(equalTo: self.helmetNoticeLabel.bottomAnchor, constant: 5).isActive = true
        self.getHelmetButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        self.getHelmetButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 80).isActive = true
        self.getHelmetButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -80).isActive = true
    }
    
    func setTakeOffHelmetButtonConstraints() {
        self.takeOffHelmetButton.topAnchor.constraint(equalTo: self.helmetNoticeLabel.bottomAnchor, constant: 5).isActive = true
        self.takeOffHelmetButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        self.takeOffHelmetButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 80).isActive = true
        self.takeOffHelmetButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -80).isActive = true
    }
    
    func setLoadingViewConstraints() {
        NSLayoutConstraint.activate([
            self.loadingView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.loadingView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }
    
    // 所要時間をString型に変換するメソッド
    func formatTime(_ time:Double) -> String {
         switch time {
         case -1 :
             return "経路を検索中..."
         case 0..<60 : // 1分以下
             return String(time) + "秒"
         case 0..<3600 : // 1時間以下
             return String(format: "%.0f", time/60) + "分"
         default: // 1時間以上
             let hour = Int(time/3600)
             let minutes = (time - Double(hour * 3600))/60
             return String(hour) + "時間" + String(format: "%.0f", minutes)  + "分"
        }
    }
    
//    @objc func didTapMapView(_ gesture: UITapGestureRecognizer) {
//        // MARK: - 特定のViewをgestureから除外する方法
//        let touchPoint = gesture.location(in: mapView)
//        
//        // LocationButtonとshowRouteButton以外の部分をtapした時、実行
//        if !locationButton.frame.contains(touchPoint) && !showRouteButton.frame.contains(touchPoint) {
//            print("Tap mapview")
//        }
//        
////        let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
////        print("タップされた座標: \(locationOnMap.latitude), \(locationOnMap.longitude)")
//    }
    
    @objc func dismissButtonAction() {
        self.dismiss(animated: true)
        self.locationManager.stopUpdatingLocation()
    }
    
    @objc func dismissBarButtonAction() {
        self.dismiss(animated: true)
        self.locationManager.stopUpdatingLocation()
    }
    
    @objc func showRouteButtonAction() {
        if didGetHelmet {
            targetLocationCoordinate = shelterLocation
        } else {
            targetLocationCoordinate = destinationLocation
        }
        
        setCenterRegion(center: currentLocation, target: targetLocationCoordinate)
    }
    
    // MARK: - Segmented ControllerのimageをAction化する
    @objc func didChangeValue(segment: UISegmentedControl) {
        // 移動手段を変えるたびに予想時間とルートを再計算する必要があるので、calculateDirectionを呼び出す作業にした
        self.loadingView.isLoading = true
        self.view.isUserInteractionEnabled = false
        
        calculateDirection(curLocate: self.currentLocation, targetLocate: self.targetLocationCoordinate, transportIndex: segment.selectedSegmentIndex)
        if segment.selectedSegmentIndex == 0 {
            print("walk")
        } else if segment.selectedSegmentIndex == 1 {
            print("Car")
        }
    }
    
    @objc func helmetButtonAction() {
        didGetHelmet = true
        //willChangeOverlay = true
        didTakeOffHelmet = false
        print("Helmet button tap!!")
        let overlays = mapView.overlays
        if !overlays.isEmpty {
            DispatchQueue.main.async {
                self.mapView.removeOverlays(overlays)
            }
        }
        
        // 避難所への経路に入れ替える
        let requestPopVC = HelmetSuccessPopupVC.instantiate(with: didGetHelmet)
        
        requestPopVC.modalPresentationStyle = .overCurrentContext
        requestPopVC.modalTransitionStyle = .crossDissolve
        self.present(requestPopVC, animated: true) {
            // 設定した時間後、処理を行う
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if requestPopVC.presentViewState {
                    self.dismiss(animated: true) {
                        // ここで、request thank you Pageを表示したあと、設置リクエストボタンの設定を帰る
                        print("Success Okay!")
                        self.getHelmetButton.isHidden = true
                        // MARK: targetLocationを避難所のとこに変える
                        self.targetLocationCoordinate = self.shelterLocation
                        
                        let shelter = CLLocation(latitude: self.shelterLocation.latitude, longitude: self.shelterLocation.longitude)
                        self.setAnnotation(pinTag: self.annotationViewPinNumber, latitudeValue: self.shelterLocation.latitude, longitudeValue: self.shelterLocation.longitude, delta: 0.01)
                        
                        self.getPlaceName(target: shelter) { placename in
                            self.addressLabel.text = "住所: \(placename ?? "")"
                            // Placeを取得してから、fontをheavyに変える作業をここで行う。また、textColorをblackに
                            self.addressLabel.textColor = UIColor.black
                            self.addressLabel.font = .systemFont(ofSize: 17, weight: .heavy)
                        }
                        
                        self.getDistance(from: self.currentLocation, to: self.shelterLocation)
                        self.calculateDirection(curLocate: self.currentLocation, targetLocate: self.shelterLocation, transportIndex: self.transportationSegmentedController.selectedSegmentIndex)
                        self.takeOffHelmetButton.isHidden = false
                        self.setCenterRegion(center: self.currentLocation, target: self.shelterLocation)
                    }
                } else {
                    // ここで、request thank you Pageを表示したあと、設置リクエストボタンの設定を帰る
                    print("Success Okay!")
                    self.getHelmetButton.isHidden = true
                    // MARK: targetLocationを避難所のとこに変える
                    self.targetLocationCoordinate = self.shelterLocation
                    
                    let shelter = CLLocation(latitude: self.shelterLocation.latitude, longitude: self.shelterLocation.longitude)
                    self.setAnnotation(pinTag: self.annotationViewPinNumber, latitudeValue: self.shelterLocation.latitude, longitudeValue: self.shelterLocation.longitude, delta: 0.01)
                    
                    self.getPlaceName(target: shelter) { placename in
                        self.addressLabel.text = "住所: \(placename ?? "")"
                        // Placeを取得してから、fontをheavyに変える作業をここで行う。また、textColorをblackに
                        self.addressLabel.textColor = UIColor.black
                        self.addressLabel.font = .systemFont(ofSize: 17, weight: .heavy)
                    }
                    
                    self.getDistance(from: self.currentLocation, to: self.shelterLocation)
                    self.calculateDirection(curLocate: self.currentLocation, targetLocate: self.shelterLocation, transportIndex: self.transportationSegmentedController.selectedSegmentIndex)
                    self.takeOffHelmetButton.isHidden = false
                    self.setCenterRegion(center: self.currentLocation, target: self.shelterLocation)
                }
            }
        }
    }
    
    @objc func takeOffHelmetButtonAction() {
        if didGetHelmet {
            didGetHelmet = false
        }
        
        didTakeOffHelmet = true
        
        if didResetHelmetLocation {
            didResetHelmetLocation = false
        }
        
        let overlays = self.mapView.overlays

        DispatchQueue.main.async {
            if !overlays.isEmpty {
                self.mapView.removeOverlays(overlays)
            }
        }
        
        print("take off helmet!")
        let requestPopVC = HelmetSuccessPopupVC.instantiate(with: didGetHelmet)
        
        requestPopVC.configure(with: didGetHelmet)
        requestPopVC.modalPresentationStyle = .overCurrentContext
        requestPopVC.modalTransitionStyle = .crossDissolve
        self.present(requestPopVC, animated: true) {
            // 設定した時間後、処理を行う
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if requestPopVC.presentViewState {
                    self.dismiss(animated: true) {
                        // ここで、request thank you Pageを表示したあと、設置リクエストボタンの設定を帰る
                        print("Success Okay!")
                        self.getHelmetButton.isHidden = false
                        // MARK: targetLocationを避難所のとこに変える
                        self.targetLocationCoordinate = self.currentLocation
                        
                        // 現在のuserの位置が、ヘルメットを解除した位置になる
                        let helmetLocation = CLLocation(latitude: self.targetLocationCoordinate.latitude, longitude: self.targetLocationCoordinate.longitude)
                        self.setAnnotation(pinTag: self.annotationViewPinNumber, latitudeValue: self.targetLocationCoordinate.latitude, longitudeValue: self.targetLocationCoordinate.longitude, delta: 0.01)
                        
                        self.getPlaceName(target: helmetLocation) { placename in
                            self.addressLabel.text = "住所: \(placename ?? "")"
                            // Placeを取得してから、fontをheavyに変える作業をここで行う。また、textColorをblackに
                            self.addressLabel.textColor = UIColor.black
                            self.addressLabel.font = .systemFont(ofSize: 17, weight: .heavy)
                        }
                        
                        self.getDistance(from: self.currentLocation, to: self.targetLocationCoordinate)
                        self.calculateDirection(curLocate: self.currentLocation, targetLocate: self.targetLocationCoordinate, transportIndex: self.transportationSegmentedController.selectedSegmentIndex)
                        self.takeOffHelmetButton.isHidden = true
                        self.setCenterRegion(center: self.currentLocation, target: self.targetLocationCoordinate)
                    }
                } else {
                    // ここで、request thank you Pageを表示したあと、設置リクエストボタンの設定を帰る
                    print("Success Okay!")
                    self.getHelmetButton.isHidden = false
                    // MARK: targetLocationを避難所のとこに変える
                    self.targetLocationCoordinate = self.destinationLocation
                    
                    // 現在のuserの位置が、ヘルメットを解除した位置になる
                    let helmetLocation = CLLocation(latitude: self.targetLocationCoordinate.latitude, longitude: self.targetLocationCoordinate.longitude)
                    self.setAnnotation(pinTag: self.annotationViewPinNumber, latitudeValue: self.targetLocationCoordinate.latitude, longitudeValue: self.targetLocationCoordinate.longitude, delta: 0.01)
                    
                    self.getPlaceName(target: helmetLocation) { placename in
                        self.addressLabel.text = "住所: \(placename ?? "")"
                        // Placeを取得してから、fontをheavyに変える作業をここで行う。また、textColorをblackに
                        self.addressLabel.textColor = UIColor.black
                        self.addressLabel.font = .systemFont(ofSize: 17, weight: .heavy)
                    }
                    
                    self.getDistance(from: self.currentLocation, to: self.targetLocationCoordinate)
                    self.calculateDirection(curLocate: self.currentLocation, targetLocate: self.targetLocationCoordinate, transportIndex: self.transportationSegmentedController.selectedSegmentIndex)
                    self.takeOffHelmetButton.isHidden = true
                    self.setCenterRegion(center: self.currentLocation, target: self.targetLocationCoordinate)
                }
            }
        }
    }
    
    // MARK: - Navigation Controller のpushメソッドを用いて, 災害が起きた場所からの近くの官公庁リストを表示する
    // MARK: - 災害が起きた場所の英語の名前を渡して, 近くの公共機関のリストをデータベースから追出できるように
    @objc func sendMessageButtonAction() {
        // Firestoreにメッセージを送信する
        print("send message button!")
        let occurPlaceEnglish = disaster?.addressInfo?.localNameEnglish
        let controller = NearbyPublicInstitutionListViewController.instantiate(with: occurPlaceEnglish ?? "")
//        controller.configure(with: occurPlaceEnglish ?? "")
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationCapturesStatusBarAppearance = true
        navigationController.modalPresentationStyle = .fullScreen
//        // fullScreenであるが、1つ前のViewのサイズに合わせてpushされる
//        navigationController?.pushViewController(controller, animated: true)
        // navigation Controllerをpushじゃないpresentで表示させる方法
        self.present(navigationController, animated: true) {
            print("Complete to present Nearby Public Institution List View")
        }
    }
    
    // 現在の位置を真ん中に表示
    @objc func moveToCurrentLocation() {
        print("Move to Current location")
        let region = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpan(latitudeDelta:0.01, longitudeDelta:0.01))
        self.mapView.setRegion(region, animated: true)
    }
}

extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let routePolyline = overlay as? MKPolyline else {
            print("Can't draw polyline of route")
            return MKOverlayRenderer()
        }
        
        let routeRenderer = MKPolylineRenderer(polyline: routePolyline)
        if annotationViewPinNumber == 0 {
            // ヘルメット場所
            routeRenderer.strokeColor = UIColor(red:0.35, green:0.35, blue:1.30, alpha:1.0)
            routeRenderer.lineWidth = 5.0
            routeRenderer.alpha = 1.0
        } else if annotationViewPinNumber == 1 {
            // 避難所
            routeRenderer.strokeColor = UIColor.systemGreen
            routeRenderer.lineWidth = 5.0
            routeRenderer.alpha = 1.0
        }
        
        return routeRenderer
    }
        
    // annotaionViewをtapしたとき、呼び出されるメソッド
    // MARK: - ここで、sheetPresentationControllerをpresentするべき
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // CLLocationとCLLocationCoodinate2Dは、異なるもの
        if let coordinate = view.annotation?.coordinate {
            print("Tapped Annotation!")
            // MARK: - Helmet ユーザの情報を表示するSheetPresentationControllerを表示
            self.showHelmetUserInfoSheet()
            print(coordinate)
            
//            // MARK: - AnnotationViewの右に表示される吹き出しがView上で表示されている場合
//            if !(view.detailCalloutAccessoryView?.isHidden ?? <#default value#>) {
//                
//            } else {
//                // AnnotationViewの吹き出しが表示されていない場合
//            }
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("call out")
    }
    
    // MARK: - Custom Annotation Viewを定義するために実装
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        if annotation is MKUserLocation { return nil }
        guard let annotation = annotation as? CustomAnnotation else {
            return nil
        }
        
        var annotationView = self.mapView.dequeueReusableAnnotationView(withIdentifier: CustomAnnotationView.identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: CustomAnnotationView.identifier)
            annotationView?.canShowCallout = true
            annotationView?.contentMode = .scaleAspectFit
            annotationView?.layoutIfNeeded()
        } else {
            annotationView?.annotation = annotation
            annotationView?.canShowCallout = true
            annotationView?.layoutIfNeeded()
        }
                
        let pinImage: UIImage!
        var size = CGSize()
        var tapTitle = ""
            
        switch annotation.pinImageTag {
        case 0:
            tapTitle = "ヘルメット"
            pinImage = UIImage(named: "helmetBasic")?.withRenderingMode(.alwaysOriginal).withTintColor(UIColor(rgb: 0xF57C00))
            size = CGSize(width: 35, height: 35)
            UIGraphicsBeginImageContext(size)
            // imageのサイズをredrawする
            pinImage.draw(in: CGRect(x: 1.7, y: 0, width: size.width - 4, height: size.height - 4))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            annotationView?.image = resizedImage
        case 1:
            tapTitle = "避難所"
            pinImage = UIImage(systemName: "figure.walk.circle.fill")?.withRenderingMode(.alwaysOriginal).withTintColor(UIColor.systemGreen)
            size = CGSize(width: 40, height: 40)
            UIGraphicsBeginImageContext(size)
            pinImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            annotationView?.image = resizedImage
        case 2:
            // MARK: - 災害が起きた場所にPinを置きたいが、まだ実装不足
            tapTitle = "\(disaster?.disasterType ?? "")発生地"
            pinImage = UIImage(named: "helmetBasic")?.withRenderingMode(.alwaysOriginal).withTintColor(UIColor(rgb: 0xF57C00))
           // pinImage = UIImage(named: "\(disaster?.image ?? "")")
            size = CGSize(width: 40, height: 40)
            UIGraphicsBeginImageContext(size)
            pinImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            annotationView?.image = resizedImage
        default:
            // それ以外は、設定なし
            pinImage = UIImage()
        }
                 
        //ラベルの作成
        let label = UILabel()
        label.text = tapTitle
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.black
        label.isUserInteractionEnabled = true
        annotationView?.detailCalloutAccessoryView = label
        annotationView?.isUserInteractionEnabled = true
        
        if annotation.pinImageTag == 0 {
            annotationView?.backgroundColor = UIColor.white
//            annotationView?.layer.cornerRadius = backGroundView.frame.height / 2
            annotationView?.layer.borderColor = UIColor.systemYellow.cgColor
            annotationView?.layer.borderWidth = 1.5
        } else if annotation.pinImageTag == 1 {
            annotationView?.backgroundColor = UIColor.clear
            annotationView?.backgroundColor = UIColor.white
            annotationView?.layer.borderColor = UIColor.clear.cgColor
            annotationView?.layer.borderColor = UIColor.systemGreen.cgColor
        } else {
            // 災害地
            annotationView?.backgroundColor = UIColor.clear
            annotationView?.backgroundColor = UIColor.white
            annotationView?.layer.borderColor = UIColor.clear.cgColor
            annotationView?.layer.borderColor = UIColor.systemRed.cgColor
        }
        annotationView?.layoutIfNeeded()
        
        return annotationView
    }
}

// MARK: - CLLocationManager
extension MapVC: CLLocationManagerDelegate {
    // ユーザの位置情報を正しく持ってきた場合
    // 位置情報が更新されるたびに、呼び出されるメソッド
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // MARK: Buttonを押さないと経路表示ができないようにする
        if let coordinate = locations.last?.coordinate {
            print("位置情報取得に成功しました")
            print("longitude: ", coordinate.longitude)
            print("latitude: ", coordinate.latitude)
            // 現在位置更新
            currentLocation.longitude = coordinate.longitude
            currentLocation.latitude = coordinate.latitude
            // MARK: - 現在位置のCLLocationの設定
            // let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            lazy var pinNum: Int? = 0
            if didGetHelmet {
                pinNum = 1
                annotationViewPinNumber = 1
                targetLocationCoordinate = shelterLocation
            } else {
                pinNum = 0
                annotationViewPinNumber = 0
                if didTakeOffHelmet {
                    if !didResetHelmetLocation {
                        targetLocationCoordinate = currentLocation
                        didResetHelmetLocation = true
                    }
                } else {
                    targetLocationCoordinate = destinationLocation
                }
            }
            
            // 最初に表示させるとき
            if !didShowFirstAnnotaionAndRegion {
                didShowFirstAnnotaionAndRegion = true
                //CLLocationDegreeからCLLocationに
                let targetLocation = CLLocation(latitude: targetLocationCoordinate.latitude, longitude: targetLocationCoordinate.longitude)
                setCenterRegion(center: coordinate, target: targetLocationCoordinate)
                setAnnotation(pinTag: pinNum!, latitudeValue: targetLocationCoordinate.latitude, longitudeValue: targetLocationCoordinate.longitude, delta: 0.1)
                
                
                // pinTagを2にしなかったため、disaster annotationが追加されなかった
                // 災害に関するannotationを別途に設定する
                // TODO: -> 災害が発生し、消えることも効率的に管理するため   
//                //disasterはあるときのAnnotation
//                if self.disaster != nil {
//                    setDisasterAnnotation(pinTag: 3, latitudeValue: <#T##CLLocationDegrees#>, longitudeValue: <#T##CLLocationDegrees#>, delta: <#T##Double#>)
//                }
                
                DispatchQueue.main.async {
                    self.getPlaceName(target: targetLocation) { placeName in
                        self.addressLabel.text = "住所: \(placeName ?? "")"
                        // Placeを取得してから、fontをheavyに変える作業をここで行う。また、textColorをblackに
                        self.addressLabel.textColor = UIColor.black
                        self.addressLabel.font = .systemFont(ofSize: 17, weight: .heavy)
                    }

                    self.calculateDirection(curLocate: self.currentLocation, targetLocate: self.targetLocationCoordinate, transportIndex: self.transportationSegmentedController.selectedSegmentIndex)
                    self.getDistance(from: self.currentLocation, to: self.targetLocationCoordinate)
                }
            } else {
                // Annotationと地域を最初に表示したならば、direction calculateを行う
                //CLLocationDegreeからCLLocationに
                let targetLocation = CLLocation(latitude: targetLocationCoordinate.latitude, longitude: targetLocationCoordinate.longitude)
                DispatchQueue.main.async {
                    if self.addressLabel.text == nil {
                        self.getPlaceName(target: targetLocation) { placeName in
                            self.addressLabel.text = "住所: \(placeName ?? "")"
                            // Placeを取得してから、fontをheavyに変える作業をここで行う。また、textColorをblackに
                            self.addressLabel.textColor = UIColor.black
                            self.addressLabel.font = .systemFont(ofSize: 17, weight: .heavy)
                        }
                    }
                    
                    self.getDistance(from: self.currentLocation, to: self.targetLocationCoordinate)
//                    self.calculateTime(curLocate: self.currentLocation, targetLocate: self.targetLocationCoordinate)
                    // self.connectOverlayWithPreviousCoordinate(coordinate: coordinate)

                    self.calculateDirection(curLocate: self.currentLocation, targetLocate: self.targetLocationCoordinate, transportIndex: self.transportationSegmentedController.selectedSegmentIndex)
                }
            }
        }
    }
    
    // ユーザの位置情報を受け取ることに失敗した場合
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(#function)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            print("GPS権限の設定済み")
            // startUpdateをすることで、didUpdateLocationメソッドを呼び出すことが可能
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        case .restricted, .notDetermined:
            print("GPS権限設定されてない")
            // GPS利用許可を求める
            DispatchQueue.main.async {
                self.getLocationUsagePermission()
            }
        case .denied:
            print("GPS権限のRequestが拒否")
            // alertを表示させ、iPhoneの設定画面に誘導する
            self.present(showRequestLocationServiceAlert(), animated: true)
            return
        default:
            print("GPS: Default")
        }
    }
    
}

//    // 目的地に向かって歩くとき、最初に表示された経路を消しながら動く
//    // MARK: 使うかどうかは未定⚠️
//    func calculateMoveToDestination() {
//        if let previousCoordinate = self.previousLocation {
//            var points: [CLLocationCoordinate2D] = []
//            let point1 = CLLocationCoordinate2DMake(previousCoordinate.latitude, previousCoordinate.longitude)
//            let point2: CLLocationCoordinate2D = CLLocationCoordinate2DMake(currentLocation.latitude, currentLocation.longitude)
//            points.append(point1)
//            points.append(point2)
//            let lineDraw = MKPolyline(coordinates: points, count:points.count)
//            self.mapView.removeOverlay(lineDraw)
//        }
//    }


//let calloutView = R.nib.placeCalloutView.firstView(owner: nil)!
//if let annotatioin = view.annotation as? PlaceAnnotation {
//    calloutView.label.text = annotatioin.name
//    calloutView.imageView.image = annotatioin.image
//}
//// make inset because the callout's bottom focuses on the center of annotation
//let inset = PlaceAnnotationView.height / 2
//calloutView.center = CGPoint(x: view.bounds.size.width / 2,
//                             y: (-calloutView.bounds.size.height / 2) - inset)
