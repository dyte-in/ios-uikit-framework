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

public class DyteChatViewController: DyteBaseViewController, NSTextStorageDelegate {
    // MARK: - Properties
    fileprivate var messages: [DyteChatMessage]?
    let messageTableView = UITableView()
    fileprivate let messageTextView = UITextView()
    var keyboardHeight: CGFloat = 0
    var messageTextViewHeightConstraint: NSLayoutConstraint?
    var messageTextFieldBottomConstraint: NSLayoutConstraint?
    var sendFileButtonBottomConstraint: NSLayoutConstraint?
    var sendButtonBottomConstraint: NSLayoutConstraint?
    var selectedParticipant: DyteJoinedMeetingParticipant?
    static let keyEveryOne = "everyone"
    private let everyOneText = "Everyone in meeting"
    let chatSelectorLabel = DyteUIUTility.createLabel()
    public var notificationBadge = DyteNotificationBadgeView()
    private var isNewChatAvailable : Bool = false
    
    let sendFileButtonDisabledView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignLibrary.shared.color.background.shade1000
        view.alpha = 0.8
        return view
    }()
    
    let sendTextViewDisabledView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignLibrary.shared.color.background.shade1000
        view.alpha = 0.8
        return view
    }()
    
    let sendFileButton = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_chat_add"))), dyteButtonState: .focus)
    let sendImageButton = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_image"))), dyteButtonState: .active)
    let sendMessageButton = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_chat_send"))), dyteButtonState: .active)
    
    var documentsViewController: DocumentsViewController?
    let imagePicker = UIImagePickerController()
    let backgroundColor = DesignLibrary.shared.color.background.shade1000
    
    let spaceToken = DesignLibrary.shared.space
    let lblNoPollExist: DyteLabel = {
        let label = DyteUIUTility.createLabel(text: "No messages! \n\n Chat messages will appear here")
        label.accessibilityIdentifier = "No_Chat_Message_Label"
        label.numberOfLines = 0
        return label
    }()
    
    let activityIndicator = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = DesignLibrary.shared.color.brand.shade500
        indicator.startAnimating()
        return indicator
    }()
    
    var viewDidAppear = false
    var messageLoaded = false
    let meetingObserver: DyteMeetingEventListner
    private var participantSelectionController: ChatParticipantSelectionViewController?
    override public init(meeting: DyteMobileClient) {
        meetingObserver = DyteMeetingEventListner(mobileClient: meeting)
        super.init(meeting: meeting)
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
        addPermissionUpdateObserver()
        meetingObserver.observeParticipantLeave { [weak self] participant in
            guard let self = self else{ return }
            self.removeParticipant(participantUserId: participant.userId)
        }
        
        meetingObserver.observeParticipantJoin { [weak self] participant in
            guard let self = self else { return }
            if let cont = self.participantSelectionController {
                var participants = meeting.participants.joined
                participants.removeAll { participant in
                    participant.id == self.meeting.localUser.id
                }
                cont.setParticipants(participants: participants)
                cont.onParticipantJoin(userId: participant.userId)
            }
        }
        
        showNotiificationBadge()
    }
    
  
    @objc func showChatParticipantSelectionOverlay() {
        let viewCont = ChatParticipantSelectionViewController()
        var participants = meeting.participants.joined
        participants.removeAll { participant in
            participant.id == meeting.localUser.id
        }
        viewCont.setParticipants(participants: participants)
        viewCont.delegate = self
        viewCont.selectedParticipant = selectedParticipant
        viewCont.modalPresentationStyle = .fullScreen
        let popoverPresentationController = viewCont.popoverPresentationController
        popoverPresentationController?.sourceView = self.view
        popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        popoverPresentationController?.permittedArrowDirections = []
        present(viewCont, animated: true, completion: nil)
        viewCont.addTopBar(dismissAnimation: true) { [weak self]  in
               guard let self = self else {return}
               self.participantSelectionController = nil
               self.didSelectChat(withParticipant: self.selectedParticipant)
        }
        
        self.participantSelectionController = viewCont
    }
    
    private func selectParticipant(withParticipant participant: DyteJoinedMeetingParticipant) {
        self.selectedParticipant = participant
    }
    
    func addPermissionUpdateObserver() {
        dyteSelfListner.observeSelfPermissionChanged { [weak self] in
            guard let self = self else {
                return
            }
            self.refreshPermission()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppear = true
        loadMessageToUI()
    }
    
    private func loadChatMessages() {
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.set(.centerView(self.view))
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            if let participant = selectedParticipant {
                self.messages = meeting.chat.getPrivateChatMessages(participant: participant)
            } else {
                self.messages = self.meeting.chat.messages
            }
            self.messageLoaded = true
            self.loadMessageToUI()
        }
    }
    
    private func loadMessageToUI() {
        DispatchQueue.main.async {
            if self.viewDidAppear && self.messageLoaded {
                self.messageTextView.placeholder = "Message.."
                self.reloadMessageTableView()
                self.activityIndicator.stopAnimating()
            }
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
            messageTextFieldBottomConstraint?.isActive = false
            sendFileButtonBottomConstraint?.isActive = false
            sendButtonBottomConstraint?.isActive = false
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
        
        messageTextFieldBottomConstraint?.constant = +keyboardHeight
        sendButtonBottomConstraint?.constant = +keyboardHeight
        sendFileButtonBottomConstraint?.constant = +keyboardHeight
        
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    
    // MARK: - Setup Views
    private func setupViews() {
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
        sendFileButton.set(.width(48))
        sendFileButton.addSubview(sendFileButtonDisabledView)
        sendFileButtonDisabledView.set(.fillSuperView(sendFileButton))
        sendMessageButton.set(.width(48))
        sendMessageButton.backgroundColor = dyteSharedTokenColor.brand.shade500
        sendMessageButton.clipsToBounds = true
        sendMessageButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        view.addSubview(sendMessageButton)
        
        let chatSelectorView = UIView()
        chatSelectorView.backgroundColor = DesignLibrary.shared.color.background.shade900
        let imageView = DyteUIUTility.createImageView(image: DyteImage(image:ImageProvider.image(named: "icon_up_arrow")))
        chatSelectorLabel.text = everyOneText
        chatSelectorView.addSubview(chatSelectorLabel)
        chatSelectorView.addSubview(imageView)
        view.addSubViews(chatSelectorView)
        
        chatSelectorView.isHidden = !meeting.localUser.permissions.chat.canSend
        
        let padding: CGFloat = 16
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.showChatParticipantSelectionOverlay))
        chatSelectorView.addGestureRecognizer(tap)
        
        // Disable autoresizing mask constraints
        chatSelectorView.translatesAutoresizingMaskIntoConstraints = false
        chatSelectorLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        
        chatSelectorView.addSubview(notificationBadge)
        let notificationBadgeHeight = dyteSharedTokenSpace.space4
        notificationBadge.set(.top(imageView),
                              .before(imageView, padding),
                              .height(notificationBadgeHeight),
                              .width(notificationBadgeHeight*2.5, .lessThanOrEqual))
        
        notificationBadge.layer.cornerRadius = notificationBadgeHeight/2.0
        notificationBadge.layer.masksToBounds = true
        notificationBadge.backgroundColor = dyteSharedTokenColor.brand.shade500
        notificationBadge.isHidden = true
        
        
        // add constraints
        let constraints = [
            chatSelectorView.leadingAnchor.constraint(equalTo: sendFileButton.leadingAnchor),
            chatSelectorView.trailingAnchor.constraint(equalTo: sendMessageButton.trailingAnchor),
            chatSelectorView.bottomAnchor.constraint(equalTo: messageTextView.topAnchor, constant: -8),
            chatSelectorView.heightAnchor.constraint(equalToConstant: 48),
            
            chatSelectorLabel.leadingAnchor.constraint(equalTo: chatSelectorView.leadingAnchor, constant: padding),
            chatSelectorLabel.topAnchor.constraint(equalTo: chatSelectorView.topAnchor, constant: padding),
            chatSelectorLabel.bottomAnchor.constraint(equalTo: chatSelectorView.bottomAnchor, constant: -padding),
            
            imageView.trailingAnchor.constraint(equalTo: chatSelectorView.trailingAnchor, constant: -padding),
            imageView.topAnchor.constraint(equalTo: chatSelectorView.topAnchor, constant: padding),
            imageView.bottomAnchor.constraint(equalTo: chatSelectorView.bottomAnchor, constant: -padding),
            
            messageTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            messageTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageTableView.bottomAnchor.constraint(equalTo: chatSelectorView.topAnchor, constant: -8),
            messageTextView.trailingAnchor.constraint(equalTo: sendMessageButton.leadingAnchor, constant: -8),
            messageTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            messageTextView.topAnchor.constraint(equalTo: messageTableView.bottomAnchor, constant: 8),
            
            sendFileButton.trailingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: -8),
            sendFileButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            sendFileButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            
            sendMessageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            sendMessageButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ]
        
        NSLayoutConstraint.activate(constraints)
        messageTextViewHeightConstraint = messageTextView.heightAnchor.constraint(equalToConstant: 48)
        messageTextViewHeightConstraint?.isActive = true
        view.addSubview(sendTextViewDisabledView)
        sendTextViewDisabledView.set(.sameTopBottom(sendMessageButton),
                                     .leading(messageTextView),
                                     .trailing(sendMessageButton))
        refreshPermission()
    }
    
    private func removeParticipant(participantUserId: String) {
        if selectedParticipant?.userId == participantUserId {
            Shared.data.privateChatReadLookup.removeValue(forKey: participantUserId)
            setDefaultParticipantToEveryOne()
        }
        if let cont = self.participantSelectionController {
            var participants = meeting.participants.joined
            participants.removeAll { participant in
                participant.id == meeting.localUser.id
            }
            cont.setParticipants(participants: participants)
            cont.onRemove(userId: participantUserId)
        }

    }
    
    private func refreshPermission() {
        var canSendFiles = self.meeting.localUser.permissions.chat.canSendFiles
        var canSendText = self.meeting.localUser.permissions.chat.canSendText
        if self.meeting.localUser.permissions.chat.canSend == false {
            canSendText = false
            canSendFiles = false
        }
        self.sendTextViewDisabledView.isHidden = canSendText
        self.sendFileButtonDisabledView.isHidden = canSendFiles
        messageTextView.resignFirstResponder()
    }
    
    private func refreshPrivatePermission() {
        var canSendFiles = self.meeting.localUser.permissions.privateChat.canSendFiles
        var canSendText = self.meeting.localUser.permissions.privateChat.canSendText
        self.sendTextViewDisabledView.isHidden = canSendText
        self.sendFileButtonDisabledView.isHidden = canSendFiles
        messageTextView.resignFirstResponder()
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
        meeting.removeChatEventsListener(chatEventsListener: self)
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
            if let id = selectedParticipant?.id, !id.isEmpty {
                try?meeting.chat.sendTextMessage(message: message, peerIds: [id])
            } else {
                try?meeting.chat.sendTextMessage(message: message)
            }
            
            messageTextView.text = ""
            messageTextViewHeightConstraint?.constant = 48
            sendMessageButton.isEnabled = false
        }
    }
    
    private func reloadMessageTableView() {
        if let participant = selectedParticipant {
            self.messages = meeting.chat.getPrivateChatMessages(participant: participant)
        } else {
            self.messages = self.meeting.chat.messages
        }
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

extension DyteChatViewController: UITableViewDelegate, UITableViewDataSource {
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
                        self?.messageTextView.resignFirstResponder()
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
                        self?.messageTextView.resignFirstResponder()
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

extension DyteChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let url = info[UIImagePickerController.InfoKey.imageURL] as? URL {
            sendMessageButton.showActivityIndicator()
            if let id = selectedParticipant?.id, !id.isEmpty {
                self.meeting.chat.sendImageMessage(imagePath: url.path, peerIds: [id])
            } else {
                self.meeting.chat.sendImageMessage(imagePath: url.path)
            }
        }
        dismiss(animated: true, completion: nil)
    }
}

extension DyteChatViewController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        sendMessageButton.showActivityIndicator()
        if let id = selectedParticipant?.id, !id.isEmpty {
            self.meeting.chat.sendFileMessage(filePath: selectedFileURL.path, peerIds: [id])
        } else {
            self.meeting.chat.sendFileMessage(filePath: selectedFileURL.path)
        }
    }
}

extension DyteChatViewController: UITextViewDelegate {
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

extension DyteChatViewController: ChatParticipantSelectionDelegate {
    
    func didSelectChat(withParticipant participant: DyteJoinedMeetingParticipant?) {
        if let dyteJoinedMeetingParticipant = participant {
            selectedParticipant = dyteJoinedMeetingParticipant
            chatSelectorLabel.text = "To \(dyteJoinedMeetingParticipant.name) (Direct)"
            setReadFor(dyteJoinedMeetingParticipant)
        } else {
            setDefaultParticipantToEveryOne()
        }
        
        showNotiificationBadge()
        self.participantSelectionController = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.reloadMessageTableView()
        })
    }
    
    private func showNotiificationBadge() {
        var showNotificationBadge = false
        for (_, value) in Shared.data.privateChatReadLookup {
            if value == true {
                showNotificationBadge =  true
                break;
            }
        }
        notificationBadge.isHidden = !showNotificationBadge
    }
    private func setDefaultParticipantToEveryOne() {
        selectedParticipant = nil
        Shared.data.privateChatReadLookup[Self.keyEveryOne] = false
        chatSelectorLabel.text = everyOneText
        refreshPermission()
    }
}

extension DyteChatViewController: DyteChatEventsListener {
    public func onNewChatMessage(message: DyteChatMessage) {
        notificationBadge.isHidden = true
        if let targetUserIds = message.targetUserIds {
            var forEveryOne =  targetUserIds.isEmpty
            if forEveryOne {
                if selectedParticipant == nil {
                    // Mean current selected is Everyone only, So don't do anything
                    if let cont = self.participantSelectionController {
                        Shared.data.privateChatReadLookup[Self.keyEveryOne] = true
                    }
                }else {
                    // Message is for everone , but current selected user is different , so showing blue dot
                    notificationBadge.isHidden = false
                    Shared.data.privateChatReadLookup[Self.keyEveryOne] = true
                }
            } else {
                let localUserId = meeting.localUser.userId
                let messageReceiverIDs = targetUserIds
                    .filter { $0 != localUserId }
                messageReceiverIDs.forEach {
                       if selectedParticipant?.userId != $0 {
                            // If current selected user is not same then show blue dot
                            Shared.data.privateChatReadLookup[$0] = true
                            notificationBadge.isHidden = false
                       }else {
                           if let cont = self.participantSelectionController {
                               Shared.data.privateChatReadLookup[$0] = true
                           }
                       }
                }
            }
            self.participantSelectionController?.newChatReceived(message: message)
        }
    }
    
    func setReadFor(_ participant: DyteJoinedMeetingParticipant) {
        Shared.data.privateChatReadLookup[participant.userId] = false
    }

    public  func onChatUpdates(messages: [DyteChatMessage]) {
        if isOnScreen {
            NotificationCenter.default.post(name: Notification.Name("NotificationAllChatsRead"), object: nil)
        }
        Shared.data.setChatReadCount(totalMessage: self.meeting.chat.messages.count)
        sendMessageButton.hideActivityIndicator()
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
    
    private var placeholderLabel: DyteLabel {
        if let label = subviews.compactMap( { $0 as? DyteLabel }).first {
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
