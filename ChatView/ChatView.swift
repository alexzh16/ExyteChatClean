//
//  ChatView.swift
//  Chat
//
//  Created by Alisa Mylnikova on 20.04.2022.
//

import SwiftUI
import FloatingButton
import SwiftUIIntrospect
import UniformTypeIdentifiers
import UIKit

public typealias MediaPickerParameters = SelectionParamsHolder

public enum ChatType {
   case conversation // input view and the latest message at the bottom
   case comments // input view and the latest message on top
}
public enum AttachmentOption {
   case photo
   case camera
   case file
}

public enum ReplyMode {
   case quote // when replying to message A, new message will appear as the newest message, quoting message A in its body
   case answer // when replying to message A, new message with appear direclty below message A as a separate cell without duplication message A in its body
}

public struct ChatView<MessageContent: View, InputViewContent: View, MenuAction: MessageMenuAction>: View {
   let logTAG = "ChatView"
   @Namespace private var scrollViewNamespace
   @State private var scrollViewProxy: ScrollViewProxy? = nil
   
   /// To build a custom message view use the following parameters passed by this closure:
   /// - message containing user, attachments, etc.
   /// - position of message in its continuous group of messages from the same user
   /// - position of message in its continuous group of comments (only works for .comments ReplyMode, nil for .quote mode)
   /// - closure to show message context menu
   /// - closure to pass user interaction, .reply for example
   /// - pass attachment to this closure to use ChatView's fullscreen media viewer
   public typealias MessageBuilderClosure = ((
       _ message: Message,
       _ positionInGroup: PositionInUserGroup,
       _ positionInCommentsGroup: CommentsPosition?,
       _ showContextMenuClosure: @escaping () -> Void,
       _ messageActionClosure: @escaping (Message, DefaultMessageMenuAction) -> Void,
       _ showAttachmentClosure: @escaping (Attachment) -> Void
   ) -> MessageContent)
   
   /// To build a custom input view use the following parameters passed by this closure:
   /// - binding to the text in input view
   /// - InputViewAttachments to store the attachments from external pickers
   /// - current input view state: .message for main input view mode and .signature for input view in media picker mode
   /// - Current input view state
   /// - .message for main input view mode and .signature for input view in media picker mode
   /// - closure to pass user interaction, .recordAudioTap for example
   /// - dismiss keyboard closure
   public typealias InputViewBuilderClosure = (
      _ text: Binding<String>,
      _ attachments: InputViewAttachments,
      _ inputViewState: InputViewState,
      _ inputViewStyle: InputViewStyle,
      _ inputViewActionClosure: @escaping (InputViewAction) -> Void,
      _ dismissKeyboardClosure: ()->()
   ) -> InputViewContent
   
   /// To define custom message menu actions
   /// - enum listing action options
   /// - message for which the menu is disaplyed
   /// closure returns the action to perform on selected action tap
   public typealias MessageMenuActionClosure = ((MenuAction, Message)->Void)

   /// User and MessageId
   public typealias TapAvatarClosure = (ExyteChatUser, String) -> ()
   
   @Environment(\.safeAreaInsets) private var safeAreaInsets
   @Environment(\.chatTheme) private var theme
   @Environment(\.mediaPickerTheme) private var pickerTheme
   
   // MARK: - Parameters
   let type: ChatType
   let sections: [MessagesSection]
   let ids: [String]
   let didSendMessage: (DraftMessage) -> Void
   
   // MARK: - View builders
   
   /// provide custom message view builder
   var messageBuilder: MessageBuilderClosure? = nil
   
   /// provide custom input view builder
   var inputViewBuilder: InputViewBuilderClosure? = nil
   
   /// message menu customization: create enum complying to MessageMenuAction and pass a closure processing your enum cases
   var messageMenuAction: MessageMenuActionClosure?

   /// content to display in between the chat list view and the input view
   var betweenListAndInputViewBuilder: (()->AnyView)?

   /// a header for the whole chat, which will scroll together with all the messages and headers
   var mainHeaderBuilder: (()->AnyView)?

   /// date section header builder
   var headerBuilder: ((Date)->AnyView)?
   
   // MARK: - Customization
   
   var isListAboveInputView: Bool = true
   var showDateHeaders: Bool = true
   var isScrollEnabled: Bool = true
   var avatarSize: CGFloat = 32
   var messageUseMarkdown: Bool = false
   var showMessageMenuOnLongPress: Bool = true
   var showNetworkConnectionProblem: Bool = false
   var tapAvatarClosure: TapAvatarClosure?
   var mediaPickerSelectionParameters: MediaPickerParameters?
   var orientationHandler: MediaPickerOrientationHandler = {_ in}
   var chatTitle: String?
   var paginationHandler: PaginationHandler?
   var showMessageTimeView = true
   var messageFont = UIFontMetrics.default.scaledFont(for: UIFont.systemFont(ofSize: 15))
   var availablelInput: AvailableInputType = .full
   
   @StateObject private var viewModel = ChatViewModel()
   @StateObject private var inputViewModel = InputViewModel()
   @StateObject private var globalFocusState = GlobalFocusState()
   @StateObject private var networkMonitor = NetworkMonitor()
   @StateObject private var keyboardState = KeyboardState()
   
   @State private var isScrolledToBottom: Bool = true
   @State private var shouldScrollToTop: () -> () = {}
   
   @State private var isShowingMenu = false
   @State private var needsScrollView = false
   @State private var readyToShowScrollView = false
   @State private var menuButtonsSize: CGSize = .zero
   @State private var tableContentHeight: CGFloat = 0
   @State private var inputViewSize = CGSize.zero
   @State private var cellFrames = [String: CGRect]()
   @State private var menuCellPosition: CGPoint = .zero
   @State private var menuBgOpacity: CGFloat = 0
   @State private var menuCellOpacity: CGFloat = 0
   @State private var menuScrollView: UIScrollView?
   
   @State private var isShowingSaveSuccess = false
   @State private var saveSuccessMessage = ""
   @State private var isShowingSnackbar = false
   @State private var snackbarMessage = ""
   
   public init(messages: [Message],
               chatType: ChatType = .conversation,
               replyMode: ReplyMode = .quote,
               didSendMessage: @escaping (DraftMessage) -> Void,
               messageBuilder: @escaping MessageBuilderClosure,
               inputViewBuilder: @escaping InputViewBuilderClosure,
               messageMenuAction: MessageMenuActionClosure?) {
      self.type = chatType
      self.didSendMessage = didSendMessage
      self.sections = ChatView.mapMessages(messages, chatType: chatType, replyMode: replyMode)
      self.ids = messages.map { $0.id }
      self.messageBuilder = messageBuilder
      self.inputViewBuilder = inputViewBuilder
      self.messageMenuAction = messageMenuAction
   }
   
   public var body: some View {
      mainView
         .background(theme.colors.mainBackground)
         .fullScreenCover(isPresented: $viewModel.fullscreenAttachmentPresented) {
            let attachments = sections.flatMap { section in section.rows.flatMap { $0.message.attachments } }
            let index = attachments.firstIndex { $0.id == viewModel.fullscreenAttachmentItem?.id }
            
            GeometryReader { g in
               FullscreenMediaPages(
                  viewModel: FullscreenMediaPagesViewModel(
                     attachments: attachments,
                     index: index ?? 0
                  ),
                  safeAreaInsets: g.safeAreaInsets,
                  onClose: { [weak viewModel] in
                     viewModel?.dismissAttachmentFullScreen()
                  }
               )
               .ignoresSafeArea()
            }
         }
         .fullScreenCover(isPresented: $inputViewModel.showPicker) {
            AttachmentsEditor(inputViewModel: inputViewModel, inputViewBuilder: inputViewBuilder, chatTitle: chatTitle, messageUseMarkdown: messageUseMarkdown, orientationHandler: orientationHandler, mediaPickerSelectionParameters: mediaPickerSelectionParameters, availableInput: availablelInput)
               .environmentObject(globalFocusState)
         }
         .onChange(of: inputViewModel.showPicker) {
            if $0 {
               globalFocusState.focus = nil
            }
         }
   }
   
   var mainView: some View {
      VStack {
         if !networkMonitor.isConnected, !networkMonitor.isConnected {
            waitingForNetwork
         }
         if isListAboveInputView {
            listWithButton
            if let builder = betweenListAndInputViewBuilder {
               builder()
            }
            inputView
         } else {
            inputView
            if let builder = betweenListAndInputViewBuilder {
               builder()
            }
            listWithButton
         }
      }
   }

   @ViewBuilder
   var listWithButton: some View {
      switch type {
      case .conversation:
         ZStack(alignment: .bottomTrailing) {
            list
            
            if !isScrolledToBottom {
               Button {
                  NotificationCenter.default.post(name: .onScrollToBottom, object: nil)
               } label: {
                  theme.images.scrollToBottom
                     .frame(width: 40, height: 40)
                     .circleBackground(theme.colors.friendMessage)
               }
               .padding(8)
            }
         }
         
      case .comments:
         list
      }
   }

   var waitingForNetwork: some View {
      VStack {
         Rectangle()
            .foregroundColor(.black.opacity(0.12))
            .frame(height: 1)
         HStack {
            Spacer()
            Image("waiting", bundle: .current)
            Text("Waiting for network")
            Spacer()
         }
         .padding(.top, 6)
         Rectangle()
            .foregroundColor(.black.opacity(0.12))
            .frame(height: 1)
      }
      .padding(.top, 8)
   }
   
   @ViewBuilder
   var list: some View {
      UIList(viewModel: viewModel,
             inputViewModel: inputViewModel,
             isScrolledToBottom: $isScrolledToBottom,
             shouldScrollToTop: $shouldScrollToTop,
             tableContentHeight: $tableContentHeight,
             messageBuilder: messageBuilder,
             mainHeaderBuilder: mainHeaderBuilder,
             headerBuilder: headerBuilder,
             inputView: inputView,
             type: type,
             showDateHeaders: showDateHeaders,
             isScrollEnabled: isScrollEnabled,
             avatarSize: avatarSize,
             showMessageMenuOnLongPress: showMessageMenuOnLongPress,
             tapAvatarClosure: tapAvatarClosure,
             paginationHandler: paginationHandler,
             messageUseMarkdown: messageUseMarkdown,
             showMessageTimeView: showMessageTimeView,
             messageFont: messageFont,
             sections: sections,
             ids: ids
      )
      .applyIf(!isScrollEnabled) {
         $0.frame(height: tableContentHeight)
      }
      .onStatusBarTap {
         shouldScrollToTop()
      }
      .transparentNonAnimatingFullScreenCover(item: $viewModel.messageMenuRow) {
         if let row = viewModel.messageMenuRow {
            ZStack(alignment: .topLeading) {
               theme.colors.messageMenuBackground
                  .opacity(menuBgOpacity)
                  .ignoresSafeArea(.all)
               
               if needsScrollView {
                  ScrollView {
                     messageMenu(row)
                  }
                  .introspect(.scrollView, on: .iOS(.v16, .v17)) { scrollView in
                     DispatchQueue.main.async {
                        self.menuScrollView = scrollView
                     }
                  }
                  .opacity(readyToShowScrollView ? 1 : 0)
               }
               if !needsScrollView || !readyToShowScrollView {
                  messageMenu(row)
                     .position(menuCellPosition)
               }
            }
            .onAppear {
               DispatchQueue.main.async {
                  if let frame = cellFrames[row.id] {
                     showMessageMenu(frame)
                  }
               }
            }
            .onTapGesture {
               hideMessageMenu()
            }
         }
      }
      .onPreferenceChange(MessageMenuPreferenceKey.self) {
         self.cellFrames = $0
      }
      .onTapGesture {
         globalFocusState.focus = nil
      }
      .onAppear {
         viewModel.didSendMessage = didSendMessage
         viewModel.inputViewModel = inputViewModel
         viewModel.globalFocusState = globalFocusState
         
         inputViewModel.didSendMessage = { value in
            didSendMessage(value)
            if type == .conversation {
               DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                  NotificationCenter.default.post(name: .onScrollToBottom, object: nil)
               }
            }
         }
      }
   }
   
   var inputView: some View {
      Group {
         if let inputViewBuilder = inputViewBuilder {
            inputViewBuilder($inputViewModel.text, inputViewModel.attachments, inputViewModel.state, .message, inputViewModel.inputViewAction()) {
               globalFocusState.focus = nil
            }
         } else {
            InputView(
               viewModel: inputViewModel,
               inputFieldId: viewModel.inputFieldId,
               style: .message,
               availableInput: availablelInput,
               messageUseMarkdown: messageUseMarkdown
            )
         }
      }
      .onChange(of: inputViewModel.text) {a, _ in
         debugPrint("\(#function) \(#line) a: \(a)")
      }
      .sizeGetter($inputViewSize)
      .environmentObject(globalFocusState)
      .onAppear(perform: inputViewModel.onStart)
      .onDisappear(perform: inputViewModel.onStop)
   }
   
   func messageMenu(_ row: MessageRow) -> some View {
      MessageMenu(
         isShowingMenu: $isShowingMenu,
         menuButtonsSize: $menuButtonsSize,
         alignment: row.message.user.isCurrentUser ? .right : .left,
         leadingPadding: avatarSize + MessageView.horizontalAvatarPadding * 2,
         trailingPadding: MessageView.statusViewSize + MessageView.horizontalStatusPadding,
         onAction: menuActionClosure(row.message)) {
            ChatMessageView(viewModel: viewModel, messageBuilder: messageBuilder, row: row, chatType: type, avatarSize: avatarSize, tapAvatarClosure: nil, messageUseMarkdown: messageUseMarkdown, isDisplayingMessageMenu: true, showMessageTimeView: showMessageTimeView, messageFont: messageFont)
               .onTapGesture {
                  hideMessageMenu()
               }
         }
         .frame(height: menuButtonsSize.height + (cellFrames[row.id]?.height ?? 0), alignment: .top)
         .opacity(menuCellOpacity)
   }
   
//   func messageMenuLe(_ row: MessageRow) -> some View {
//      MessageMenu(
//         isShowingMenu: $isShowingMenu,
//         menuButtonsSize: $menuButtonsSize,
//         alignment: row.message.user.isCurrentUser ? .right : .left,
//         leadingPadding: avatarSize + MessageView.horizontalAvatarPadding * 2,
//         trailingPadding: MessageView.statusViewSize + MessageView.horizontalStatusPadding,
//         onAction: menuActionClosure(row.message)) {
//            ChatMessageView(viewModel: viewModel, messageBuilder: messageBuilder, row: row, chatType: type, avatarSize: avatarSize, tapAvatarClosure: nil, messageUseMarkdown: messageUseMarkdown, isDisplayingMessageMenu: true, showMessageTimeView: showMessageTimeView, messageFont: messageFont)
//               .onTapGesture {
//                  hideMessageMenu()
//               }
//         }
////         mainButton: {
////            ChatMessageView(
////               viewModel: viewModel,
////               messageBuilder: messageBuilder,
////               row: row,
////               chatType: type,
////               avatarSize: avatarSize,
////               tapAvatarClosure: nil,
////               messageUseMarkdown: messageUseMarkdown,
////               isDisplayingMessageMenu: true,
////               showMessageTimeView: showMessageTimeView,
////               messageFont: messageFont
////            )
////            .frame(width: UIScreen.main.bounds.width - 32)
////            .padding(.horizontal, 8)
////            .padding(.bottom, isShowingMenu ? 0 : 0) // Adjust bottom padding if menu is shown
////            .onAppear {
////               DispatchQueue.main.async {
////                  if let frame = cellFrames[row.id] {
////                     showMessageMenu(frame)
////                  }
////               }
////            }
////            .onTapGesture {
////               hideMessageMenu()
////            }
////         },
////         messageText: row.message.text,
////         messageImageURL: row.message.attachments.first(where: { $0.type == .image })?.full,
////         messageDocumentURL: row.message.attachments.first(where: { $0.type == .files })?.full,
////         onSaveSuccess: {
////            showSaveSuccessMessage(forKey: "document_saved_successfully")
////         }
////      )
//      .frame(height: menuButtonsSize.height + (cellFrames[row.id]?.height ?? 0), alignment: .top)
//      .opacity(menuCellOpacity)
//      
//   }
   
   func showSnackbar(message: String) {
      snackbarMessage = message
      isShowingSnackbar = true
   }
   
   func hideSnackbar() {
      isShowingSnackbar = false
   }
   
   func showSaveSuccessMessage(forKey key: String) {
      let message = NSLocalizedString(key, comment: "")
      withAnimation {
         showSnackbar(message: message)
      }
   }
   
   func menuActionClosure(_ message: Message) -> (MenuAction) -> () {
      if let messageMenuAction {
         return { action in
            hideMessageMenu()
            messageMenuAction(action, message)
         }
      } else if MenuAction.self == DefaultMessageMenuAction.self {
         return { action in
            hideMessageMenu()
            viewModel.messageMenuActionInternal(message: message, action: action as! DefaultMessageMenuAction)
         }
      }
      return { _ in }
   }
   
   func showMessageMenu(_ cellFrame: CGRect) {
      DispatchQueue.main.async {
         let wholeMenuHeight = menuButtonsSize.height + cellFrame.height
         let needsScrollTemp = wholeMenuHeight > UIScreen.main.bounds.height - safeAreaInsets.top - safeAreaInsets.bottom
         
         menuCellPosition = CGPoint(x: cellFrame.midX, y: cellFrame.minY + wholeMenuHeight/2 - safeAreaInsets.top)
         menuCellOpacity = 1
         
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            var finalCellPosition = menuCellPosition
            if needsScrollTemp ||
                  cellFrame.minY + wholeMenuHeight + safeAreaInsets.bottom > UIScreen.main.bounds.height {
               
               finalCellPosition = CGPoint(x: cellFrame.midX, y: UIScreen.main.bounds.height - wholeMenuHeight/2 - safeAreaInsets.top - safeAreaInsets.bottom
               )
            }
            
            withAnimation(.linear(duration: 0.1)) {
               menuBgOpacity = 0.9
               menuCellPosition = finalCellPosition
               isShowingMenu = true
            }
         }
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            needsScrollView = needsScrollTemp
         }
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            readyToShowScrollView = true
            if let menuScrollView = menuScrollView {
               menuScrollView.contentOffset = CGPoint(x: 0, y: menuScrollView.contentSize.height - menuScrollView.frame.height + safeAreaInsets.bottom)
            }
         }
      }
   }
   
   func hideMessageMenu() {
      menuScrollView = nil
      withAnimation(.linear(duration: 0.1)) {
         menuCellOpacity = 0
         menuBgOpacity = 0
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
         viewModel.messageMenuRow = nil
         isShowingMenu = false
         needsScrollView = false
         readyToShowScrollView = false
      }
   }
   
   func scrollToMessage(withId id: String) {
      if let scrollViewProxy = scrollViewProxy {
         scrollViewProxy.scrollTo(id, anchor: .center)
      }
   }
   
   func downloadAndShareFile(from url: URL) {
      let session = URLSession.shared
      let downloadTask = session.downloadTask(with: url) { (location, response, error) in
         guard let location = location, error == nil else {
            debugPrint("\(logTAG) \(#line) \(#function) Download error: \(error?.localizedDescription ?? "Unknown error")")
            return
         }
         
         let fileManager = FileManager.default
         let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
         let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
         
         do {
            // Удалить файл, если он уже существует
            if fileManager.fileExists(atPath: destinationURL.path) {
               try fileManager.removeItem(at: destinationURL)
            }
            // Переместить загруженный файл
            try fileManager.moveItem(at: location, to: destinationURL)
            //  поделиться файлом
            DispatchQueue.main.async {
               self.share(item: [destinationURL])
            }
         } catch {
            debugPrint("\(logTAG) \(#line) \(#function) File move error: \(error.localizedDescription)")
         }
      }
      downloadTask.resume()
   }
   
   func downloadAndShareFiles(from url: URL) {
      let task = URLSession.shared.downloadTask(with: url) { (tempURL, response, error) in
         guard let tempURL = tempURL, error == nil else {
            debugPrint("\(logTAG) \(#line) \(#function) Download error: \(String(describing: error))")
            return
         }
         
         let fileManager = FileManager.default
         let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
         let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
         
         do {
            // Удалить файл, если он уже существует
            if fileManager.fileExists(atPath: destinationURL.path) {
               try fileManager.removeItem(at: destinationURL)
            }
            // Переместить загруженный файл
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            debugPrint("\(logTAG) \(#line) \(#function) File moved to: \(destinationURL.path)")
            
            // Здесь вы можете выполнить последующие действия, например, поделиться файлом
            DispatchQueue.main.async {
               self.share(item: [destinationURL])
            }
         } catch {
            debugPrint("\(logTAG) \(#line) \(#function) File move error: \(error.localizedDescription)")
         }
      }
      task.resume()
   }
   
   public func share(item: [Any]) {
      let activityViewController = UIActivityViewController(activityItems: item, applicationActivities: nil)
      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
         let window = windowScene.windows.first,
         let rootViewController = window.rootViewController {
         
         var topController = rootViewController
         while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
         }
         
         topController.present(activityViewController, animated: true, completion: nil)
      }
   }
   
   func saveDocument(url: URL) {
      let documentPicker = UIDocumentPickerViewController(forExporting: [url])
      //        documentPicker.delegate = context.coordinator
      documentPicker.modalPresentationStyle = .formSheet
      if let topController = UIApplication.shared.windows.first?.rootViewController {
         topController.present(documentPicker, animated: true, completion: nil)
      }
   }
   
   // координатор для обработки делегата UIDocumentPickerViewController
   class Coordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
      let logTAG = "Coordinator"
      func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
         guard let url = urls.first else { return }
         // Здесь можно обработать сохранение документа по выбранному пути
         debugPrint("\(logTAG) \(#line) \(#function) Document saved at: \(url)")
      }
      
      func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
         debugPrint("\(logTAG) \(#line) \(#function) Document picker was cancelled")
      }
   }
   
   private func saveImageToAlbum(_ imageURL: URL?) {
      guard let imageURL = imageURL else { return }
      // Implement logic to save image to album
      let task = URLSession.shared.dataTask(with: imageURL) { data, response, error in
         if let data = data, let image = UIImage(data: data) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            showSaveSuccessMessage(forKey: "image_saved_successfully")
            //                    onSaveSuccess?()
         } else {
            showSaveSuccessMessage(forKey: "Error")
         }
      }
      task.resume()
   }
   
   private func saveImageToDevice(_ imageURL: URL?) {
      guard let imageURL = imageURL else { return }
      // Implement logic to save image to device
      // Example:
      // if let imageData = try? Data(contentsOf: imageURL), let image = UIImage(data: imageData) {
      //     UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
      // }
   }
   
   // Example selector function for saveImageToDevice
   private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
      if let error = error {
         debugPrint("\(logTAG) \(#line) \(#function) Error saving image: \(error.localizedDescription)")
      } else {
         debugPrint("\(logTAG) \(#line) \(#function) Image saved successfully.")
      }
   }
}

public extension ChatView {
   
   func betweenListAndInputViewBuilder<V: View>(_ builder: @escaping ()->V) -> ChatView {
      var view = self
      view.betweenListAndInputViewBuilder = {
         AnyView(builder())
      }
      return view
   }
   
   func mainHeaderBuilder<V: View>(_ builder: @escaping ()->V) -> ChatView {
      var view = self
      view.mainHeaderBuilder = {
         AnyView(builder())
      }
      return view
   }
   
   func headerBuilder<V: View>(_ builder: @escaping (Date)->V) -> ChatView {
      var view = self
      view.headerBuilder = { date in
         AnyView(builder(date))
      }
      return view
   }
   
   func isListAboveInputView(_ isAbove: Bool) -> ChatView {
      var view = self
      view.isListAboveInputView = isAbove
      return view
   }
   
   func showDateHeaders(_ showDateHeaders: Bool) -> ChatView {
      var view = self
      view.showDateHeaders = showDateHeaders
      return view
   }
   
   func isScrollEnabled(_ isScrollEnabled: Bool) -> ChatView {
      var view = self
      view.isScrollEnabled = isScrollEnabled
      return view
   }
   
   func showMessageMenuOnLongPress(_ show: Bool) -> ChatView {
      var view = self
      view.showMessageMenuOnLongPress = show
      return view
   }
   
   func showNetworkConnectionProblem(_ show: Bool) -> ChatView {
      var view = self
      view.showNetworkConnectionProblem = show
      return view
   }
   
   func assetsPickerLimit(assetsPickerLimit: Int) -> ChatView {
      var view = self
      view.mediaPickerSelectionParameters = MediaPickerParameters()
      view.mediaPickerSelectionParameters?.selectionLimit = assetsPickerLimit
      return view
   }
   
   func setMediaPickerSelectionParameters(_ params: MediaPickerParameters) -> ChatView {
      var view = self
      view.mediaPickerSelectionParameters = params
      return view
   }
   
   func orientationHandler(orientationHandler: @escaping MediaPickerOrientationHandler) -> ChatView {
      var view = self
      view.orientationHandler = orientationHandler
      return view
   }
   
   /// when user scrolls up to `pageSize`-th meassage, call the handler function, so user can load more messages
   /// NOTE: doesn't work well with `isScrollEnabled` false
   func enableLoadMore(pageSize: Int, _ handler: @escaping ChatPaginationClosure) -> ChatView {
      var view = self
      view.paginationHandler = PaginationHandler(handleClosure: handler, pageSize: pageSize)
      return view
   }
   
   func chatNavigation(title: String, status: String? = nil, cover: URL? = nil) -> some View {
      var view = self
      view.chatTitle = title
      return view.modifier(ChatNavigationModifier(title: title, status: status, cover: cover))
   }
   
   // makes sense only for built-in message view
   
   func avatarSize(avatarSize: CGFloat) -> ChatView {
      var view = self
      view.avatarSize = avatarSize
      return view
   }
   
   func tapAvatarClosure(_ closure: @escaping TapAvatarClosure) -> ChatView {
      var view = self
      view.tapAvatarClosure = closure
      return view
   }
   
   func messageUseMarkdown(messageUseMarkdown: Bool) -> ChatView {
      var view = self
      view.messageUseMarkdown = messageUseMarkdown
      return view
   }
   
   func showMessageTimeView(_ isShow: Bool) -> ChatView {
      var view = self
      view.showMessageTimeView = isShow
      return view
   }
   
   func setMessageFont(_ font: UIFont) -> ChatView {
      var view = self
      view.messageFont = font
      return view
   }
   
   // makes sense only for built-in input view
   
   func setAvailableInput(_ type: AvailableInputType) -> ChatView {
      var view = self
      view.availablelInput = type
      return view
   }
}
