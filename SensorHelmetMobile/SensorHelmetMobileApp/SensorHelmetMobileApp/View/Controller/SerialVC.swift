//
//  SerialVC.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2022/12/14.
//

import UIKit

class SerialVC: UIViewController {

    @IBOutlet weak var serialMessageLabel: UILabel!
    
    @IBOutlet weak var scanButton: UIButton! {
        didSet {
            scanButton.tintColor = .systemBlue
        }
    }
    
    @IBOutlet weak var sendMessageButton: UIButton! {
        didSet {
            sendMessageButton.tintColor = .cyan
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // serialの初期化
        serial = BluetoothSerial.init()
    }
    
    @IBAction func scanButtonAction(_ sender: Any) {
        performSegue(withIdentifier: "ScanVC", sender: nil)
    }
    
    // 周辺機器にデータを転送する
    @IBAction func sendMessageButtonAction(_ sender: Any) {
        if !serial.isReadyToUseBluetooth {
            print("Serial is not ready")
            return
        }
        
        serial.delegate = self
        let msg = "123"
        serial.sendMessageToDevice(msg)
        serialMessageLabel.text = "waiting for Peripheral's messege"
    }
}

extension SerialVC: BluetoothSerialDelegate {
    
    func serialDidReceiveMessage(message: String) {
        // 返信で返ってきたメッセージをラベルに表示
        serialMessageLabel.text = message
    }
    
    
}
