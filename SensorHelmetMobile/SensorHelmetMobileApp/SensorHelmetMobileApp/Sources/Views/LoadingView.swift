//
//  LoadingView.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/01/20.
//

import UIKit

// URLSessionTaskのcancelの代わりにloadingViewを表示することで、task cancelと類似なロジックを与える
final class LoadingView: UIView {
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = UIColor.white
        view.hidesWhenStopped = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "ただいま、データを読み込んでいます"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var isLoading = false {
        didSet {
            self.isHidden = !self.isLoading
            self.isLoading ? self.activityIndicatorView.startAnimating() : self.activityIndicatorView.stopAnimating()
      }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.backgroundView)
        self.addSubview(self.activityIndicatorView)
        self.addSubview(self.titleLabel)
        // LoadingViewのbackgroundViewのconstraints設定
        NSLayoutConstraint.activate([
            self.backgroundView.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.backgroundView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.backgroundView.topAnchor.constraint(equalTo: self.topAnchor)
        ])
        
        // activityIndicatorViewのconstraints設定
        NSLayoutConstraint.activate([
            self.activityIndicatorView.heightAnchor.constraint(equalToConstant: 100),
            self.activityIndicatorView.widthAnchor.constraint(equalToConstant: 100),
            self.activityIndicatorView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.activityIndicatorView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        // titleLabelのconstraints設定
        NSLayoutConstraint.activate([
            self.titleLabel.heightAnchor.constraint(equalToConstant: 300),
            self.titleLabel.widthAnchor.constraint(equalToConstant: 300),
            self.titleLabel.centerXAnchor.constraint(equalTo: self.activityIndicatorView.centerXAnchor),
            self.titleLabel.centerYAnchor.constraint(equalTo: self.activityIndicatorView.topAnchor, constant: 90)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("LoadingView.swift don't use NibFile.")
    }
}
