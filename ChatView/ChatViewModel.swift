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
   
   @Published var showConfirmDeleteMessage = false
   @Published var confirmDeleteMessageClosure: (() -> Void)?
   
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
   
   func messageMenuAction() -> (Message, DefaultMessageMenuAction) -> Void {
      { [weak self] message, action in
         DispatchQueue.main.async {
            self?.messageMenuActionInternal(message: message, action: action)
         }
      }
   }

   func messageMenuActionInternal(message: Message, action: DefaultMessageMenuAction) {
       switch action {
       case .reply:
           inputViewModel?.attachments.replyMessage = message.toReplyMessage()
           globalFocusState?.focus = .uuid(inputFieldId)
       case .edit(let saveClosure):
           inputViewModel?.text = message.text
           inputViewModel?.edit(saveClosure)
           globalFocusState?.focus = .uuid(inputFieldId)
       case .delete(let confirmClosure):
           showConfirmDeleteMessage = true
           confirmDeleteMessageClosure = confirmClosure
//       case .copy:
//          debugPrint("copy")
//       case .saveImageToAlbum:
//          debugPrint("saveImageToAlbum")
//       case .saveImageToDevice:
//          debugPrint("saveImageToDevice")
//       case .saveDocument:
//          debugPrint("saveDocument")
//       case .saveText:
//          debugPrint("saveText")
//       case .share:
//          debugPrint("share")
       }
   }
}
