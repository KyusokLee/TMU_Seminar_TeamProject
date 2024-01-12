//
//  SensorDataLabelTableViewCollectionViewCell.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2024/01/08.
//

import UIKit

class SensorDataLabelTableViewCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var labelTableView: UITableView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupTableView()
    }
}

extension SensorDataLabelTableViewCollectionViewCell {
    func setupTableView() {
        labelTableView.delegate = self
        labelTableView.dataSource = self
        registerCell()
    }
    
    func registerCell() {
        labelTableView.register(
            UINib(nibName: "SensorDataLabelTableViewCell", bundle: nil),
            forCellReuseIdentifier: "SensorDataLabelTableViewCell"
        )
    }
}

extension SensorDataLabelTableViewCollectionViewCell: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SensorDataLabelTableViewCell", for: indexPath) as? SensorDataLabelTableViewCell else {
            return UITableViewCell()
        }
        
        cell.configure(dataString: "Data")
        return cell
    }
}
