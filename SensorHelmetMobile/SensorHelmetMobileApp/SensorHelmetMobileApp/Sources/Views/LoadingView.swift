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
        view.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
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
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.text = "データを読み込み中..."
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
            self.backgroundView.heightAnchor.constraint(equalToConstant: 150),
            self.backgroundView.widthAnchor.constraint(equalToConstant: 150),
            self.backgroundView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.backgroundView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        // activityIndicatorViewのconstraints設定
        NSLayoutConstraint.activate([
            self.activityIndicatorView.heightAnchor.constraint(equalToConstant: 50),
            self.activityIndicatorView.widthAnchor.constraint(equalToConstant: 50),
            self.activityIndicatorView.centerXAnchor.constraint(equalTo: self.backgroundView.centerXAnchor),
            self.activityIndicatorView.centerYAnchor.constraint(equalTo: self.backgroundView.centerYAnchor)
        ])
        
        // titleLabelのconstraints設定
        NSLayoutConstraint.activate([
            self.titleLabel.widthAnchor.constraint(equalToConstant: 140),
            self.titleLabel.centerXAnchor.constraint(equalTo: self.backgroundView.centerXAnchor),
            self.titleLabel.centerYAnchor.constraint(equalTo: self.backgroundView.bottomAnchor, constant: -20)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("LoadingView.swift don't use NibFile.")
    }
}
