//
//  ImageMediaItem.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/11/07.
//

import UIKit
import MessageKit


// チャットの内容にimageが入るかも知れないので、imageファイルと関連したModel定義
// MediaItemは　MessageKit内に存在するprotocolであり、imageを表すために必要な必須情報を定義
struct ImageMediaItem: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(image: UIImage) {
        self.image = image
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }
}
