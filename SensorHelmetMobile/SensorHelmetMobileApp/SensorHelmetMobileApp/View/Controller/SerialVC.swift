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
            scanButton.setTitle("Bluetooth scanを始める", for: .normal)
            scanButton.tintColor = .systemBlue
        }
    }
    
    @IBOutlet weak var sendMessageButton: UIButton! {
        didSet {
            sendMessageButton.setTitle("Messageを送る", for: .normal)
            sendMessageButton.tintColor = .cyan
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // serialの初期化
        serial = BluetoothSerial.init()
    }
    
    @IBAction func scanButtonAction(_ sender: Any) {
        let scanVC = UIStoryboard.init(name: "ScanView", bundle: nil).instantiateViewController(withIdentifier: "ScanVC")
        self.present(scanVC, animated: true, completion: nil)
    }
    
    // 周辺機器にデータを転送する
    @IBAction func sendMessageButtonAction(_ sender: Any) {
        if !serial.isReadyToUseBluetooth {
            print("Serial is not ready")
            return
        }
        
        serial.delegate = self
        let msg = "okokok"
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
