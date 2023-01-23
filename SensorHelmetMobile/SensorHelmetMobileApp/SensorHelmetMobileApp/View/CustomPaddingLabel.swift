//
//  CustomPaddingLabel.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/23.
//

import UIKit

class CustomPaddingLabel: UILabel {
    private var padding = UIEdgeInsets(top: 2.0, left: 4.0, bottom: 2.0, right: 4.0)
        
    convenience init(padding: UIEdgeInsets) {
        self.init()
        self.padding = padding
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }
    
    // 中に含まれているcontentSizeに合わせてheightとwidthにpaddingを与える
    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.height += padding.top + padding.bottom
        contentSize.width += padding.left + padding.right
        
        return contentSize
    }
}
