//
//  ViewController.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2022/12/12.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var serialMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // serialの初期化
        serial = BluetoothSerial.init()
    }
    
    @IBAction func scanButtonAction(_ sender: Any) {
        let scanVC = UIStoryboard.init(name: "ScanView", bundle: nil).instantiateViewController(withIdentifier: "ScanVC")
        self.present(scanVC, animated: true, completion: nil)
    }
    
    @IBAction func sendMessageButtonAction(_ sender: Any) {
        if !serial.isReadyToUseBluetooth {
            print("Serial is not ready!")
            return
        }
        serial.delegate = self
        // messageを設定し、これに繋がったperipheralに伝送するメソッドを呼び出す
        let msg = "okokok"
        serial.sendMessageToDevice(msg)
        // ラベルのtextを変更し、データを待ち中であることを表現する
        serialMessageLabel.text = "waiting for Peripheral's messege"
    }
}

extension ViewController: BluetoothSerialDelegate {
    func serialDidReceiveMessage(message: String) {
        // 返信で返ってきたメッセージをラベルに表示
        serialMessageLabel.text = message
    }
    
}

