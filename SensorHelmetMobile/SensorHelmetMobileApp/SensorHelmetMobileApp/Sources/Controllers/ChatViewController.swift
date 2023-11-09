//
//  MessagesViewController.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/30.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseFirestore

// Life Cycle and Variables
// MessagesViewControllerは, MessageKitのUIを表示するVC
class ChatViewController: MessagesViewController {
    
    var institutionName: String?
    // グローバル変数
    var sender = Sender(senderId: "any_unique_id", displayName: "jake")
    var messages = [Message]()
    
    // 画面遷移メソッド
    static func instantiate(with institutionName: String) -> ChatViewController {
        let storyboard = UIStoryboard(name: "MessagesView", bundle: nil)
        guard let controller = storyboard.instantiateViewController(
            withIdentifier: "ChatViewController"
        ) as? ChatViewController else {
            fatalError("ChatViewController could not be found.")
        }
        
        controller.fetchData(with: institutionName)
        controller.loadViewIfNeeded()
        
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        confirmDelegates()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
         setNavigationBar()
    }
    
    

}

// Logics and Functions
extension ChatViewController {
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
        // 簡単にback Buttonを Customizeする方法
        // ただし、chevron.leftのimageの色を消すだけ
        // また、"Back"というdefault文字を消す
        self.navigationController?.navigationBar.topItem?.backButtonTitle = ""
        self.navigationController?.navigationBar.tintColor = UIColor.black
        
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        appearance.titleTextAttributes = textAttributes
        
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.compactAppearance = appearance
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    func fetchData(with institutionName: String) {
        self.institutionName = institutionName
    }
    
    func confirmDelegates() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    // UIを管轄するメソッド
    // 鮮やかな青色 #1E90FFを採択
    func setupUI() {
        messagesCollectionView.backgroundColor = UIColor.secondarySystemBackground
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.image = UIImage(systemName: "paperplane")?.withTintColor(UIColor(rgb: 0x1E90FF), renderingMode: .alwaysOriginal)
    }
}

extension ChatViewController: MessagesDataSource {
    
    // 現在の送信者
    var currentSender: SenderType {
        return sender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageType {
        
        // 従来のindexPath.rowではなく、indexPath.sectionでメッセージ (MessageType) を取得
        // MessageKitではMessageTypeをMessagesCollectionViewの独自セクションに配置するため
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
    
}

extension ChatViewController: MessagesLayoutDelegate {
    // 下の余白
    func footerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 0, height: 8)
    }
        
    // 吹き出しの上にある名前が出るところのheight
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 20
    }
}

// ViewのUIに関するProtocol
// 相手が送ってるのであれば左側、自分が送ってるのであれば右側に吹き出しを配置する機能は内部で既に実装されている
extension ChatViewController: MessagesDisplayDelegate {
    // 吹き出しの背景の色
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ?
        UIColor(rgb: 0x1E90FF) : UIColor.systemBackground
    }
      
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .black : .white
    }
      
    // 吹き出しのしっぽの方向
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let cornerDirection: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(cornerDirection, .curved)
    }
    
    // プロフィールViewの設定 (Avatar View)
    
}

// 入力バーに関するProtocol
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message(content: text)
        
        
//        insertNewMessage(message)
        inputBar.inputTextView.text.removeAll()
    }
}
