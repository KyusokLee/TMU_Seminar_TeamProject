//
//  HelmetUserInfoTableViewCell.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/12/04.
//

import UIKit

protocol HelmetUserInfoTableViewCellDelegate: AnyObject {
    func createChatRoomView(userName: String)
    func showTappedLocationRoute()
}

class HelmetUserInfoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var helmetImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var routeButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    
    lazy var guideLabel: UILabel = {
        let label = UILabel()
        label.text = "メッセージ機能はヘルメット装着後, 利用可能です"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor.systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    // MARK: - messageButtonを使うためにどのような処理をすればいいかを表すguide label
    
    // falseでdefault設定
    var isAvailableToMessage: Bool = false
    var userName: String = ""
    // Delegateパータンは必ずWeak varで弱い参照にするようにする
    weak var delegate: HelmetUserInfoTableViewCellDelegate?
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let button = messageButton {
        // messageButtonをタップした場合のevent伝達
            let buttonPoint = convert(point, to: button)
            if button.point(inside: buttonPoint, with: event) {
                return true
            }
        }
        return false // messageButtonを除いた領域をtouch無視
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        setupUI()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // MARK: - Buttonがtouchされない
    @IBAction func didTapMessageButton(_ sender: Any) {
        print("Tap Button in cell")
        delegate?.createChatRoomView(userName: self.userName)
    }
    
    @IBAction func didTapRouteButton(_ sender: Any) {
        print("Tap show routeButton!")
        
    }
    
}

extension HelmetUserInfoTableViewCell {
    // MARK: - Helmetユーザの名前, 位置情報, 現在ユーザのヘルメット着用状態をここで設定
    // MARK: isConnected　-> スマホユーザのヘルメット着用状態を示す
    func configure(placeName: String?, userName: String, isConnected: Bool) {
        self.isAvailableToMessage = isConnected
        self.userName = userName
        userNameLabel.text = userName + "ユーザ"
        
        if let placeString = placeName {
            locationLabel.textColor = .black.withAlphaComponent(0.85)
            locationLabel.text = placeString
        } else {
            locationLabel.textColor = .systemRed.withAlphaComponent(0.7)
            locationLabel.text = "位置情報の取得に失敗しました"
        }
        
        // Configureの段階でUIを設定できるようにすると
        setupUI(canSendMessage: self.isAvailableToMessage)
    }
    
    func setupUI(canSendMessage isAvailableToMessage: Bool) {
        self.addSubview(guideLabel)
//        // tabelView Cellのタップをできないようにする
//        self.selectionStyle = .none
        // ButtonがTableViewCellのtouchイベントを邪魔しないように設定
        
        setupFont()
        setupImageView()
        setupMessageButton(canSendMessage: isAvailableToMessage)
        setupGuideLabelButton(canSendMessage: isAvailableToMessage)
    }
    
    func setGuideLabelConstraints(canSendMessage isAvailable: Bool) {
        // layoutを分岐する
        if isAvailable {
            // Helmetを着用した場合
            // Activateしたのを全部無効にしてからじゃないとlayoutの衝突になる
            NSLayoutConstraint.deactivate([
                guideLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                guideLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 15),
                guideLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10)
            ])
            
            NSLayoutConstraint.activate([
                guideLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                guideLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 0),
                guideLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
            ])
        } else {
            NSLayoutConstraint.deactivate([
                guideLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                guideLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 0),
                guideLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
            ])
            // Helmetを着用しておらず、着用に関するガイド文句を表示するべきである場合
            NSLayoutConstraint.activate([
                guideLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                guideLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 15),
                guideLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10)
            ])
        }
    }
    
    func setupGuideLabelButton(canSendMessage isAvailable: Bool) {
        guideLabel.isHidden = isAvailable
        setGuideLabelConstraints(canSendMessage: isAvailable)
    }
        
    func setupFont() {
        userNameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        locationLabel.font = .systemFont(ofSize: 15, weight: .medium)
    }
    
    // 考察: imageViewのheightを固定値にしたい場合は、bottomAnchoerやtopAnchorを他のUIにalignさせるとより調整しやすいかも
    // propertyやstackViewを使う方法もある
    func setupImageView() {
        let image = UIImage(named: "helmetBasic")?.withRenderingMode(.alwaysOriginal).withTintColor(UIColor(rgb: 0xF57C00))
        let size = CGSize(width: 35, height: 35)
        UIGraphicsBeginImageContext(size)
        image?.draw(in: CGRect(x: 1.7, y: 0, width: size.width - 4, height: size.height - 4))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        helmetImageView.backgroundColor = .white
        helmetImageView.layer.masksToBounds = true
        helmetImageView.layer.cornerRadius = helmetImageView.frame.height / 2
        helmetImageView.layer.borderWidth = 0.8
        helmetImageView.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.85).cgColor
        helmetImageView.image = resizedImage
    }
    
    func setupMessageButton(canSendMessage isAvailable: Bool) {
        let image = UIImage(systemName: "envelope.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 35))
            .withTintColor(
                UIColor.systemBlue.withAlphaComponent(0.85),
                renderingMode: .alwaysOriginal
            )
        messageButton.backgroundColor = UIColor.systemBackground
        messageButton.setImage(image, for: .normal)
        
        if isAvailable {
            messageButton.isUserInteractionEnabled = true
            messageButton.isEnabled = true
        } else {
            messageButton.isUserInteractionEnabled = false
            messageButton.isEnabled = false
        }
    }
    
    // MARK: - タップした位置までの経路を表示するボタン
    func setupRouteButton() {
        
    }
}
