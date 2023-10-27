//
//  PublicInstitutionTableViewCell.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/26.
//

import UIKit

class PublicInstitutionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var publicInstitutionImageView: UIImageView!
    
    @IBOutlet weak var publicInstitutionNameLabel: UILabel!
    
    @IBOutlet weak var publicInstitutionTypeLabel: UILabel!
    
    @IBOutlet weak var chevronImageView: UIImageView! {
        didSet {
            chevronImageView.image = UIImage(systemName: "chevron.right")?.withTintColor(UIColor(rgb: 0x1976D2).withAlphaComponent(0.7), renderingMode: .alwaysOriginal)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}

// Logic and function
extension PublicInstitutionTableViewCell {
    // UILabelのconfigureを行う
    func configure(institutionType: String, institutionName: String) {
        // MARK: - Typeごとに分ける作業を行う
        // 公共機関のタイプは4つだけを設定
        // 市役所などの官公庁, 消防署, 警察署, 病院
        // Government, FireStation, PoliceOffice, Hospital
        // ImageViewのconfigureを行う
        for type in PublicInstitutionType.allCases {
            let stringValue = type.rawValue
            if institutionType == stringValue {
                publicInstitutionTypeLabel.text = stringValue
                // image 処理
                let image = UIImage(named: stringValue.lowercased())?.withTintColor(.black, renderingMode: .alwaysOriginal)
                size = CGSize(width: 35, height: 35)
                UIGraphicsBeginImageContext(size)
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                publicInstitutionImageView.image = resizedImage
            } else {
                // 未登録の公共機関の場合
                publicInstitutionTypeLabel.text = "公共機関"
                let image = UIImage(systemName: "questionmark")?.withTintColor(.black, renderingMode: .alwaysOriginal)
                publicInstitutionImageView.image = image
            }
        }
        
        publicInstitutionNameLabel.text = institutionName
    }
}
