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

// Apple Mapを用いた経路探索と現在位置の取得
// TODO: Helmetの場所にある程度近づけると、Helmetのannotationを消し、避難所のannotationを立てる
// MARK: - ⚠️maps short session requested but session sharing is not enabledエラーを修正中
// MARK: - ✍️実装中: 緯度と経度を用いたreverseGeocodeLocationで、住所名を持ってくる

// TODO: 1. 最初から、helmetがある目的地までのとこを表示
// TODO: 2. ヘルメットを装着していない状態なら、避難所までの経路は表示されないように
// TODO: 3 - 1. ヘルメット解除する場合を想定して、destinationLocationをcurrentLocationに変える作業をする
// TODO: 3 - 2. これに関しては、ずっと位置情報をupdateするのではなく、解除ボタンを押したときだけ、destinationLocationをfetchする作業をする
// TODO: 3 - 3. どうせ、ヘルメットを装着しているのであれば、Firestoreに格納される経度と緯度は、現在地にfetchされるはず

class MapVC: UIViewController {
    private var mapView: MKMapView = MKMapView()
    
    // Firestoreから受け取る
    // MARK: 現在の位置情報を受け取るための変数を定義
    var currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    var destinationLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    var shelterLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    
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
    
    // リアルタイムな現在位置情報をmanageするための変数
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()

        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        
        return manager
    }()
    
    let dismissButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "multiply")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.tintColor = .systemGray3
        button.addTarget(nil, action: #selector(dismissButtonAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // 経路までのnavigatorのButtonを表示
    let navigateRouteButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.buttonSize = .medium
        config.baseBackgroundColor = UIColor.systemBlue
        config.baseForegroundColor = UIColor.white
        config.imagePlacement = NSDirectionalRectEdge.top
        // buttonのimageをwithConfigurationと同時に作らないと、buttonの中にimage部分の枠が含まれてしまう
        config.image = UIImage(systemName: "arrow.triangle.turn.up.right.circle.fill",
                               withConfiguration: UIImage.SymbolConfiguration(scale: .large))
        config.imagePadding = 10
        config.contentInsets = NSDirectionalEdgeInsets.init(top: 10, leading: 10, bottom: 10, trailing: 10)
        config.cornerStyle = .medium
        config.title = "経路案内"
        button.addTarget(nil, action: #selector(navigateRouteButtonAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration = config
        return button
    }()
    
    // 経路探索を中止するButtonを表示
    let cancelNavitageRouteButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.buttonSize = .medium
        config.baseBackgroundColor = UIColor(rgb: 0xDC6464).withAlphaComponent(0.8)
        config.baseForegroundColor = UIColor.white
        config.imagePlacement = NSDirectionalRectEdge.top
        // buttonのimageをwithConfigurationと同時に作らないと、buttonの中にimage部分の枠が含まれてしまう
        config.image = UIImage(systemName: "stop.circle.fill",
                               withConfiguration: UIImage.SymbolConfiguration(scale: .large))
        config.imagePadding = 10
        config.contentInsets = NSDirectionalEdgeInsets.init(top: 10, leading: 10, bottom: 10, trailing: 10)
        config.cornerStyle = .medium
        config.title = "案内中止"
        button.addTarget(nil, action: #selector(cancelNavigateRouteButtonAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration = config
        button.isEnabled = false
        return button
    }()
    
    //MARK: - distanceLabelの上にクリックした住所を表示したい
    let addressLabel: UILabel = {
        let label = UILabel()
        label.text = "住所を表示"
        //住所の場合は、fontを濃くする
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.systemGray3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let distanceLabel: UILabel = {
        let label = UILabel()
        label.text = "距離を表示"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.systemGray3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let expectedTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "所要時間を表示"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.systemGray3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let helmetNoticeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor(rgb: 0xF57C00)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let getHelmetButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.buttonSize = .large
        config.baseBackgroundColor = UIColor(rgb: 0x06C755).withAlphaComponent(0.5)
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
        config.cornerStyle = .medium
        config.attributedTitle = AttributedString("ヘルメットを装着", attributes: AttributeContainer([
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .medium)]))
        //NSAttributedString.Key.foregroundColor: UIColor.whiteをまたすると、もっと白くなってしまう
        config.titleAlignment = .center
        
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(nil, action: #selector(helmetButtonAction), for: .touchUpInside)
        button.configuration = config
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
    let locationButton: CLLocationButton = {
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
        
        getLocationUsagePermission()
        view.addSubview(dismissButton)
        view.addSubview(navigateRouteButton)
        view.addSubview(cancelNavitageRouteButton)
        view.addSubview(addressLabel)
        view.addSubview(distanceLabel)
        view.addSubview(expectedTimeLabel)
        view.addSubview(helmetNoticeLabel)
        view.addSubview(getHelmetButton)
        view.addSubview(takeOffHelmetButton)
        setDismissBtnConstraints()
        setNavigateRouteBtnConstraints()
        setCancelNavigateBtnConstraints()
        setAddressLabelConstraints()
        setDistanceLabelConstraints()
        setExpectedTimeLabelConstraints()
        setHelmetNoticeLabelConstraints()
        setGetHelmetButtonConstraints()
        setTakeOffHelmetButtonConstraints()
        self.getHelmetButton.isHidden = false
        self.takeOffHelmetButton.isHidden = true
//        removeGetHelmetButtonConstraints()

        
        mapView.frame = view.bounds
        mapView.showsUserLocation = true
        // mapViewにCustomAnnotationViewを登録
        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: CustomAnnotationView.identifier)
        mapView.addSubview(locationButton)
        setLocationButtonConstraints()
        // mapView.bringSubviewToFront(locationButton)
        mapView.setUserTrackingMode(.follow, animated: true)
        mapView.delegate = self
        view.addSubview(mapView)
        // mapViewの上にButtonを表示させる方法 (AppleのHIGに望ましくない)
        // view.bringSubviewToFront(dismissButton)
        setMapViewConstraints()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.locationManager.stopUpdatingLocation()
    }
    
    // 最初の地域設定
    func setCenterRegion(center: CLLocationCoordinate2D, target: CLLocationCoordinate2D) {
        // Region(地域)を設定
        let coordinate = CLLocationCoordinate2DMake((center.latitude + destinationLocation.latitude) / 2, (center.longitude + destinationLocation.longitude) / 2)
        // Mapで表示した地域のHeightとwidthを設定
        let span = MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        mapView.setRegion(region, animated: true)
    }
    
    func getDistance(from curLocate: CLLocationCoordinate2D, to targetLocate: CLLocationCoordinate2D) {
        let rawDistance = curLocate.distance(to: targetLocate)
        
        // TODO: 🔥100m以内であれば、Helmetの装着したかを表示し、ボタンを押したら、避難所への経路を表示
        if rawDistance < 100 {
            let roundedDistance = (rawDistance / 10).rounded() * 10
            self.distanceLabel.text = "目的地までの距離: \(Int(roundedDistance))m"
            self.helmetNoticeLabel.text = "近くにヘルメットがあります"
            
            if getHelmetButton.isHidden {
                self.getHelmetButton.isHidden = false
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
                
                if let hasAlsoChome = targetPlacemark.thoroughfare {
                    placeName += hasAlsoChome
                } else if let hasNoChome = targetPlacemark.subLocality {
                    placeName += hasNoChome
                }
                
                if let hasBanchi = targetPlacemark.subThoroughfare {
                    placeName += hasBanchi
                }
                
                completion(placeName)
            } else if let hasError = error {
                print(hasError.localizedDescription)
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
    
    // TODO: リアルタイムな移動経路の計算
    // 現在位置からtarget位置までの経路表示
    func calculateDirection(curLocate: CLLocationCoordinate2D, targetLocate: CLLocationCoordinate2D) {
        if !didTapNavigateButton {
            //
        }
        // 現在位置から目的地までの方向を計算する
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
        
        let overlays = mapView.overlays
        
        if didTapNavigateButton || didGetHelmet {
            // pass
        } else {
            // overlayを全部消す
            if !overlays.isEmpty {
                DispatchQueue.main.async {
                    self.mapView.removeOverlays(overlays)
                }
            }
        }
        
        if direction.isCalculating {
            // 経路表示中止
            if didTapCancelNavigateButton {
                // direction cancel
                direction.cancel()
                return
            } else {
                // 計算中であり、中止ボタンが押されてない
                DispatchQueue.main.async {
                    self.getDistance(from: curLocate, to: targetLocate)
                }
            }
        } else {
            // 計算中でなかったら、計算をstart
            direction.calculate { [weak self] response, error in
                // routeをひとつにするか複数にするかをここで設定
                guard let response = response, let route = response.routes.first else {
                    return
                }
                
                let timeFormatString = self?.formatTime(route.expectedTravelTime)
                DispatchQueue.main.async {
                    self?.expectedTimeLabel.text = "予想所要時間: " + (timeFormatString ?? "")
                    self?.expectedTimeLabel.textColor = UIColor.black
                    self?.expectedTimeLabel.font = .systemFont(ofSize: 17, weight: .heavy)
                    self?.mapView.addOverlay(route.polyline, level: .aboveRoads)
                }
            }
        }
    }
    
    // Custom Pinを立てる
    func setAnnotation(pinTag: Int, latitudeValue: CLLocationDegrees, longitudeValue: CLLocationDegrees, delta span :Double) {
        let pin = CustomAnnotation(pinImageTag: pinTag, coordinate: CLLocationCoordinate2D(latitude: latitudeValue, longitude: longitudeValue))
        
        DispatchQueue.main.async {
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotation(pin)
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
    
    func setMapViewConstraints() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.topAnchor.constraint(equalTo: self.dismissButton.bottomAnchor, constant: 10).isActive =  true
        mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: self.navigateRouteButton.topAnchor, constant: -10).isActive = true
    }
    
    func setLocationButtonConstraints() {
        self.locationButton.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor, constant: -30).isActive = true
        self.locationButton.rightAnchor.constraint(equalTo: self.mapView.rightAnchor, constant: -6).isActive = true
    }
    
    func setDismissBtnConstraints() {
        self.dismissButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 50).isActive = true
        self.dismissButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 30).isActive = true
    }
    
    func setNavigateRouteBtnConstraints() {
        self.navigateRouteButton.bottomAnchor.constraint(equalTo: self.addressLabel.topAnchor, constant: -10).isActive = true
        self.navigateRouteButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 80).isActive = true
    }
    
    func setCancelNavigateBtnConstraints() {
        self.cancelNavitageRouteButton.bottomAnchor.constraint(equalTo: self.addressLabel.topAnchor, constant: -10).isActive = true
        self.cancelNavitageRouteButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -80).isActive = true
    }
    
    func setAddressLabelConstraints() {
        self.addressLabel.topAnchor.constraint(equalTo: self.navigateRouteButton.bottomAnchor, constant: 10).isActive = true
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
    
    @objc func dismissButtonAction() {
        self.dismiss(animated: true)
    }
    
    @objc func navigateRouteButtonAction() {
        didTapNavigateButton = true
        // navigate buttonを押すと、案内中止Buttonを活性化し、このボタンは、非活性化にする
        navigateRouteButton.isEnabled = false
        navigateRouteButton.configuration?.showsActivityIndicator = true
        navigateRouteButton.configuration?.title = "経路案内中"
        cancelNavitageRouteButton.isEnabled = true

        // 経路表示（overlay calculate）を実施
        if !didGetHelmet {
            targetLocationCoordinate = destinationLocation
        } else {
            targetLocationCoordinate = shelterLocation
        }
        setCenterRegion(center: currentLocation, target: targetLocationCoordinate)
        
        // Direction計算
        calculateDirection(curLocate: currentLocation, targetLocate: targetLocationCoordinate)
    }
    
    // リアルタイムな経路探索を中止する
    @objc func cancelNavigateRouteButtonAction() {
        didTapCancelNavigateButton = true
        didTapNavigateButton = false
        cancelNavitageRouteButton.isEnabled = false
        navigateRouteButton.configuration?.showsActivityIndicator = false
        navigateRouteButton.configuration?.title = "経路案内"
        navigateRouteButton.isEnabled = true
        
        var targetDestination: CLLocationCoordinate2D?
        // 経路表示（overlay calculate）を実施
        if !didGetHelmet {
            targetDestination = destinationLocation
        } else {
            targetDestination = shelterLocation
        }
        
        calculateDirection(curLocate: currentLocation, targetLocate: targetDestination!)
    }
    
    @objc func helmetButtonAction() {
        didGetHelmet = true
        print("Helmet button tap!!")
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
                        self.calculateDirection(curLocate: self.currentLocation, targetLocate: self.shelterLocation)
                        self.takeOffHelmetButton.isHidden = false
                        self.setCenterRegion(center: self.currentLocation, target: self.shelterLocation)
                    }
                }
            }
        }
    }
    
    @objc func takeOffHelmetButtonAction() {
        if didGetHelmet {
            didGetHelmet = false
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
                        let helmetLocation = CLLocation(latitude: self.currentLocation.latitude, longitude: self.currentLocation.longitude)
                        self.setAnnotation(pinTag: self.annotationViewPinNumber, latitudeValue: self.targetLocationCoordinate.latitude, longitudeValue: self.targetLocationCoordinate.longitude, delta: 0.01)
                        
                        self.getPlaceName(target: helmetLocation) { placename in
                            self.addressLabel.text = "住所: \(placename ?? "")"
                            // Placeを取得してから、fontをheavyに変える作業をここで行う。また、textColorをblackに
                            self.addressLabel.textColor = UIColor.black
                            self.addressLabel.font = .systemFont(ofSize: 17, weight: .heavy)
                        }
                        
                        self.getDistance(from: self.currentLocation, to: self.targetLocationCoordinate)
                        self.calculateDirection(curLocate: self.currentLocation, targetLocate: self.targetLocationCoordinate)
                        self.takeOffHelmetButton.isHidden = true
                        self.setCenterRegion(center: self.currentLocation, target: self.targetLocationCoordinate)
                    }
                }
            }
        }
    }
    
    // 現在の位置を真ん中に表示
    @objc func moveToCurrentLocation() {
        print("Move to Current location")
        let region = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpan(latitudeDelta:0.01, longitudeDelta:0.01))
        self.mapView.setRegion(region, animated: true)
    }
    
    // gestureはいらない
//    @objc func showAnnotationDetailView(gestureRecognizer: UITapGestureRecognizer) {
//        print("show annotation detail")
//    }
    
}

extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let routePolyline = overlay as? MKPolyline else {
            print("Can't draw polyline of route")
            return MKOverlayRenderer()
        }
        
        let routeRenderer = MKPolylineRenderer(polyline: routePolyline)
        
        if annotationViewPinNumber == 0 {
            routeRenderer.strokeColor = UIColor(red:1.00, green:0.35, blue:0.30, alpha:1.0)
            routeRenderer.lineWidth = 5.0
            routeRenderer.alpha = 1.0
        } else {
            routeRenderer.strokeColor = UIColor.systemGreen
            routeRenderer.lineWidth = 5.0
            routeRenderer.alpha = 1.0
        }
        
        return routeRenderer
    }
        
    // annotaionViewをtapしたとき、呼び出されるメソッド
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // CLLocationとCLLocationCoodinate2Dは、異なるもの
        if let hasCoordinate = view.annotation?.coordinate {
            print("Tap Annotation")
            self.mapView.selectAnnotation(view.annotation!, animated: true)
            
            let location = CLLocation(latitude: hasCoordinate.latitude, longitude: hasCoordinate.longitude)
            
            DispatchQueue.main.async {
                self.getPlaceName(target: location) { placeName in
                    self.addressLabel.text = "住所: \(placeName ?? "")"
                    // Placeを取得してから、fontをheavyに変える作業をここで行う。また、textColorをblackに
                    self.addressLabel.textColor = UIColor.black
                    self.addressLabel.font = .systemFont(ofSize: 17, weight: .heavy)
                }
                
                if self.didGetHelmet {
                    self.getHelmetButton.isHidden = true
                }
                
                self.getDistance(from: self.currentLocation, to: hasCoordinate)
                self.calculateDirection(curLocate: self.currentLocation, targetLocate: hasCoordinate)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("call out")
    }
    
    // annotationViewのtapを解除したとき、呼び出されるメソッド
    // MARK: - 注意: 他のannotaionをクリックしても、didDeselectされた後、selectされるようになる
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let hasCoordinate = view.annotation?.coordinate {
            print(hasCoordinate)
            
            DispatchQueue.main.async {
                self.addressLabel.text = "住所を表示"
                self.addressLabel.textColor = UIColor.systemGray3
                self.addressLabel.font = .systemFont(ofSize: 17, weight: .medium)
                self.distanceLabel.text = "距離を表示"
                self.distanceLabel.textColor = UIColor.systemGray3
                self.distanceLabel.font = .systemFont(ofSize: 17, weight: .medium)
                self.expectedTimeLabel.text = "所要時間を表示"
                self.expectedTimeLabel.textColor = UIColor.systemGray3
                self.expectedTimeLabel.font = .systemFont(ofSize: 17, weight: .medium)
            }
            
            return
        }
    }
    
    // MARK: - Custom Annotation Viewを定義するために実装
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        if annotation is MKUserLocation { return nil }
        
        guard let hasAnnotation = annotation as? CustomAnnotation else {
            return nil
        }
        
        var annotationView = self.mapView.dequeueReusableAnnotationView(withIdentifier: CustomAnnotationView.identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: hasAnnotation, reuseIdentifier: CustomAnnotationView.identifier)
            annotationView?.canShowCallout = true
            annotationView?.contentMode = .scaleAspectFit
            annotationView?.layoutIfNeeded()
        } else {
            annotationView?.annotation = hasAnnotation
            annotationView?.canShowCallout = true
            annotationView?.layoutIfNeeded()
        }
        
//        // backGroundView
//        if let hasBackgroundView = annotationView?.subviews.first {
//
//        } else {
//
//        }
        let backGroundView = UIView()
        backGroundView.frame = CGRect(x: -2, y: -1, width: 40, height: 40)
        
        let pinImage: UIImage!
        let size = CGSize(width: 35, height: 35)
        var tapTitle = ""
        UIGraphicsBeginImageContext(size)
            
        switch hasAnnotation.pinImageTag {
        case 0:
            tapTitle = "ヘルメット"
//            backGroundView.backgroundColor = UIColor.white
//            backGroundView.layer.cornerRadius = backGroundView.frame.height / 2
//            backGroundView.layer.borderColor = UIColor(rgb: 0xF57C00).cgColor
//            backGroundView.layer.borderWidth = 1.5
            pinImage = UIImage(named: "helmetBasic")?.withRenderingMode(.alwaysOriginal).withTintColor(UIColor(rgb: 0xF57C00))
        case 1:
            tapTitle = "避難所"
//            backGroundView.backgroundColor = UIColor.systemGreen
//            backGroundView.layer.cornerRadius = backGroundView.frame.height / 2
//            backGroundView.layer.borderColor = UIColor.systemGreen.cgColor
//            backGroundView.layer.borderWidth = 1.5
            pinImage = UIImage(named: "shelterBasic")?.withRenderingMode(.alwaysOriginal).withTintColor(UIColor.systemGreen)
        default:
            // それ以外は、設定なし
            pinImage = UIImage()
        }
        
        // ボタンなどを設けなかったから、いらない
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showAnnotationDetailView(gestureRecognizer: )))
//        annotationView?.addGestureRecognizer(tapGesture)
                 
        //ラベルの作成
        let label = UILabel()
        label.text = tapTitle
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.black
        label.isUserInteractionEnabled = true
        annotationView?.detailCalloutAccessoryView = label
        annotationView?.isUserInteractionEnabled = true
        
        pinImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        annotationView?.image = resizedImage
        
        if hasAnnotation.pinImageTag == 0 {
            backGroundView.backgroundColor = UIColor.white
            backGroundView.layer.cornerRadius = backGroundView.frame.height / 2
            backGroundView.layer.borderColor = UIColor(rgb: 0xF57C00).cgColor
            backGroundView.layer.borderWidth = 1.5
//            annotationView?.backgroundColor = UIColor.white
//            annotationView?.layer.cornerRadius = backGroundView.frame.height / 2
//            annotationView?.layer.borderColor = UIColor(rgb: 0xF57C00).cgColor
//            annotationView?.layer.borderWidth = 1.5
        } else {
//            annotationView?.backgroundColor = UIColor.systemGreen
//            annotationView?.layer.cornerRadius = backGroundView.frame.height / 2
//            annotationView?.layer.borderColor = UIColor.systemGreen.cgColor
//            annotationView?.layer.borderWidth = 1.5
            
            backGroundView.backgroundColor = UIColor.systemGreen
            backGroundView.layer.cornerRadius = backGroundView.frame.height / 2
            backGroundView.layer.borderColor = UIColor.systemGreen.cgColor
            backGroundView.layer.borderWidth = 1.5
        }
        
        annotationView?.addSubview(backGroundView)
        annotationView?.sendSubviewToBack(backGroundView)
        
        return annotationView
    }
}

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
                targetLocationCoordinate = destinationLocation
            }
            
            // 最初に表示させるとき
            if !didShowFirstAnnotaionAndRegion {
                didShowFirstAnnotaionAndRegion = true

                //CLLocationDegreeからCLLocationに
                let targetLocation = CLLocation(latitude: targetLocationCoordinate.latitude, longitude: targetLocationCoordinate.longitude)

                setCenterRegion(center: coordinate, target: targetLocationCoordinate)
                setAnnotation(pinTag: pinNum!, latitudeValue: targetLocationCoordinate.latitude, longitudeValue: targetLocationCoordinate.longitude, delta: 0.1)

                DispatchQueue.main.async {
                    self.getPlaceName(target: targetLocation) { placeName in
                        self.addressLabel.text = "住所: \(placeName ?? "")"
                        // Placeを取得してから、fontをheavyに変える作業をここで行う。また、textColorをblackに
                        self.addressLabel.textColor = UIColor.black
                        self.addressLabel.font = .systemFont(ofSize: 17, weight: .heavy)
                    }

                    self.calculateDirection(curLocate: self.currentLocation, targetLocate: self.targetLocationCoordinate)
                    self.getDistance(from: self.currentLocation, to: self.targetLocationCoordinate)
                }
            } else {
                // Annotationと地域を最初に表示さたならば、direction calculateを行う
//                if didGetHelmet {
//                    calculateDirection(curLocate: currentLocation, targetLocate: shelterLocation)
//                } else {
//                    calculateDirection(curLocate: currentLocation, targetLocate: destinationLocation)
//                }
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
