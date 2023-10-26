//
//  NearbyPublicInstitutionListViewController.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/21.
//

import UIKit

// Life Cycle and Variables
final class NearbyPublicInstitutionListViewController: UIViewController {
    
    @IBOutlet weak var publicInstitutionListTableView: UITableView!
    
    var publicInstitutionList: [String] = []
    
    // カメラをVCへの画面遷移メソッド
    static func instantiate() -> NearbyPublicInstitutionListViewController {
        let storyboard = UIStoryboard(name: "NearbyPublicInstitutionListView", bundle: nil)
        guard let controller = storyboard.instantiateViewController(
            withIdentifier: "NearbyPublicInstitutionListViewController"
        ) as? NearbyPublicInstitutionListViewController else {
            fatalError("NearbyPublicInstitutionListViewController could not be found.")
        }
        
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
        registerCell()
        
        publicInstitutionListTableView.delegate = self
        publicInstitutionListTableView.dataSource = self

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

// MARK: - Logic and Function
private extension NearbyPublicInstitutionListViewController {
    private func setNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        self.navigationItem.title = "近くの公共機関"
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        appearance.titleTextAttributes = textAttributes
        
        let dismissBarButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark")?.withTintColor(UIColor.black, renderingMode: .alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(dismissBarButtonAction)
        )
        self.navigationController?.navigationBar.topItem?.leftBarButtonItem = dismissBarButton
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func registerCell() {
        publicInstitutionListTableView.register(UINib(nibName: "PublicInstitutionTableViewCell", bundle: nil), forCellReuseIdentifier: "PublicInstitutionTableViewCell")
    }
    
    @objc func dismissBarButtonAction() {
        self.dismiss(animated: true)
    }
}

extension NearbyPublicInstitutionListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return publicInstitutionList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PublicInstitutionTableViewCell", for: indexPath) as? PublicInstitutionTableViewCell else {
            return UITableViewCell()
        }
        
        // MARK: - 公共機関の名前が入る
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
    }
    
    
}
