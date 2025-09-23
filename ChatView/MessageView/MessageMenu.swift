//
//  MessageMenu.swift
//
//
//  Created by Alisa Mylnikova on 20.03.2023.
//
import SwiftUI
import FloatingButton
import enum FloatingButton.Alignment
import UIKit // Required for UIPasteboard

public protocol MessageMenuAction: Equatable, CaseIterable {
   func title() -> String
   func icon() -> Image
}

public enum DefaultMessageMenuAction: MessageMenuAction {
   case reply
   
   public func title() -> String {
      "Reply"
   }
   
   public func icon() -> Image {
      Image(.reply)
   }
}

//public enum PricallMessageMenuAction {
//    case reply
//    case copy
//    case saveImageToAlbum
//    case saveImageToDevice
//    case saveDocument
//    case saveText
//    case share
//}

struct MessageMenu<MainButton: View, ActionEnum: MessageMenuAction>: View {
    @Environment(\.chatTheme) private var theme
    
   @Binding var isShowingMenu: Bool
   @Binding var menuButtonsSize: CGSize
   var alignment: Alignment
   var leadingPadding: CGFloat
   var trailingPadding: CGFloat
   var onAction: (ActionEnum) -> ()
   var mainButton: () -> MainButton
//   var messageText: String
   var messageImageURL: URL?
   var messageDocumentURL: URL?
   var onSaveSuccess: (() -> Void)? // Callback for save success
    
   @State private var errorMessage: String = ""
   @State private var showErrorAlert = false

   var body: some View {
       FloatingButton(
           mainButtonView: mainButton().allowsHitTesting(false),
           buttons: ActionEnum.allCases.map {
               menuButton(title: $0.title(), icon: $0.icon(), action: $0)
           },
           isOpen: $isShowingMenu
       )
       .straight()
       //.mainZStackAlignment(.top)
       .initialOpacity(0)
       .direction(.bottom)
       .alignment(alignment)
       .spacing(2)
       .animation(.linear(duration: 0.2))
       .menuButtonsSize($menuButtonsSize)
   }
   
//   var body: some View {
//      VStack {
//         ScrollView {
//            VStack(spacing: 8) {
//               FloatingButton(
//                  mainButtonView: mainButton().allowsHitTesting(false),
//                  buttons: ActionEnum.allCases.map {
//                     menuButton(title: $0.title(), icon: $0.icon(), action: $0)
//                  },
//                  isOpen: $isShowingMenu
//               )
//               .straight()
//               .initialOpacity(0)
//               .direction(.bottom)
//               .alignment(alignment)
//               .spacing(2)
//               .animation(.linear(duration: 0.2))
//               .menuButtonsSize($menuButtonsSize)
//               .alert(isPresented: $showErrorAlert) {
//                  Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
//               }
//            }
//         }
//      }
//   }
//    
    func menuButtons() -> some View {
        switch messageType() {
        case .image:
            return AnyView(
                VStack {
//                    menuButton(title: "Reply", icon: theme.images.messageMenu.reply, action: .reply)
//                    menuButton(title: "Copy", icon: Image(systemName: "doc.on.doc"), action: .copy)
//                    menuButton(title: "Save to Album", icon: Image(systemName: "photo.on.rectangle"), action: .saveImageToAlbum)
//                    menuButton(title: "Save to Device", icon: Image(systemName: "square.and.arrow.down"), action: .saveImageToDevice)
//                    menuButton(title: "Save or Share Document", icon: Image(systemName: "square.and.arrow.up"), action: .share)
                }
            )
        case .document:
            return AnyView(
                VStack {
//                    menuButton(title: "Reply", icon: theme.images.messageMenu.reply, action: .reply)
//                    menuButton(title: "Copy", icon: Image(systemName: "doc.on.doc"), action: .copy)
//                    menuButton(title: "Save or Share Document", icon: Image(systemName: "square.and.arrow.down"), action: .share)
//                    menuButton(title: "Share", icon: Image(systemName: "square.and.arrow.up"), action: .share)
                }
            )
        case .text:
            return AnyView(
                VStack {
//                    menuButton(title: "Reply", icon: theme.images.messageMenu.reply, action: .reply)
//                    menuButton(title: "Copy", icon: Image(systemName: "doc.on.doc"), action: .copy)
//                    menuButton(title: "Share", icon: Image(systemName: "square.and.arrow.up"), action: .share)
                }
            )
        }
    }
    
   func menuButton(title: String, icon: Image, action: ActionEnum) -> some View {
      HStack(spacing: 0) {
         if alignment == .left {
            Color.clear.viewSize(leadingPadding)
         }
         
         ZStack {
            theme.colors.friendMessage
               .background(.ultraThinMaterial)
               .environment(\.colorScheme, .light)
               .opacity(0.5)
               .cornerRadius(12)
            HStack {
               Text(title)
                  .foregroundColor(theme.colors.textLightContext)
               Spacer()
               icon
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 12)
         }
         .frame(width: 208)
         .fixedSize()
         .onTapGesture {
            onAction(action)
            //                handleAction(action)
         }
         
         if alignment == .right {
            Color.clear.viewSize(trailingPadding)
         }
      }
   }
    func messageType() -> MessageType {
        if let _ = messageImageURL {
            return .image
        } else if let _ = messageDocumentURL {
            return .document
        } else {
            return .text
        }
    }
}

enum MessageType {
    case image
    case document
    case text
}

struct MainButton: View {
    var imageName: String
    var colorHex: String
    var width: CGFloat = 50

    var body: some View {
        ZStack {
            Color(hex: colorHex)
                .frame(width: width, height: width)
                .cornerRadius(width / 2)
                .shadow(color: Color(hex: colorHex).opacity(0.3), radius: 15, x: 0, y: 15)
            Image(systemName: imageName)
                .foregroundColor(.white)
        }
    }
}
