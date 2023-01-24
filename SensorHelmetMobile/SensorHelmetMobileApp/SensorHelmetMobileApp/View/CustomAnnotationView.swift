//
//  CustomAnnotationView.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/21.
//

import UIKit
import MapKit

// カスタムアノテーションビューの定義
// ⚠️途中の段階
//class CustomAnnotationView: MKMarkerAnnotationView {
//    override var annotation: MKAnnotation? {
//        didSet {
//            configure(for: annotation)
//        }
//    }
//
//    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
//        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
//
//        glyphImage = UIImage(systemName: "flame")!
//        configure(for: annotation)
//    }
//
//    // nibファイルを使わないから、coderはfatalError処理をした
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func configure(for annotation: MKAnnotation?) {
//        displayPriority = .required
//        markerTintColor = selectTintColor(annotation)
//    }
//
//    private func selectTintColor(_ annotation: MKAnnotation?) -> UIColor? {
//        guard let annotation = annotation as? MKPointAnnotation else { return nil }
//        // MARK: ー 以下のやつは、任意のcolorを格納した方法
//        let colors: [UIColor] = [.systemRed, .systemBlue, .systemYellow, .systemGreen]
//        let index = Int(annotation.title ?? "") ?? 0
//        let remainder = index % colors.count
//        return colors[remainder]
//    }
//}

// markerViewがballon animationを含むようだ
class CustomAnnotationView: MKAnnotationView {
    static let identifier = "CustomAnnotationView"
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?){
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)
        setupUI()
    }
    
    // nib fileを使用しない
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        layer.cornerRadius = frame.size.height / 2
    }
}

class CustomAnnotation: NSObject, MKAnnotation {
    let pinImageTag: Int?
    let coordinate: CLLocationCoordinate2D
    //let backgroundColor: UIColor?
    
    init(
        pinImageTag: Int?,
        coordinate: CLLocationCoordinate2D
        //backgroundColor: UIColor?
    ) {
        self.pinImageTag = pinImageTag
        self.coordinate = coordinate
        //self.backgroundColor = backgroundColor
        
        super.init()
    }
}
