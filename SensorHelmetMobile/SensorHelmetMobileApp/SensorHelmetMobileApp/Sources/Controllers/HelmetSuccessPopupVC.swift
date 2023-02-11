//
//  HelmetSuccessPopupVC.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/21.
//

import UIKit

class HelmetSuccessPopupVC: UIViewController {
    
    @IBOutlet weak var popupView: UIView! {
        didSet {
            popupView.layer.cornerRadius = 15
            popupView.layer.shadowColor = UIColor.black.cgColor
            popupView.layer.masksToBounds = false
            popupView.layer.shadowOpacity = 0.7
        }
    }
    @IBOutlet weak var getHelmetSuccessImageView: UIImageView! {
        didSet {
            getHelmetSuccessImageView.contentMode = .scaleAspectFit
        }
    }
    @IBOutlet weak var successTitleLabel: UILabel! {
        didSet {
            successTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        }
    }
    // viewをpresentしたらstateは、常にtrueである
    var presentViewState = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    static func instantiate(with helmetState: Bool) -> HelmetSuccessPopupVC {
        // controllerの指定
        let controller = UIStoryboard(name: "HelmetPopupView", bundle: nil).instantiateViewController(withIdentifier: "HelmetSuccessPopupVC") as! HelmetSuccessPopupVC
        controller.loadViewIfNeeded()
        controller.configure(with: helmetState)
        
        return controller
    }
    
    // 余白の画面をクリックしたらviewをdismissするように
    // override touchsBeganメソッドで画面をdimiss
    // Result: popup viewをクリックしても、dismiss viewになった
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true) {
            self.presentViewState = false
            print("画面のtapによるdismiss")
        }
    }
    
    //MARK: - Configureそれぞれのbutton stateに合わせてimageとlabelを表示する方が効率的
    func configure(with helmetState: Bool) {
        if helmetState {
            getHelmetSuccessImageView.image = redrawImage()
            successTitleLabel.text = "ヘルメット装着に成功しました"
        } else {
            getHelmetSuccessImageView.image = UIImage(named: "done_check_icon")
            successTitleLabel.text = "ヘルメット装着を解除しました"
        }
    }
    
    func redrawImage() -> UIImage? {
        let customImage = UIImage(named: "helmetBasic")
        let newImageRect = CGRect(x: 0, y: 0, width: 200, height: 200)
        UIGraphicsBeginImageContext(CGSize(width: 200, height: 200))
        customImage?.draw(in: newImageRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysOriginal).withTintColor(UIColor.systemYellow)
        UIGraphicsEndImageContext()
        
        return newImage
    }

}
