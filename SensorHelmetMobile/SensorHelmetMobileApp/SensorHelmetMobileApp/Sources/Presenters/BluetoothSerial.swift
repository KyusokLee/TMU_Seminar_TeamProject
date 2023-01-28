//
//  BluetoothSerial.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2022/12/12.
//

import UIKit
import CoreBluetooth

// Bluetooth通信を担当するserialをクラスで宣言
// CoreBluetoothを使うためのプロトコルを追加
// Global Handlerにした

// Central Managerがmain device
// peripheral がair podsなどの周辺機器


var serial: BluetoothSerial!

// Delegate Patternでviewとserialの連動を行う
protocol BluetoothSerialDelegate: AnyObject {
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?)
    func serialDidConnectPeripheral(peripheral : CBPeripheral)
    func serialDidReceiveMessage(message : String)
}

// プロトコルに含まれている一部の間数をOptionalに設定する
extension BluetoothSerialDelegate {
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?) {}
    func serialDidConnectPeripheral(peripheral : CBPeripheral) {}
    func serialDidReceiveMessage(message : String) {}
}


class BluetoothSerial: NSObject {
    
    weak var delegate: BluetoothSerialDelegate?
    // Peripheral意味: 周辺
    // Bluetooth周辺機器を検索し、繋げる役割を果たす
    var centralManager: CBCentralManager!
    // 現在、連結を試しているBluetooh周辺機器を意味する
    // 接続をtryするperipheral（周辺機器）は複数ありえる
    // MARK: ✍️配列型にした方が拡張性はいいが、今回はまず、一つの機器に絞った
    var pendingPeripheral: CBPeripheral?
    // 連結に成功したデバイスを意味する
    // MARK: デバイスとの通信を開始すると、このオブジェクトを利用することになる
    var connectedPeripheral: CBPeripheral?
    // データを周辺機器に送るためのcharacteristicsを格納する変数
    weak var writeCharacteristics: CBCharacteristic?
    // データの読み出しに使うcharacteristics
    weak var readCharacteristics: CBCharacteristic?
    
    
    // データを周辺機器に送るときのTypeを設定する。
    // .withResponse: データを送ると、これに対する返信が返ってくるケース
    // .withoutResponse: データを送っても、返信が来ないケース
    private var writeType: CBCharacteristicWriteType = .withoutResponse
    
    // Peripheralが持っているservice UUIDを指す
    // ほぼ全てのHM-10モジュールは、FFE0を持っているので、初期値をFFE0に設定しただけ
    // MARK: ⚠️途中
    var serviceUUID = CBUUID(string: "FFE0")
    // serviceUUIDに含まれているデータ送受信のとき使うためのUUID
    // FFE0が持っているFFE1にしただけ
    var characteristicUUID = CBUUID(string: "FFE1")
    
    // Switch機能を制御するための変数
    // MARK: ⚠️途中
    var isSwitchedOn = false
    
    // Bluetoothデバイスと繋げるのに成功し、通信可能な状態ならtrueを返す
    var isReadyToUseBluetooth: Bool {
        get {
            return centralManager.state == .poweredOn
            && connectedPeripheral != nil
            && writeCharacteristics != nil
        }
    }
    
    // serialを初期化するときに、必ず呼び出す
    // なぜなら、serialはnilになることは全くないので、必ず初期化してから使うように定義されている
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // デバイス検索開始
    // 接続可能な全ての周辺機器をserviceUUIDを通して探し出す
    func startScan() {
        // Bluetooth機能をOnにしているデバイスのみを処理する
        guard self.centralManager.state == .poweredOn else {
            return
        }
        
        // CBCentralManagerのメソッドである　scanForPeripheralsを呼び出し、接続可能なデバイスを探索
        //　この時、withServiceパラメータにnilを入力すると、全種類のデバイスを検索する
        // 一方で、serviceUUIDを入力すると、serviceUUIDを持つデバイスのみを検索するようになる
        // 新たなデバイスが接続されるたびに、centralManager(_: didDiscover: advertiseMent: ~ rssi: ~)を呼び出す
        centralManager.scanForPeripherals(withServices: [serviceUUID], options:  nil)
        
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        
        for peripheral in peripherals {
            delegate?.serialDidDiscoverPeripheral(peripheral: peripheral, RSSI: nil)
        }
    }
    
    // デバイス検索を中止
    func stopScan() {
        centralManager.stopScan()
    }
    
    // パラメータで受け取ったPeripheralをCentralManagerに繋げるように試みる
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        // 接続失敗の場合を備えて、現在接続中である周辺機器を保存する
        pendingPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    // String型でデータを周辺機器で送信する
    func sendMessageToDevice(_ message: String) {
        guard isReadyToUseBluetooth else { return }
        
        // String　-> utf8型のデータに変換して伝送する
        // utf8は、unicodeをencodingする方式であり、全世界で使う規約である
        if let data = message.data(using: String.Encoding.utf8) {
            connectedPeripheral!.writeValue(data, for: writeCharacteristics!, type: writeType)
        }
    }
    
    // データの配列をByte型として周辺機器に伝送する
    func sendBytesToDevice(_ bytes: [UInt8]) {
        guard isReadyToUseBluetooth else { return }
        
        // UInt8型に指定したunsafePointerを設ける
        // そのために、UInt8のbyteを初期化してallocate(割り当てる必要がある)
        // パラメータのbytesのpointerのinitializeを行う
        let uint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: bytes.count)
        uint8Pointer.initialize(from: bytes, count: bytes.count)
        
        // UInt8型に指定したunsafePointerを設ける
        let data = Data(bytes: uint8Pointer, count: bytes.count)
        connectedPeripheral!.writeValue(data, for: writeCharacteristics!, type: writeType)
    }
    
    // データを周辺機器に伝送する
    func sendDataToDevice(_ data: Data) {
        guard isReadyToUseBluetooth else { return }
        
        connectedPeripheral!.writeValue(data, for: writeCharacteristics!, type: writeType)
    }
}

extension BluetoothSerial: CBCentralManagerDelegate {
    // central機器のBluetoothがONになっているか、OFFになっているかなどのデバイスの状態が変化するたびに、呼び出されるメソッド
    // On: .poweredOn
    // Off: .poweredOff
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // switch機能があれば、使いたいので、一応書いた
        if central.state == .poweredOn {
            isSwitchedOn = true
        } else {
            isSwitchedOn = false
            print("Turn on Bluetooth")
        }
        
        self.pendingPeripheral = nil
        self.connectedPeripheral = nil
    }
    
    // デバイスが検索されるたびに、呼び出されるメソッド
    // デバイスを見つかったときに、呼び出されるメソッド
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // TODO: 🔥機器が検索されるたびに、必要なコードをここに作成する予定
        // MARK: ⚠️途中の段階
        // RSSIはデバイスの信号の強度を指す
        
        delegate?.serialDidDiscoverPeripheral(peripheral: peripheral, RSSI: RSSI)
        
        // var peripheralName: String!
               
//        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
//            peripheralName = name
//        }
//        else {
//            peripheralName = "Unknown"
//        }
//
//        if peripheral.identifier.uuidString == "6D915395-3E79-0072-22A3-009DDC331F7C" {
//            centralManager.stopScan()
//            centralManager.connect(peripheral, options: nil)
//            print("finded!?")
//        }
        
//        let newPeripheral = Peripheral(id: peripherals.count, name: peripheralName, rssi: RSSI.intValue)
//        print(newPeripheral)
//        peripherals.append(newPeripheral)
    }
    
    // デバイスがつながると呼び出されるメソッド
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        pendingPeripheral = nil
        connectedPeripheral = peripheral
        
        // peripheralのServicesを検索する
        // パラメータをnilにすると、peripheralの全てのservicesを検索する
        // 今は、全てのservicesを検索したいので、nilに設定した
        peripheral.discoverServices(nil)
    }
}

extension BluetoothSerial: CBPeripheralDelegate {
    // service検索に成功した時、呼び出されるメソッド
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            if let error = error {
                print("error: \(error)")
            }
            return
        }
     
        print("Found \(services.count) services: \(services)")
        
        for service in services {
            print(service.uuid.uuidString)
            // 検索した全てのservicesに対してCharacteristicsを検索する
            // パラメータをnilに設定すると、serviceの全てのcharacteristicsを検索する
            print("discovering characteristics")
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
//            if service.uuid.uuidString == "FFE0" {
//                print("discovering characteristics")
//                peripheral.discoverCharacteristics(nil, for: service)
//            }
        }
    }
     
    // Characteristics検索に成功したとき、呼び出されるメソッド
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            if let error = error {
                print("error in dicovercharc: \(error)")
            }
            return
        }
        print("Found \(characteristics) characteristics! : \(characteristics)")
        
        for characteristic in characteristics {
            // 検索された全てのCharacteristicについて、characteristicUUIDをもう一度チェックし、一致すればperipheralを登録し、通信のための設定を完了させる
            if characteristic.uuid == characteristicUUID {
                // 該当のデバイスを登録する
                peripheral.setNotifyValue(true, for: characteristic)
                // データを送るためのCharacteristicを保存
                self.writeCharacteristics = characteristic
                // データを送るためのタイプを設定する。これは、周辺機器がどんなTypeに設定されているかによって変更する
                self.writeType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                // 周辺機器と接続完了し、動作するコードをここに作成する
                delegate?.serialDidConnectPeripheral(peripheral: peripheral)
            }
        }
    }
    
    // peripheralからデータを受け取ると、呼び出されるメソッド
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let data = characteristic.value
        // 伝送されたデータが存在するかを確認する
        guard data != nil else { return }
        
        // データをString型に変換し、変換された値をパラメータとしたdelegate間数を呼び出す
        if let str = String(data: data!, encoding: String.Encoding.utf8) {
            delegate?.serialDidReceiveMessage(message : str)
        } else {
            return
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        // Bluetoothデバイスから、応答が届いたときだけ、呼び出されるメソッド
        // 必要なロジックを作成すればいい
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        // Bluetoothデバイスの信号強度をリクエストする peripheral.readRSSI()が呼び出されるメソッド
        // 必要なロジックをここに作成すればいい
    }
}
