//
//  ChatViewController.swift
//  DyteUiKit
//
//  Created by Shaunak Jagtap on 21/01/23.
//

import UIKit
import DyteiOSCore
import MobileCoreServices
import UniformTypeIdentifiers

public class ChatViewController: DyteBaseViewController, NSTextStorageDelegate {
    // MARK: - Properties
    fileprivate var messages: [DyteChatMessage]?
    let messageTableView = UITableView()
    fileprivate let messageTextView = UITextView()
    var keyboardHeight: CGFloat = 0
    var messageTextViewHeightConstraint: NSLayoutConstraint?
    var messageTextFieldBottomConstraint: NSLayoutConstraint?
    var sendFileButtonBottomConstraint: NSLayoutConstraint?
    var sendButtonBottomConstraint: NSLayoutConstraint?
    let sendFileButton = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_chat_add"))), dyteButtonState: .focus)
    let sendImageButton = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_image"))), dyteButtonState: .active)
    let sendMessageButton = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_chat_send"))), dyteButtonState: .active)
    var documentsViewController: DocumentsViewController?
    let imagePicker = UIImagePickerController()
    let backgroundColor = DesignLibrary.shared.color.background.shade1000
    
    let spaceToken = DesignLibrary.shared.space
    let lblNoPollExist: DyteText = {
        let label = DyteUIUTility.createLabel(text: "No messages! \n\n Chat messages will appear here")
        label.accessibilityIdentifier = "No_Chat_Message_Label"
        label.numberOfLines = 0
        return label
    }()
    
    override public init(dyteMobileClient: DyteMobileClient) {
        super.init(dyteMobileClient: dyteMobileClient)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        meeting.addChatEventsListener(chatEventsListener: self)
        self.view.accessibilityIdentifier = "Chat_Screen"
        sendMessageButton.accessibilityIdentifier = "Send_Chat_Button"
        messageTextView.accessibilityIdentifier = "Input_Message_TextView"
        sendFileButton.accessibilityIdentifier = "Select_FileType_Button"
        setupViews()
        addWaitingRoom {}
        setUpReconnection(failed: {}, success: {})
        loadChatMessages()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
       
    }
    
    private func loadChatMessages() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.messages = self.meeting.chat.messages
            self.messageTextView.placeholder = "Message.."
            self.reloadMessageTableView()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
            messageTextFieldBottomConstraint = messageTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
            sendFileButtonBottomConstraint = sendFileButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
            sendButtonBottomConstraint = sendMessageButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
            messageTextFieldBottomConstraint?.constant = -keyboardHeight
            sendButtonBottomConstraint?.constant = -keyboardHeight
            sendFileButtonBottomConstraint?.constant = -keyboardHeight
            messageTextFieldBottomConstraint?.isActive = true
            sendButtonBottomConstraint?.isActive = true
            sendFileButtonBottomConstraint?.isActive = true
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        messageTextFieldBottomConstraint?.isActive = false
        sendButtonBottomConstraint?.isActive = false
        sendFileButtonBottomConstraint?.isActive = false
        
        messageTextFieldBottomConstraint?.constant = +keyboardHeight
        sendButtonBottomConstraint?.constant = +keyboardHeight
        sendFileButtonBottomConstraint?.constant = +keyboardHeight
        messageTextFieldBottomConstraint?.isActive = true
        sendButtonBottomConstraint?.isActive = true
        sendFileButtonBottomConstraint?.isActive = true
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    
    // MARK: - Setup Views
    func setupViews() {
        
        // configure messageTableView
        messageTableView.backgroundColor = backgroundColor
        messageTableView.separatorStyle = .none
        self.view.backgroundColor = backgroundColor
        messageTableView.delegate = self
        messageTableView.keyboardDismissMode = .onDrag
        messageTableView.dataSource = self
        messageTableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        messageTableView.register(FileMessageCell.self, forCellReuseIdentifier: "FileMessageCell")
        messageTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lblNoPollExist)
        lblNoPollExist.set(.centerView(view), .leading(view, spaceToken.space5))
        view.addSubview(messageTableView)
        
        // configure messageTextField
        messageTableView.rowHeight = UITableView.automaticDimension
        messageTextView.textStorage.delegate = self
        messageTextView.font = UIFont.boldSystemFont(ofSize: 14)
        messageTextView.isScrollEnabled = false
        messageTextView.backgroundColor = DesignLibrary.shared.color.background.shade900
        let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypeNameTextField ?? .rounded
        messageTextView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one,
                                                                                         radius: borderRadiusType)
        messageTextView.clipsToBounds = true
        messageTextView.delegate = self
        messageTextView.textColor = .black
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageTextView)
        
        let leftButton: DyteControlBarButton = {
            let button = DyteControlBarButton(image: DyteImage(image: ImageProvider.image(named: "icon_cross")))
            button.accessibilityIdentifier = "Cross_Button"
            return button
        }()
        leftButton.backgroundColor = navigationItem.backBarButtonItem?.tintColor
        leftButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        let customBarButtonItem = UIBarButtonItem(customView: leftButton)
        navigationItem.leftBarButtonItem = customBarButtonItem
        
        let label = DyteUIUTility.createLabel(text: "Chat")
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        navigationItem.titleView = label
        
        // configure sendButton
        let fileIcon = ImageProvider.image(named: "icon_chat_add")
        sendFileButton.setImage(fileIcon, for: .normal)
        sendFileButton.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
        view.addSubview(sendFileButton)
        if self.meeting.localUser.permissions.chat.canSendFiles {
            sendFileButton.set(.width(48))
            sendFileButton.isHidden = false
        } else {
            sendFileButton.set(.width(0))
            sendFileButton.isHidden = true
        }
        
        //        let imageIcon = ImageProvider.image(named: "icon_image")
        //        sendImageButton.setImage(imageIcon, for: .normal)
        //        sendImageButton.set(.width(48))
        //        sendImageButton.addTarget(self, action: #selector(addImageButtonTapped), for: .touchUpInside)
        //        view.addSubview(sendImageButton)
        
        
        sendMessageButton.set(.width(48))
        sendMessageButton.backgroundColor = dyteSharedTokenColor.brand.shade500
        sendMessageButton.clipsToBounds = true
        sendMessageButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        view.addSubview(sendMessageButton)
        
        
        
        // add constraints
        let constraints = [
                   messageTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                   messageTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                   messageTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                   messageTableView.bottomAnchor.constraint(equalTo: messageTextView.topAnchor, constant: -8),
                   messageTextView.trailingAnchor.constraint(equalTo: sendMessageButton.leadingAnchor, constant: -8),
                   messageTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
                   messageTextView.topAnchor.constraint(equalTo: messageTableView.bottomAnchor, constant: 8),
                   
                   sendFileButton.trailingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: -8),
                   sendFileButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
                   sendFileButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
                   
                   sendMessageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
                   sendMessageButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
               ]
        
        // configure addImageButton
        //        addImageButton.setTitle("Add Image", for: .normal)
        //        addImageButton.addTarget(self, action: #selector(addImageButtonTapped), for: .touchUpInside)
        //        addImageButton.translatesAutoresizingMaskIntoConstraints = false
        //        view.addSubview(addImageButton)
        //
        //
        //        addFileButton.setTitle("Add File", for: .normal)
        //        addFileButton.addTarget(self, action: #selector(addFileButtonTapped), for: .touchUpInside)
        //        addFileButton.translatesAutoresizingMaskIntoConstraints = false
        //        view.addSubview(addFileButton)
        
        NSLayoutConstraint.activate(constraints)
        messageTextViewHeightConstraint = messageTextView.heightAnchor.constraint(equalToConstant: 48)
        messageTextViewHeightConstraint?.isActive = true
    }
    
    private func createMoreMenu() {
        var menus = [MenuType]()
        menus.append(contentsOf: [.files, .images, .cancel])
        
        let moreMenu = DyteMoreMenu(features: menus, onSelect: { [weak self] menuType in
            switch menuType {
            case.images:
                self?.addImageButtonTapped()
            case .files:
                self?.addFileButtonTapped()
            default:
                print("Not Supported for now")
            }
        })
        moreMenu.accessibilityIdentifier = "Chat_File_Type_BottomSeet"
        moreMenu.show(on: view)
    }
    
      // MARK: - Actions
    
    @objc func goBack() {
        self.dismiss(animated: true)
    }
    
    @objc func menuTapped() {
        messageTextView.resignFirstResponder()
        createMoreMenu()
    }
    
    @objc func addFileButtonTapped() {
        var filePicker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            filePicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .plainText, .audio, .video, .movie, .image, .livePhoto], asCopy: false)
        } else {
            filePicker = UIDocumentPickerViewController(documentTypes: [], in: .import)
        }
        messageTextView.resignFirstResponder()
        filePicker.delegate = self
        present(filePicker, animated: true, completion: nil)
    }
    
    @objc func addImageButtonTapped() {
        messageTextView.resignFirstResponder()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    @objc func sendButtonTapped() {
        if !messageTextView.text.isEmpty {
            
            let spacing = CharacterSet.whitespacesAndNewlines
            let message = messageTextView.text.trimmingCharacters(in: spacing)
            try?meeting.chat.sendTextMessage(message: message)
            
            messageTextView.text = ""
            messageTextViewHeightConstraint?.constant = 48
            sendMessageButton.isEnabled = false
        }
    }
    
    private func reloadMessageTableView() {
        lblNoPollExist.isHidden = (messages?.count ?? 0) > 0 ? true : false
        messageTableView.isHidden = !lblNoPollExist.isHidden
        if (messages?.count ?? 0) > 0 {
            messageTableView.reloadData(completion: {
                DispatchQueue.main.async { [weak self] in
                    let indexPath = IndexPath(row: (self?.messages?.count ?? 1)-1, section: 0)
                    self?.messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            })
        }
    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: - UITableViewDelegate, UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (messages?.count ?? 0) > indexPath.row, messages?[indexPath.row].type == .file
        {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "FileMessageCell", for: indexPath) as? FileMessageCell, let msg = messages?[indexPath.row] as? DyteFileMessage {
                cell.fileTitleLabel.text =  msg.name
                cell.nameLabel.attributedText = MessageUtil().getTitleText(msg: msg)
                cell.fileSizeLabel.text = ByteCountFormatter.string(fromByteCount: msg.size, countStyle: .file)
                cell.fileTypeLabel.text = (URL(fileURLWithPath: msg.name).pathExtension).uppercased()
                if let fileURL = URL(string: msg.link) {
                    cell.downloadButtonAction = { [weak self] in
                        DispatchQueue.main.async {
                            cell.downloadButton.showActivityIndicator()
                        }
                        self?.documentsViewController = DocumentsViewController(documentURL: fileURL)
                        if let vc = self?.documentsViewController {
                            vc.downloadFinishAction = {
                                DispatchQueue.main.async {
                                    cell.downloadButton.hideActivityIndicator()
                                }
                            }
                            self?.present(vc, animated: true, completion: nil)
                        }
                    }
                }
                return cell
            }
            
        } else if messages?[indexPath.row].type == .image {
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as? MessageCell, let msg = messages?[indexPath.row] as? DyteImageMessage {
                if let fileURL = URL(string: msg.link) {
                    cell.message = messages?[indexPath.row]
                    cell.downloadButtonAction = { [weak self] in
                        DispatchQueue.main.async {
                            cell.downloadButton.showActivityIndicator()
                        }
                        self?.documentsViewController = DocumentsViewController(documentURL: fileURL)
                        if let vc = self?.documentsViewController {
                            vc.downloadFinishAction = {
                                DispatchQueue.main.async {
                                    cell.downloadButton.hideActivityIndicator()
                                }
                            }
                            self?.present(vc, animated: true, completion: nil)
                        }
                    }
                }
                return cell
            }
        } else if let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as? MessageCell {
            cell.message = messages?[indexPath.row]
            return cell
        }
        
        return UITableViewCell(frame: .zero)
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let url = info[UIImagePickerController.InfoKey.imageURL] as? URL {
            sendMessageButton.showActivityIndicator()
            try?self.meeting.chat.sendImageMessage(filePath: url.path, fileName: url.lastPathComponent)
        }
        dismiss(animated: true, completion: nil)
    }
}

extension ChatViewController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        sendMessageButton.showActivityIndicator()
        try?self.meeting.chat.sendFileMessage(filePath: selectedFileURL.path, fileName: selectedFileURL.lastPathComponent)
    }
}

extension ChatViewController: UITextViewDelegate {
    public func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.black {
            textView.text = nil
            textView.textColor = .lightGray
        }
    }
    public func textViewDidChange(_ textView: UITextView) {
        let spacing = CharacterSet.whitespacesAndNewlines
        if !textView.text.trimmingCharacters(in: spacing).isEmpty {
            sendMessageButton.isEnabled = true
        } else {
            sendMessageButton.isEnabled = false
        }
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
        
        if size.height > 48 {
            messageTextFieldBottomConstraint?.isActive = true
            sendButtonBottomConstraint?.isActive = true
            sendFileButtonBottomConstraint?.isActive = true
        }
        
        messageTextViewHeightConstraint?.constant = size.height > 48 ? size.height : 48
        view.layoutIfNeeded()
    }
}

extension ChatViewController: DyteChatEventsListener {
    public func onNewChatMessage(message: DyteChatMessage) {
        if message.userId != meeting.localUser.userId {
            var chat = ""
            if  let textMessage = message as? DyteTextMessage {
                chat = "\(textMessage.displayName): \(textMessage.message)"
            }else {
                if message.type == DyteMessageType.image {
                    chat = "\(message.displayName): Send you an Image"
                } else if message.type == DyteMessageType.file {
                    chat = "\(message.displayName): Send you an File"
                }
            }
            notificationDelegate?.didReceiveNotification(type: .Chat(message:chat))
        }
    }
    
    public  func onChatUpdates(messages: [DyteChatMessage]) {
        if isOnScreen {
            NotificationCenter.default.post(name: Notification.Name("NotificationAllChatsRead"), object: nil)
        }
        sendMessageButton.hideActivityIndicator()
        self.messages = meeting.chat.messages
        reloadMessageTableView()
    }
}

public extension UITableView {
    
    func reloadData(completion: @escaping () -> ()) {
        UIView.animate(withDuration: 0, animations: {
            self.reloadData()
        }, completion: { _ in
            completion()
        })
    }
    
    func scrollToFirstCell() {
        if numberOfSections > 0 {
            if numberOfRows(inSection: 0) > 0 {
                scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }
    
    func scrollToLastCell(animated: Bool) {
        if numberOfSections > 0 {
            let nRows = numberOfRows(inSection: numberOfSections - 1)
            if nRows > 0 {
                scrollToRow(at: IndexPath(row: nRows - 1, section: numberOfSections - 1), at: .bottom, animated: animated)
            }
        }
    }
    
    func stopScrolling() {
        
        guard isDragging else {
            return
        }
        
        var offset = self.contentOffset
        offset.y -= 1.0
        setContentOffset(offset, animated: false)
        
        offset.y += 1.0
        setContentOffset(offset, animated: false)
    }
    
    func scrolledToBottom() -> Bool {
        return contentOffset.y >= (contentSize.height - bounds.size.height)
    }
}

extension UITextView {
    
    private class PlaceholderLabel: UILabel { }
    
    private var placeholderLabel: DyteText {
        if let label = subviews.compactMap( { $0 as? DyteText }).first {
            return label
        } else {
            let label = DyteUIUTility.createLabel(alignment: .left)
            label.font = UIFont.boldSystemFont(ofSize: 14)
            label.textColor = dyteSharedTokenColor.textColor.onBackground.shade700
            label.numberOfLines = 0
            label.font = font
            addSubview(label)
            return label
        }
    }
    
    @IBInspectable
    var placeholder: String {
        get {
            return subviews.compactMap( { $0 as? PlaceholderLabel }).first?.text ?? ""
        }
        set {
            let placeholderLabel = self.placeholderLabel
            placeholderLabel.text = newValue
            placeholderLabel.numberOfLines = 0
            let width = frame.width - textContainer.lineFragmentPadding * 2
            let size = placeholderLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            placeholderLabel.frame.size.height = size.height
            placeholderLabel.frame.size.width = width
            placeholderLabel.frame.origin = CGPoint(x: textContainer.lineFragmentPadding, y: textContainerInset.top)
            
            textStorage.delegate = self
        }
    }
    
}

extension UITextView: NSTextStorageDelegate {
    
    public func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        if editedMask.contains(.editedCharacters) {
            placeholderLabel.isHidden = !text.isEmpty
        }
    }
    
}
