//
//  ScanVC.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2022/12/14.
//

import UIKit
import CoreBluetooth

class ScanVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    // 現在検索された周辺機器リスト
    var peripheralList : [(peripheral : CBPeripheral, RSSI : Float)] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // scanボタンを押して、検索を開始するたびに、listを初期化する
        setUpTableView()
        registerNib()
        
        peripheralList = []
        serial.delegate = self
        // scan 開始
        serial.startScan()
    }
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    func registerNib() {
        tableView.register(UINib(nibName: "ScanTableViewCell", bundle: nil), forCellReuseIdentifier: "ScanTableViewCell")
    }
    
}

extension ScanVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheralList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ScanTableViewCell", for: indexPath) as? ScanTableViewCell else {
            return UITableViewCell()
        }
        
        let peripheralName = peripheralList[indexPath.row].peripheral.name
        cell.updatePeriphralName(name: peripheralName)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        serial.stopScan()
        
        let selectedPeripheral = peripheralList[indexPath.row].peripheral
        serial.connectToPeripheral(selectedPeripheral)
    }

}

extension ScanVC: BluetoothSerialDelegate {
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?) {
        
        for existing in peripheralList {
            if existing.peripheral.identifier == peripheral.identifier {
                // すでに保存したデバイスなら、return
                return
            }
        }
        
        // 信号の強さを基準にソートする
        let fRSSI = RSSI?.floatValue ?? 0.0
        peripheralList.append((peripheral: peripheral, RSSI: fRSSI))
        peripheralList.sort { $0.RSSI < $1.RSSI }
        // tableView更新
        tableView.reloadData()
    }
    
    func serialDidConnectPeripheral(peripheral: CBPeripheral) {
        let connectSuccessAlert = UIAlertController(title: "Bluetooth 接続成功!", message: "\(peripheral.name ?? "知らないデバイス")と繋がりました。", preferredStyle: .actionSheet)
        let confirm = UIAlertAction(title: "確認", style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
        }
        connectSuccessAlert.addAction(confirm)
        serial.delegate = nil
        present(connectSuccessAlert, animated: true, completion: nil)
    }
}
