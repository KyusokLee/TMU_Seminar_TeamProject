//
//  UIImage+Utils.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/11/29.
//

import Foundation
import UIKit

extension UIImage {
    var scaledToSafeUploadSize: UIImage? {
        let maxImageSideLength: CGFloat = 480
        let largerSide: CGFloat = max(size.width, size.height)
        let ratioScale: CGFloat = largerSide > maxImageSideLength ? largerSide / maxImageSideLength : 1
        let newImageSize = CGSize(width: size.width / ratioScale, height: size.height / ratioScale)
        
        return image(scaledTo: newImageSize)
    }
    
    // deferはエラーが発生してコードブロックを抜けようが、正常にコードブッロクを抜けようがdefer文はコードがブロックを抜けるとき、必ず実行される
    private func image(scaledTo size: CGSize) -> UIImage? {
        defer {
            UIGraphicsEndImageContext()
        }
        
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        draw(in: CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
