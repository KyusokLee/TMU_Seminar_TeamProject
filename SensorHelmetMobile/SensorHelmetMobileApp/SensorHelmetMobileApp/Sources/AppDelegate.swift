//
//  AppDelegate.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2022/12/12.
//

import UIKit
import FirebaseCore
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

// アプリが実行されているときも、Pushのアラームが来るように
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Push通知を受信したら、実行されるメソッド
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        if notification.request.identifier == "DisasterOccurNotification" {
            let userInfo = notification.request.content.userInfo
            let placeName = userInfo["locationLocalName"] as! String
            print("災害が起きた場所は\(placeName)")
        }
        
        // MARK: - placeNameをMapVCとNearByVCまで渡す方法を実装する予定
        completionHandler([.list, .banner])
    }
    
    // Local PushがTriggerされるたびに呼び出される
    // messageをTouchしたときの間数
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let notification = response.notification.request
        // タップした通知の識別子を読み込む
        let identifier = notification.identifier
        // userInfo
        let userInfo = notification.content.userInfo
        // window
        let window = UIApplication.shared.windows.first
        let application = UIApplication.shared
        
        //　Applicationのstateによって処理を変える
        switch application.applicationState {
        case .active:
            NotificationCenter.default.post(name: Notification.Name("didReceivePushTouch"), object: nil, userInfo: userInfo)
        case .inactive:
            NotificationCenter.default.post(name: Notification.Name("didReceivePushTouch"), object: nil, userInfo: userInfo)
        case .background:
            guard let notiKey = userInfo["locationLocalName"]! as? String else { return }
                
            let userDefault = UserDefaults.standard
            userDefault.set(notiKey, forKey: "NOTIFICATION_KEY")
            userDefault.synchronize()
        default:
            print("Undefined Application State")
        }
        
        if let locationName = userInfo["locationLocalName"] as? String {
            // 特定のViewControllerにデータを渡し、画面をUpdate
            // MapVCにPinを立てる作業(UIの変更)
            print(locationName)
            if let mainViewController = window?.rootViewController as? ViewController {
                mainViewController.getDisasterOccurLocationData(placeName: locationName)
            }
        }
        print("didReceive - identifier: \(identifier)")
        print("didReceive - UserInfo: \(userInfo)")
        
        completionHandler()
    }
}
