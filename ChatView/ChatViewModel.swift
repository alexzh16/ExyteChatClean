//
//  Created by Alex.M on 20.06.2022.
//

import Foundation
import Combine

final class ChatViewModel: ObservableObject {
   
   @Published private(set) var fullscreenAttachmentItem: Optional<Attachment> = nil
   @Published var fullscreenAttachmentPresented = false
   @Published var uploadedFileURL: URL? = nil
   
   @Published var messageMenuRow: MessageRow?
   
   let inputFieldId = UUID()
   
   var didSendMessage: (DraftMessage) -> Void = {_ in}
   var inputViewModel: InputViewModel?
   var globalFocusState: GlobalFocusState?
   
   func presentAttachmentFullScreen(_ attachment: Attachment) {
      fullscreenAttachmentItem = attachment
      fullscreenAttachmentPresented = true
   }
   
   func dismissAttachmentFullScreen() {
      fullscreenAttachmentPresented = false
      fullscreenAttachmentItem = nil
   }
   
   func sendMessage(_ message: DraftMessage) {
      didSendMessage(message)
   }
   // Метод для установки URL загруженного файла
   func setUploadedFileURL(_ url: URL) {
      uploadedFileURL = url
   }
   
   func messageMenuAction() -> (ExyteChatMessage, MessageMenuAction) -> Void {
       { [weak self] in
           self?.messageMenuActionInternal(message: $0, action: $1)
       }
   }

   func messageMenuActionInternal(message: ExyteChatMessage, action: MessageMenuAction) {
       switch action {
       case .reply:
           inputViewModel?.attachments.replyMessage = message.toReplyMessage()
           globalFocusState?.focus = .uuid(inputFieldId)
       case .copy:
          debugPrint("copy")
       case .saveImageToAlbum:
          debugPrint("saveImageToAlbum")
       case .saveImageToDevice:
          debugPrint("saveImageToDevice")
       case .saveDocument:
          debugPrint("saveDocument")
       case .saveText:
          debugPrint("saveText")
       case .share:
          debugPrint("share")
       }
   }
}
