//
//  TCPNetwork.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/03.
//

import Foundation
import Network

// TCP Networkを用いて、Raspiを遠隔操作する

class TempHum : ObservableObject{
    var addTimer: Timer!
    var tempData = ""
    
    func send(connection: NWConnection) {
        let message = "\n"
        let data = message.data(using: .utf8)!
        let semaphore = DispatchSemaphore(value: 0)

        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                NSLog("\(#function), \(error)")
            } else {
                semaphore.signal()
            }
        })

        semaphore.wait()
    }
    
    func recv(connection: NWConnection) {
        let semaphore = DispatchSemaphore(value: 0)
        connection.receive(minimumIncompleteLength: 0, maximumLength: 65535, completion:{(data, context, flag, error) in
            if let error = error {
                NSLog("\(#function), \(error)")
            } else {
                if let data = data {
                    let text:String = String(data: data, encoding: .utf8)!
                    let words = text.components(separatedBy: ",")
                    DispatchQueue.main.async {
                        self.tempData = "温度:\(words[0].trimmingCharacters(in: .whitespacesAndNewlines))"
                    }
                    semaphore.signal()
                }
                else {
                    NSLog("receiveMessage data nil")
                }
            }
        })

        semaphore.wait()
    }
    
    func disconnect(connection: NWConnection)
    {
        connection.cancel()
    }
    
    func connect(host: String, port: String) -> NWConnection
    {
        let t_host = NWEndpoint.Host(host)
        let t_port = NWEndpoint.Port(port)
        let connection : NWConnection
        let semaphore = DispatchSemaphore(value: 0)
        
        connection = NWConnection(host: t_host, port: t_port!, using: .tcp)
        
        connection.stateUpdateHandler = { (newState) in
            switch newState {
                case .ready:
                    NSLog("Ready to send")
                    semaphore.signal()
                case .waiting(let error):
                    NSLog("\(#function), \(error)")
                case .failed(let error):
                    NSLog("\(#function), \(error)")
                case .setup: break
                case .cancelled: break
                case .preparing: break
                @unknown default:
                    fatalError("Illegal state")
            }
        }
        
        let queue = DispatchQueue(label: "temphum")
        connection.start(queue:queue)
        semaphore.wait()
        return connection
    }
    
    @objc func interval_get(sender: Timer)
    {
        let connection : NWConnection
        let addr = sender.userInfo as! Dictionary<String, String>
        let host = addr["host"]
        let port = addr["port"]
        
        connection = connect(host: host!, port: port!)
        send(connection: connection)
        recv(connection: connection)
        disconnect(connection: connection)
    }
    
    init(host: String, port: String) {
        let addr = ["host":host, "port":port]
        addTimer =  Timer.scheduledTimer(timeInterval:5.0,
                                         target:self,
                                         selector:#selector(interval_get),
                                         userInfo:addr,
                                         repeats:true)
        addTimer.fire()
    }
}
