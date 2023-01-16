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
class MapVC: UIViewController {
    private var mapView: MKMapView = MKMapView()
    
    // 目的地の位置情報
    // Firestoreから受け取る
    var destinationLongitude: CLLocationDegrees = 0.00
    var destinationLatitude: CLLocationDegrees = 0.00
    var locations: [CLLocation] = []
    
    // 最初に目的地までの経路を表示したか否かのFlag
    var didShowRouteToDestination: Bool = false
    // navigateRouteBtnを押したか否かのFlag
    var didTapNavigateButton: Bool = false
    // cancel Buttonを押したか否かのFlag
    var didTapCancelNavigateButton: Bool = false
    
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
    
    // MARK: 現在の位置情報を受け取るための変数を定義
    // 最初に、Viewを表示させるときに目的地までの経路を示すため
    var currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    // 移動記録を残すための変数
    // 前の位置情報を記録
    var previousLocation: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getLocationUsagePermission()
        
        view.addSubview(dismissButton)
        view.addSubview(navigateRouteButton)
        view.addSubview(cancelNavitageRouteButton)
        setDismissBtnConstraints()
        setNavigateRouteBtnConstraints()
        setCancelNavigateBtnConstraints()
        
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
    
    func setMapViewConstraints() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.topAnchor.constraint(equalTo: self.dismissButton.bottomAnchor, constant: 10).isActive =  true
        mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: self.navigateRouteButton.topAnchor, constant: -10).isActive = true
    }
    
    func getLocationUsagePermission() {
        // アプリの使用中のみ位置情報サービスの利用許可を求める
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func setRegionAndAnnotation(center: CLLocationCoordinate2D) {
        // Region(地域)を設定
        let coordinate = CLLocationCoordinate2DMake((center.latitude + destinationLatitude) / 2, (center.longitude + destinationLongitude) / 2)
        // Mapで表示した地域のHeightとwidthを設定
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    //TODO: 🔥最初に現在地から目的地までの経路を表示する
    func showDestinationDirection(curLocate: CLLocationCoordinate2D) {
        // 現在位置から目的地までの方向を計算する
        print("destination longi: ", destinationLongitude)
        print("destination lati:", destinationLatitude)
        
        let sourcePlacemark = MKPlacemark(coordinate: curLocate, addressDictionary: nil)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        
        let destinationPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: destinationLatitude, longitude: destinationLongitude), addressDictionary: nil)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let directionsRequest = MKDirections.Request()
        directionsRequest.transportType = .walking
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destinationMapItem
        let direction = MKDirections(request: directionsRequest)
        
        direction.calculate { [weak self] response, error in
            guard let response = response, let route = response.routes.first else {
                return
            }
            
            self?.mapView.addOverlay(route.polyline, level: .aboveRoads)
        }
        
        if didTapCancelNavigateButton {
            direction.cancel()
        }
    }
    
//    // 現在の位置情報をgetする関数
//    func getCurrentLocation(manager: CLLocationManager) {
//        if let coordinate = manager.location?.coordinate {
//            print("目的地までの経路を表示します")
//            setRegionAndAnnotation(center: coordinate)
//            showDestinationDirection(curLocate: coordinate)
//        } else {
//            print("位置情報の表示に失敗しました")
//        }
//    }
    
    // TODO: リアルタイムな移動経路の計算
    func calculateDirection(curLocate: CLLocationCoordinate2D) {
        if !didTapNavigateButton {
            //
        }
        // 現在位置から目的地までの方向を計算する
        let sourcePlacemark = MKPlacemark(coordinate: curLocate, addressDictionary: nil)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        
        let destinationPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: destinationLatitude, longitude: destinationLongitude), addressDictionary: nil)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let directionsRequest = MKDirections.Request()
        directionsRequest.transportType = .walking
        // 出発地
        directionsRequest.source = sourceMapItem
        // 目的地
        directionsRequest.destination = destinationMapItem
        // 出発地から目的地までのDirection Requestを送る
        let direction = MKDirections(request: directionsRequest)
        
        //計算Calculateを止めることで、経路探索を中止することが可能
        
        direction.calculate { [weak self] response, error in
            guard let response = response, let route = response.routes.first else {
                return
            }
            
            self?.mapView.addOverlay(route.polyline, level: .aboveRoads)
        }
        
        
        
        
        
        
    }
    
    // 目的地に向かって歩くとき、最初に表示された経路を消しながら動く
    // MARK: 使うかどうかは未定⚠️
    func calculateMoveToDestination() {
        if let previousCoordinate = self.previousLocation {
            var points: [CLLocationCoordinate2D] = []
            let point1 = CLLocationCoordinate2DMake(previousCoordinate.latitude, previousCoordinate.longitude)
            let point2: CLLocationCoordinate2D = CLLocationCoordinate2DMake(currentLocation.latitude, currentLocation.longitude)
            points.append(point1)
            points.append(point2)
            let lineDraw = MKPolyline(coordinates: points, count:points.count)
            self.mapView.removeOverlay(lineDraw)
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
    
    func setDismissBtnConstraints() {
        self.dismissButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 50).isActive = true
        self.dismissButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 30).isActive = true
    }
    
    func setNavigateRouteBtnConstraints() {
        self.navigateRouteButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        self.navigateRouteButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 80).isActive = true
    }
    
    func setCancelNavigateBtnConstraints() {
        self.cancelNavitageRouteButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        self.cancelNavitageRouteButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -80).isActive = true
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
        
        showDestinationDirection(curLocate: currentLocation)
    }
    
    // リアルタイムな経路探索を中止する
    @objc func cancelNavigateRouteButtonAction() {
        didTapCancelNavigateButton = true
        didTapNavigateButton = false
        cancelNavitageRouteButton.isEnabled = false
        navigateRouteButton.configuration?.showsActivityIndicator = false
        navigateRouteButton.configuration?.title = "経路案内"
        navigateRouteButton.isEnabled = true
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
}

extension MapVC: CLLocationManagerDelegate {
    // ユーザの位置情報を正しく持ってきた場合
    // 位置情報が更新されるたびに、呼び出されるメソッド
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = locations.last?.coordinate {
            print("位置情報取得に成功しました")
            print("longitude: ", coordinate.longitude)
            print("latitude: ", coordinate.latitude)
            
            currentLocation.longitude = coordinate.longitude
            currentLocation.latitude = coordinate.latitude
            
            setRegionAndAnnotation(center: coordinate)
            
            if !didShowRouteToDestination {
                // Viewが表示されたとたんに、destinationまでの経路を表示したか否か
                showDestinationDirection(curLocate: coordinate)
                didShowRouteToDestination = true
            } else {
                print("目的地までの経路を既に表示しました。")
                
                if didTapNavigateButton {
                    calculateMoveToDestination()
                } else {
                    
                    return
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
