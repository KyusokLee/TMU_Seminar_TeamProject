//
//  PublicInstitutionTableViewCell.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/26.
//

import UIKit

class PublicInstitutionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var publicInstitutionImageView: UIImageView!
    
    @IBOutlet weak var publicInstitutionNameLabel: UILabel! {
        didSet {
            publicInstitutionNameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        }
    }
    
    @IBOutlet weak var publicInstitutionTypeLabel: UILabel! {
        didSet {
            publicInstitutionTypeLabel.textColor = .systemGray.withAlphaComponent(0.85)
            publicInstitutionTypeLabel.font = .systemFont(ofSize: 15, weight: .medium)
        }
    }
    
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
        let image = UIImage(named: institutionType)?.withTintColor(.black, renderingMode: .alwaysOriginal)
        
        if let image = image {
            // Firestoreに登録されてる公共機関の名前
            let size = CGSize(width: 35, height: 35)
            UIGraphicsBeginImageContext(size)
            image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            publicInstitutionImageView.image = resizedImage
        } else {
            // 登録されていない公共機関の場合
            let defaultImage = UIImage(systemName: "questionmark")?.withTintColor(.black, renderingMode: .alwaysOriginal)
            publicInstitutionImageView.image = defaultImage
        }
        
        publicInstitutionNameLabel.text = institutionName
        publicInstitutionTypeLabel.text = institutionType
    }
}
