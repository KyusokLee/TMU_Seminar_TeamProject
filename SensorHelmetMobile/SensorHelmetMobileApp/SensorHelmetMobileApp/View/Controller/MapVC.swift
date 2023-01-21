//
//  MapVC.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/04.
//

import UIKit
import MapKit
import CoreLocation

// Apple Mapを用いた経路探索と現在位置の取得
// TODO: Helmetの場所にある程度近づけると、Helmetのannotationを消し、避難所のannotationを立てる
// MARK: - ⚠️maps short session requested but session sharing is not enabledエラーを修正中
// MARK: - ✍️実装中: 緯度と経度を用いたreverseGeocodeLocationで、住所名を持ってくる

// TODO: 最初から、helmetがある目的地までのとこを表示

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
    // 初期の設定を表示したかどうか
    var didShowFirstAnnotaionAndRegion: Bool = false
    
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
        label.textColor = UIColor(rgb: 0x4CAF50)
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
        button.addTarget(nil, action: #selector(navigateRouteButtonAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration = config
        
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
        setDismissBtnConstraints()
        setNavigateRouteBtnConstraints()
        setCancelNavigateBtnConstraints()
        setAddressLabelConstraints()
        setDistanceLabelConstraints()
        setExpectedTimeLabelConstraints()
        setHelmetNoticeLabelConstraints()
        setGetHelmetButtonConstraints()
        self.getHelmetButton.isHidden = true
        removeGetHelmetButtonConstraints()
        
        // mapViewにtapGestureを登録する必要があるのかな
        
        mapView.frame = view.bounds
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.follow, animated: true)
        mapView.delegate = self
        view.addSubview(mapView)
        // mapViewの上にButtonを表示させる方法 (AppleのHIGに望ましくない)
        // view.bringSubviewToFront(dismissButton)
        setMapViewConstraints()
        
        // 現在位置の取得
        // getCurrentLocation(manager: locationManager)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.locationManager.stopUpdatingLocation()
    }
    
//    // mapViewにtapGestureを登録する
//    func setMapTapGesture() {
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapGestureAction))
//        mapView.addGestureRecognizer(tapGesture)
//    }
//
//    @objc func mapTapGestureAction() {
//        print("tap map")
//    }
    
    // 最初の地域設定
    func setRegionAndAnnotation(center: CLLocationCoordinate2D, target: CLLocationCoordinate2D) {
        // Region(地域)を設定
        let coordinate = CLLocationCoordinate2DMake((center.latitude + destinationLocation.latitude) / 2, (center.longitude + destinationLocation.longitude) / 2)
        // Mapで表示した地域のHeightとwidthを設定
        let span = MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    func getDistance(from curLocate: CLLocationCoordinate2D, to targetLocate: CLLocationCoordinate2D) {
        let rawDistance = curLocate.distance(to: targetLocate)
        
        // TODO: 🔥5m以内であれば、Helmetの装着したかを表示し、ボタンを押したら、避難所への経路を表示
        if rawDistance < 5 {
            let roundedDistance = (rawDistance / 10).rounded() * 10
            self.distanceLabel.text = "目的地までの距離: \(Int(roundedDistance))"
            
            if getHelmetButton.isHidden {
                self.getHelmetButton.isHidden = false
                setGetHelmetButtonConstraints()
            }
        } else {
            self.distanceLabel.text = curLocate.distanceText(to: targetLocate)
            
            if !getHelmetButton.isHidden {
                self.getHelmetButton.isHidden = true
                removeGetHelmetButtonConstraints()
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
            self?.mapView.addOverlay(route.polyline, level: .aboveRoads)
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
        
        // overlayを全部消す
        if !overlays.isEmpty {
            DispatchQueue.main.async {
                self.mapView.removeOverlays(overlays)
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
    func setAnnotation(latitudeValue: CLLocationDegrees, longitudeValue: CLLocationDegrees, delta span :Double, title strTitle: String, subtitle strSubTitle:String) {
        mapView.removeAnnotations(mapView.annotations)
        
        let annotation = MKPointAnnotation()
        let annotation2 = MKPointAnnotation()
        var annotations = [annotation]
        
        annotation.coordinate = CLLocationCoordinate2DMake(latitudeValue, longitudeValue)
        annotation.title = strTitle
        annotation.subtitle = strSubTitle
        
        annotation2.coordinate = shelterLocation
        annotation2.title = "避難所"
        annotation2.subtitle = ""
//        var view = MKMarkerAnnotationView()
//        view.annotation = annotation2
//        view.markerTintColor = UIColor.systemGreen
        
        annotations.append(annotation)
        annotations.append(annotation2)
        mapView.addAnnotations(annotations)
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
        self.helmetNoticeLabel.topAnchor.constraint(equalTo: self.expectedTimeLabel.bottomAnchor, constant: 5).isActive = true
        self.helmetNoticeLabel.bottomAnchor.constraint(equalTo: self.getHelmetButton.topAnchor, constant: -5).isActive = true
        self.helmetNoticeLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        self.helmetNoticeLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
    }
    
    func setGetHelmetButtonConstraints() {
        self.getHelmetButton.topAnchor.constraint(equalTo: self.helmetNoticeLabel.bottomAnchor, constant: 5).isActive = true
        self.getHelmetButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        self.getHelmetButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 80).isActive = true
        self.getHelmetButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -80).isActive = true
    }
    
    func removeGetHelmetButtonConstraints() {
        self.getHelmetButton.bottomAnchor.constraint(equalTo: self.getHelmetButton.topAnchor).isActive = true
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
        // 避難所への経路に入れ替える
    }
    
}

extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let routePolyline = overlay as? MKPolyline else {
            print("Can't draw polyline of route")
            return MKOverlayRenderer()
        }
        
        let routeRenderer = MKPolylineRenderer(polyline: routePolyline)
        routeRenderer.strokeColor = UIColor(red:1.00, green:0.35, blue:0.30, alpha:1.0)
        routeRenderer.lineWidth = 5.0
        routeRenderer.alpha = 1.0
        
        return routeRenderer
    }
        
    // annotaionViewをtapしたとき、呼び出されるメソッド
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // CLLocationとCLLocationCoodinate2Dは、異なるもの
        if let hasCoordinate = view.annotation?.coordinate {
            print("Tap Annotation")
            let location = CLLocation(latitude: hasCoordinate.latitude, longitude: hasCoordinate.longitude)
            
            DispatchQueue.main.async {
                self.getPlaceName(target: location) { placeName in
                    self.addressLabel.text = "住所: \(placeName ?? "")"
                    // Placeを取得してから、fontをheavyに変える作業をここで行う。また、textColorをblackに
                    self.addressLabel.textColor = UIColor.black
                    self.addressLabel.font = .systemFont(ofSize: 17, weight: .heavy)
                }
                
                self.getDistance(from: self.currentLocation, to: hasCoordinate)
                self.calculateDirection(curLocate: self.currentLocation, targetLocate: hasCoordinate)
            }
        }
    }
    
    // annotationViewのtapを解除したとき、呼び出されるメソッド
    // MARK: - ⚠️注意: 他のannotaionをクリックしても、didDeselectされた後、selectされるようになる
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
    
    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        if annotation.title == "避難所" {
//            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "")
//            annotationView.backgroundColor = UIColor.systemGreen
//            return annotationView
//        } else {
//            return MKAnnotationView()
//        }
//    }
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
            // CLLocationの設定
            let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            // 最初に表示させるとき
            if !didShowFirstAnnotaionAndRegion {
                didShowFirstAnnotaionAndRegion = true
    
                if didGetHelmet {
                    targetLocationCoordinate = shelterLocation
                } else {
                    targetLocationCoordinate = destinationLocation
                }
                
                //CLLocationDegreeからCLLocationに
                let targetLocation = CLLocation(latitude: targetLocationCoordinate.latitude, longitude: targetLocationCoordinate.longitude)
                
                setRegionAndAnnotation(center: coordinate, target: targetLocationCoordinate)
                setAnnotation(latitudeValue: targetLocationCoordinate.latitude, longitudeValue: targetLocationCoordinate.longitude, delta: 0.1, title: "目的地", subtitle: "")
                
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
