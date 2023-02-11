//
//  VideoListTableViewCell.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/11.
//

import UIKit

class VideoListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var videoFileNameLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView! {
        didSet {
            chevronImageView.image = UIImage(systemName: "chevron.right")?.withTintColor(UIColor(rgb: 0x1976D2).withAlphaComponent(0.7), renderingMode: .alwaysOriginal)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    // UILabelのconfigureを行う
    func configure(fileName: String) {
        videoFileNameLabel.text = fileName
    }
}
