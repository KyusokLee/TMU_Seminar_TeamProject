//
//  ScanTableViewCell.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2022/12/14.
//

import UIKit

class ScanTableViewCell: UITableViewCell {

    @IBOutlet weak var peripheralName: UILabel! {
        didSet {
            peripheralName.textColor = .darkGray
            peripheralName.font = .systemFont(ofSize: 18, weight: .bold)
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
    
    func updatePeriphralName(name: String?) {
        guard name != nil else { return }
        peripheralName.text = name
    }
    
}
