//
//  SendMessagesToServerController.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/21.
//

import UIKit

final class SendMessagesToServerController: UIViewController {
    
    // カメラをVCへの画面遷移メソッド
    static func instantiate() -> SendMessagesToServerController {
        let storyboard = UIStoryboard(name: "SendMessagesToServerView", bundle: nil)
        guard let controller = storyboard.instantiateViewController(
            withIdentifier: "SendMessagesToServerController"
        ) as? SendMessagesToServerController else {
            fatalError("SendMessagesToServerController could not be found.")
        }
        
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
}
