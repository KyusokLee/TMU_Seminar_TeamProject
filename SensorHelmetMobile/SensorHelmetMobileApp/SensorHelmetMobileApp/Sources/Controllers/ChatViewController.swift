//
//  MessagesViewController.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/10/30.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Photos
import FirebaseFirestore
import FirebaseStorage

// Life Cycle and Variables
// MessagesViewControllerは, MessageKitのUIを表示するVC
class ChatViewController: MessagesViewController {
    
    // CameraButton
    // 現在位置も一緒に送れるようにしたい
    lazy var cameraBarButtonItem: InputBarButtonItem = {
        let button = InputBarButtonItem(type: UIButton.ButtonType.system)
        button.image = UIImage(systemName: "camera")?
            .withTintColor(
                UIColor(rgb: 0x1E90FF),
                renderingMode: .alwaysOriginal
            )
        button.addTarget(self, action: #selector(didTapCameraButton), for: .touchUpInside)
        return button
    }()
    
    private var isSendingPhoto = false {
        didSet {
            messageInputBar.leftStackViewItems.forEach { item in
                guard let item = item as? InputBarButtonItem else {
                    return
                }
                item.isEnabled = !self.isSendingPhoto
            }
        }
    }
    
    var institutionName: String?
    var institutionType: String?
    // 送信者のId Number分岐
    // helmetのユーザじゃない場合: institutionNameがユーザ名となる
    // MARK: - chatRoomId -> 話し相手が誰かを特定するid
    // MARK: - userId -> ヘルメットユーザか公共機関であるかを示すインスタンス
    // MARK: - MessageのuserIdに格納する値はuserIdである
    var chatRoomId: String?
    var userId: String?
    var occurPlace: String?
    // グローバル変数
    var sender = Sender(senderId: "", displayName: "")
    var messages = [Message]()
    let customFirestore = CustomFirestore()
    
    // 画面遷移メソッド
    static func instantiate(with institutionName: String, type institutionType: String, occurPlace placeName: String, chatRoomNum chatRoomIdentifier: String?, userId userIdentifier: String?) -> ChatViewController {
        let storyboard = UIStoryboard(name: "MessagesView", bundle: nil)
        guard let controller = storyboard.instantiateViewController(
            withIdentifier: "ChatViewController"
        ) as? ChatViewController else {
            fatalError("ChatViewController could not be found.")
        }
        
        controller.fetchData(
            with: institutionName,
            type: institutionType,
            occurPlace: placeName,
            chatRoomNum: chatRoomIdentifier,
            userId: userIdentifier
        )
        controller.loadViewIfNeeded()
        
        return controller
    }
    
    // Viewを再定義するメソッド
    override func loadView() {
        // 今回はRootViewを再設定するわけではないので、super.loadViewをしないといけない
        // super.loadViewをしちゃいけない場合は、rootView自体を新しく再定義する場合であり、rootViewの下のViewをカストマイズするばあいは、super.loadView()をする
        super.loadView()
        
        // ここで、カストマイズしたChatMessagesCollectionViewを既存のmessagesCollectionViewにかぶせる作業をする
        let collectionView = ChatMessagesCollectionView()
        collectionView.collectionDelegate = self
        messagesCollectionView = collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupController()
        setupUI()
        // リアルタイムにデータベースの更新を行うため、Listenerを設定
        setupMessageListener()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("Keyboardを表示")
        self.messageInputBar.inputTextView.becomeFirstResponder()
        self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        setNavigationBar()
    }
    
    // deinitでメモリ解放
    deinit {
        //　チャットルームを抜けるとき、listenrの削除する
        customFirestore.removeListener()
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
    
    // MARK: - fetchDataでデータ送信先、データを送る側のユーザ (id)のデータを同期させる
    // userがないときもあるから
    // userIdがないときは、公共機関
    // MARK: - chatRoomIdentifier: 公共機関がメッセージを送信する場合もその送信先がどのユーザであるかを指定する必要があった
    // MARK: - そのため、chatRoomIdentifierをパラメータとして設けることにした
    func fetchData(with institutionName: String, type institutionType: String, occurPlace placeName: String, chatRoomNum chatRoomIdentifier: String?, userId userIdentifier: String?) {
        self.institutionName = institutionName
        self.institutionType = institutionType
        self.occurPlace = placeName
        
        // MARK: - ヘルメット着用したユーザだけ、公共機関とのメッセージなどのやりとりを可能にし、無分別なトラフィック量を調節する
        guard let chatRoomId = chatRoomIdentifier else {
            print("ChatRoom does not exist because of no specified chat user")
            navigationController?.popViewController(animated: true)
            return
        }
        
        // ChatRoomのIdを設定
        self.chatRoomId = chatRoomId
        // MARK: - システム流れ的にchatRoomVCに入る前にユーザがヘルメットのユーザか、公共機関であるかを分類しておく
        
        if let userId = userIdentifier {
            // HelmetのUserIdがある場合 (ヘルメットユーザである場合)
            self.userId = userId
            self.sender.displayName = userId
            self.sender.senderId = userId
        } else {
            // helmetのユーザではなく、公共機関の場合
            // userIdをinstitutionNameにする
            self.userId = self.institutionType
            self.sender.displayName = self.institutionName ?? "未設定"
            // typeでidの分岐を行う
            self.sender.senderId = self.institutionType ?? "未設定"
        }
    }
    
    func setupController() {
        confirmDelegates()
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
        
        setupMessageInputBar()
        addCameraBarButtonToMessageInputBar()
    }
    
    private func setupMessageInputBar() {
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.layer.cornerRadius = 15
        messageInputBar.inputTextView.tintColor = .white
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.image = UIImage(systemName: "paperplane")?.withTintColor(
            UIColor(rgb: 0x1E90FF),
            renderingMode: .alwaysOriginal
        )
        messageInputBar.inputTextView.placeholder = "メッセージを入力"
    }
    
    // 使うかどうかまだ未決定
    func removeOutgoingMessageAvatars() {
        guard let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout else { return }
        layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
        layout.setMessageOutgoingAvatarSize(.zero)
        
        let outgoingLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15))
        layout.setMessageOutgoingMessageTopLabelAlignment(outgoingLabelAlignment)
    }

    
    func addCameraBarButtonToMessageInputBar() {
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        messageInputBar.setStackViewItems([cameraBarButtonItem], forStack: .left, animated: false)
    }

    
    // Messageを全部持ってくる
    func setupMessageListener() {
        guard let place = occurPlace else {
            navigationController?.popViewController(animated: true)
            return
        }
        
        guard let institutionType = self.institutionType else {
            navigationController?.popViewController(animated: true)
            return
        }
        
        // MARK: - Messageを全部取得
        // MARK: - subscribeで特定のplace, institutionType, chatRoomId(チャット相手)を指定し、データを持ってくる
        // MARK: - completionで指定したDirectory内のthreadにある複数のメッセージを取得する
        customFirestore.subscribe(place, institutionType, chatRoomId: self.chatRoomId ?? "") { [weak self] result in
            switch result {
            case .success(let messages):
                self?.loadImageAndUpdateCells(messages)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: - Messageのデータfetch
    // MARK: - 複数のmessageを持ってくる
    func loadImageAndUpdateCells(_ messages: [Message]) {
        messages.forEach { message in
            var message = message
            
            if let url = message.downloadURL {
                // messageにimage（画像ファイル）がある場合
                FirebaseStorageManager.downloadImage(url: url) { [weak self] image in
                    guard let image = image else { return }
                    message.image = image
                    self?.insertNewMessage(message)
                }
            } else {
                insertNewMessage(message)
            }
        }
    }
    
    func insertNewMessage(_ message: Message) {
        messages.append(message)
        // MARK: - senderId別にMessageをくくり、また、メッセージの日付順にメッセージを表示させるためのソート
        messages.sort()
            
        messagesCollectionView.reloadData()
    }
    
    func dismissKeyboard() {
        self.messageInputBar.inputTextView.resignFirstResponder()
    }
    
    // ラズパイのカメラだけを連結するようにしたい
    // MARK: - 目指している機能: tapしてラズパイにつけたカメラから写真を撮るようにしたい
    @objc func didTapCameraButton() {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        if let sheet = picker.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        
        self.present(picker, animated: true)
    }
}

// Message DataSource
extension ChatViewController: MessagesDataSource {
    
    // 現在の送信者 (アプリのユーザ)
    // senderIdは公共機関の場合institutionTypeに、displayNameはinstitutionNameになるように設定
    // helmetの場合　userIdとdisplayName両方とも 同じくする
    var currentSender: SenderType {
        return Sender(senderId: self.userId ?? (self.institutionType ?? ""), displayName: self.userId ?? (self.institutionName ?? ""))
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageType {
        // 従来のindexPath.rowではなく、indexPath.sectionでメッセージ (MessageType) を取得
        // MessageKitではMessageTypeをMessagesCollectionViewの独自セクションに配置するため
        return messages[indexPath.section] as MessageType
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    // messageTopLabelの属性テキスト(UserName)
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let profileName = messages[indexPath.section].sender.displayName
        
        return NSAttributedString(
            string: profileName,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .caption1),
                .foregroundColor: UIColor(white: 0.3, alpha: 1)
            ]
        )
    }

    // messageBottomLabelの属性テキスト
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        // Date型
        // メッセージを送信した日付と時刻
        let messageDate = messages[indexPath.section].sentDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatter.dateFormat(
            fromTemplate: "yyyy年MM月dd日, HH:mm",
            options: 0,
            locale: Locale(identifier: "ja_JP")
        )
        
        // MARK: - FireStoreに格納したTimestamp型の日付データを表示したい様式に変換する作業
        return NSAttributedString(
            string: dateFormatter.string(from: messageDate),
            attributes: [
                .font: UIFont.systemFont(ofSize: 12.0),
                .foregroundColor: UIColor.black
            ]
        )
    }
    
    
}

// Message Layout
extension ChatViewController: MessagesLayoutDelegate {
    func headerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize.zero
    }
    
    // 下の余白
    func footerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 0, height: 8)
    }
        
    // 吹き出しの上にある名前が出るところのheight
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 20
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 20
    }
}

// ViewのUIに関するProtocol
// 相手が送ってるのであれば左側、自分が送ってるのであれば右側に吹き出しを配置する機能は内部で既に実装されている
// MARK: - Infoの部分でLightにしたので、ダークモードにならない
extension ChatViewController: MessagesDisplayDelegate {
    // 吹き出しの背景の色
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ?
        UIColor(rgb: 0x1E90FF) : UIColor.systemBackground
    }
      
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ?
            UIColor.white : UIColor.black
    }
      
    // 吹き出しのしっぽの方向
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let cornerDirection: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(cornerDirection, .curved)
    }
    
    // avaterViewの設定 (ユーザのprofile画像ってこと)
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = messages[indexPath.section].sender
        // imageSizeの変更
        var size = CGSize()
        
        // MARK: - Messageの中のsenderIdで分類するべき
        // MARK: - fetch速度がどれくらい速いかはわからない -> 同期されるかを試す
        if sender.senderId.range(of: "helmet") != nil {
            // helmet ユーザの場合
            let image = UIImage(named: "helmetBasic")?.withRenderingMode(.alwaysOriginal).withTintColor(UIColor(rgb: 0xF57C00))
            size = CGSize(width: 35, height: 35)
            UIGraphicsBeginImageContext(size)
            image?.draw(in: CGRect(x: 1.7, y: 0, width: size.width - 4, height: size.height - 4))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            avatarView.backgroundColor = .white
            avatarView.image = resizedImage
        } else {
            // 公共機関の場合
            // システム上、senderIdにinstitutionTypeが入ることになる
            let image = UIImage(named: sender.senderId)?.withTintColor(.black, renderingMode: .alwaysOriginal)
            size = CGSize(width: 35, height: 35)
            UIGraphicsBeginImageContext(size)
            image?.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            avatarView.backgroundColor = .white
            avatarView.image = resizedImage
        }
    }
    
    // MARK: - 相手は公共機関の場合　-> 指定した公共機関に画像imageがfetchされる
    // もし、ヘルメットユーザの場合は、Helmetの画像がfetchされる
}

// MARK: - 入力バーに関するProtocol(Sendボタンをタップしたときのイベント処理)
//  - 公共機関のアプリに関する機能は実装しないつもり　-> 要するに、ユーザのものだけ実装すればいい
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // 内容が何もないときの処理は省略
        // message ID がhelmetIDである
        // MARK: - userId: SenderのsendId
        // MARK: - userName: SenderのdisplayNameに　当てはまるようにカストマイズした
        // MARK: - 公共機関の場合　userIdはinstitutionTypeになるように
        var profileName = ""
        if self.userId == self.institutionType {
            // 公共機関の場合
            profileName = self.institutionName ?? ""
        } else if self.userId != self.institutionType {
            // ヘルメットユーザの場合
            profileName = self.userId ?? ""
        }
        
        let message = Message(userId: self.userId ?? "", userName: profileName, content: text)
        // MARK: - 公共機関が送ったメッセージもMessageのUserIDを公共機関ではなく、チャットをしているヘルメットユーザにするべきである
        // ここをうまく整理して、システムを確立すること
        customFirestore.save(self.occurPlace ?? "", self.institutionType ?? "", self.chatRoomId ?? "", message) { [weak self] error in
            if let error = error {
                print("ChatViewController inputBar Message Save Error: \(error.localizedDescription)")
                return
            }
            self?.messagesCollectionView.scrollToLastItem()
        }
        
        inputBar.inputTextView.text.removeAll()
    }
    
    
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let asset = info[.phAsset] as? PHAsset {
            let imageSize = CGSize(width: 500, height: 500)
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: imageSize,
                contentMode: .aspectFit,
                options: nil
            ) { image, _ in
                guard let image = image else { return }
                self.sendPhoto(image)
            }
        } else if let image = info[.originalImage] as? UIImage {
            sendPhoto(image)
        }
    }
    
    // 写真を送る方法
    private func sendPhoto(_ image: UIImage) {
        isSendingPhoto = true
        var profileName = ""
        if self.userId == self.institutionType {
            // 公共機関の場合
            profileName = self.institutionName ?? ""
        } else if self.userId != self.institutionType {
            // ヘルメットユーザの場合
            profileName = self.userId ?? ""
        }
        // MARK: - FetchDataの段階でuserIdがnil ("")の場合 -> 公共機関の名前を格納する作業をした
        // MARK: - そのため、userIdはself.userIdにしても正常に分岐されるはず
        FirebaseStorageManager.uploadImage(
            image: image,
            place: self.occurPlace ?? "",
            institutionType: self.institutionType ?? "",
            chatRoomId: self.chatRoomId ?? "",
            userId: self.userId ?? ""
        ) { [weak self] url in
            self?.isSendingPhoto = false
            
            guard let url = url else { return }
            
            var message = Message(userId: self?.userId ?? "", userName: profileName, image: image)
            message.downloadURL = url
            self?.customFirestore.save(
                self?.occurPlace ?? "",
                self?.institutionType ?? "",
                self?.chatRoomId ?? "",
                message
            )
            self?.messagesCollectionView.scrollToLastItem()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - MessageCellDelegate
extension ChatViewController: MessageCellDelegate {
    
    //MARK: - Cellのバックグラウンドをタップした時の処理
    func didTapBackground(in cell: MessageCollectionViewCell) {
        print("バックグラウンドタップ")
        dismissKeyboard()
    }

    //MARK: - メッセージをタップした時の処理
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("メッセージタップ")
        dismissKeyboard()
    }

    //MARK: - アバターをタップした時の処理
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("アバタータップ")
        dismissKeyboard()
    }

    //MARK: - メッセージ上部をタップした時の処理
    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        print("メッセージ上部タップ")
        dismissKeyboard()
    }

    //MARK: - メッセージ下部をタップした時の処理
    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        print("メッセージ下部タップ")
        dismissKeyboard()
    }
}

extension ChatViewController: MessagesCollectionViewDelegate {
    func didTap() {
        dismissKeyboard()
    }
}

// 他のファイルで指定するとうまく動かなかったので、ここで実装
protocol MessagesCollectionViewDelegate: AnyObject {
    func didTap()
}

// MessagesCollectionViewを継承するSubClassを定義
class ChatMessagesCollectionView: MessagesCollectionView {
    weak var collectionDelegate: MessagesCollectionViewDelegate?

    override func handleTapGesture(_ gesture: UIGestureRecognizer) {
        super.handleTapGesture(gesture)
        
        collectionDelegate?.didTap()
    }
}
