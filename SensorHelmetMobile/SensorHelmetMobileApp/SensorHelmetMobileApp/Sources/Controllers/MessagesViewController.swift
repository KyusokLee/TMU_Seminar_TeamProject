//
//  MessagesViewController.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/30.
//

import UIKit
import MessageKit

// Life Cycle and Variables
class MessagesViewController: UIViewController {
    
    var institutionName: String?
    
    // 画面遷移メソッド
    static func instantiate(with institutionName: String) -> MessagesViewController {
        let storyboard = UIStoryboard(name: "MessagesView", bundle: nil)
        guard let controller = storyboard.instantiateViewController(
            withIdentifier: "MessagesViewController"
        ) as? MessagesViewController else {
            fatalError("MessagesViewController could not be found.")
        }
        
        
        controller.loadViewIfNeeded()
        
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        setNavigationBar()
    }
    
    

}

// Logics and Functions
extension MessagesViewController {
    private func setNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        // アラームが表示されていないのにも関わらず　Toyodaの地名が入ってしまった
        if let name = institutionName {
            self.navigationItem.title = "\(name)"
        } else {
            self.navigationItem.title = "未登録の公共機関"
        }
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        appearance.titleTextAttributes = textAttributes
        
        let backBarButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left")?.withTintColor(UIColor.black, renderingMode: .alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(backBarButtonAction)
        )
        self.navigationController?.navigationBar.topItem?.leftBarButtonItem = backBarButton
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    func fetchData(with institutionName: String) {
        
    }
    
    @objc func backBarButtonAction() {
        print("Tab Back Button")
        self.navigationController?.popViewController(animated: true)
    }
}
