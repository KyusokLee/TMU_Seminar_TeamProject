//
//  SensorDataLabelTableViewCell.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2024/01/08.
//

import UIKit

class SensorDataLabelTableViewCell: UITableViewCell {

    @IBOutlet weak var dataLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}

extension SensorDataLabelTableViewCell {
    // MARK: - 各データをここでconfigureさせる
    func configure(dataString: String?) {
        dataLabel.text = dataString
    }
    
    func setupUI() {
        setupFont()
    }
    
    func setupFont() {
        dataLabel.font = .systemFont(ofSize: 17, weight: .semibold)
    }
}

