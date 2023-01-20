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

class MapVC: UIViewController {
    private var mapView: MKMapView = MKMapView()
    
    // Firestoreから受け取る
    // MARK: 現在の位置情報を受け取るための変数を定義
    var currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    var destinationLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    var shelterLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    
    // target
    var targetLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    
    var locations: [CLLocation] = []
    
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
//        button.setImage(UIImage(systemName: "arrow.triangle.turn.up.right.circle.fill")?.withRenderingMode(.alwaysOriginal), for: .normal)
//        button.tintColor = .systemGray3
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
    
    let distanceLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = UIColor.black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let expectedTimeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = UIColor.black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getLocationUsagePermission()
        view.addSubview(dismissButton)
        view.addSubview(navigateRouteButton)
        view.addSubview(cancelNavitageRouteButton)
        view.addSubview(distanceLabel)
        view.addSubview(expectedTimeLabel)
        setDismissBtnConstraints()
        setNavigateRouteBtnConstraints()
        setCancelNavigateBtnConstraints()
        setDistanceLabelConstraints()
        setExpectedTimeLabelConstraints()
        
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
        self.distanceLabel.text = curLocate.distanceText(to: targetLocate)
    }
    
    func getLocationUsagePermission() {
        // アプリの使用中のみ位置情報サービスの利用許可を求める
        self.locationManager.requestWhenInUseAuthorization()
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
        
        let destinationPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: destinationLocation.latitude, longitude: destinationLocation.longitude), addressDictionary: nil)
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
        
        if direction.isCalculating {
            // 経路表示中止
            if didTapCancelNavigateButton {
                // direction cancel
                direction.cancel()
                // overlayを全部消す
                mapView.removeOverlays(overlays)
                return
            } else {
                // 計算中であり、中止ボタンが押されてない
                getDistance(from: curLocate, to: targetLocate)
            }
        } else {
            // 計算中でなかったら、計算をstart
            direction.calculate { [weak self] response, error in
                // routeをひとつにするか複数にするかをここで設定
                guard let response = response, let route = response.routes.first else {
                    return
                }
                
                let timeFormatString = self?.formatTime(route.expectedTravelTime)
                
                self?.expectedTimeLabel.text = "予想所要時間: " + (timeFormatString ?? "")
                
                self?.mapView.addOverlay(route.polyline, level: .aboveRoads)
            }
        }
        
        //計算Calculateを止めることで、経路探索を中止することが可能
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
        self.navigateRouteButton.bottomAnchor.constraint(equalTo: self.distanceLabel.topAnchor, constant: -10).isActive = true
        self.navigateRouteButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 80).isActive = true
    }
    
    func setCancelNavigateBtnConstraints() {
        self.cancelNavitageRouteButton.bottomAnchor.constraint(equalTo: self.distanceLabel.topAnchor, constant: -10).isActive = true
        self.cancelNavitageRouteButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -80).isActive = true
    }
    
    func setDistanceLabelConstraints() {
        self.distanceLabel.topAnchor.constraint(equalTo: self.navigateRouteButton.bottomAnchor, constant: 10).isActive = true
        self.distanceLabel.bottomAnchor.constraint(equalTo: self.expectedTimeLabel.topAnchor, constant: -10).isActive = true
        self.distanceLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        self.distanceLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
    }
    
    func setExpectedTimeLabelConstraints() {
        self.expectedTimeLabel.topAnchor.constraint(equalTo: self.distanceLabel.bottomAnchor, constant: 10).isActive = true
        self.expectedTimeLabel.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        self.expectedTimeLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        self.expectedTimeLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
    }
    
    func formatTime(_ time:Double) -> String{
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
            targetLocation = destinationLocation
        } else {
            targetLocation = shelterLocation
        }
        
        // Direction計算
        calculateDirection(curLocate: currentLocation, targetLocate: targetLocation)
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
            
            if !didShowFirstAnnotaionAndRegion {
                didShowFirstAnnotaionAndRegion = true
    
                if didGetHelmet {
                    targetLocation = shelterLocation
                } else {
                    targetLocation = destinationLocation
                }
                
                setRegionAndAnnotation(center: coordinate, target: targetLocation)
                setAnnotation(latitudeValue: targetLocation.latitude, longitudeValue: targetLocation.longitude, delta: 0.1, title: "目的地", subtitle: "")
                getDistance(from: currentLocation, to: targetLocation)
            } else {
                // Annotationと地域を最初に表示さたならば、direction calculateを行う
                if didGetHelmet {
                    calculateDirection(curLocate: currentLocation, targetLocate: shelterLocation)
                } else {
                    calculateDirection(curLocate: currentLocation, targetLocate: destinationLocation)
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
