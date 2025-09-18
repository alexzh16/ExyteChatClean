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

enum MessageMenuAction {
    case reply
    case copy
    case saveImageToAlbum
    case saveImageToDevice
    case saveDocument
    case saveText
    case share
}

struct MessageMenu<MainButton: View>: View {
    
    @Environment(\.chatTheme) private var theme
    
    @Binding var isShowingMenu: Bool
    @Binding var menuButtonsSize: CGSize
    var alignment: Alignment
    var leadingPadding: CGFloat
    var trailingPadding: CGFloat
    var mainButton: () -> MainButton
    var onAction: (MessageMenuAction) -> ()
    var messageText: String
    var messageImageURL: URL?
    var messageDocumentURL: URL?
    var onSaveSuccess: (() -> Void)? // Callback for save success
    
    @State private var errorMessage: String = ""
    @State private var showErrorAlert = false
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 8) {
                    FloatingButton(mainButtonView: mainButton().allowsHitTesting(false), buttons: [
                        menuButtons()
                    ], isOpen: $isShowingMenu)
                    .straight()
                    .initialOpacity(0)
                    .direction(.bottom)
                    .alignment(alignment)
                    .spacing(2)
                    .animation(.linear(duration: 0.2))
                    .menuButtonsSize($menuButtonsSize)
                    .alert(isPresented: $showErrorAlert) {
                        Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                    }
                }
                
            }
        }
    }
    
    func menuButtons() -> some View {
        switch messageType() {
        case .image:
            return AnyView(
                VStack {
                    menuButton(title: "Reply", icon: theme.images.messageMenu.reply, action: .reply)
                    menuButton(title: "Copy", icon: Image(systemName: "doc.on.doc"), action: .copy)
                    menuButton(title: "Save to Album", icon: Image(systemName: "photo.on.rectangle"), action: .saveImageToAlbum)
//                    menuButton(title: "Save to Device", icon: Image(systemName: "square.and.arrow.down"), action: .saveImageToDevice)
                    menuButton(title: "Save or Share Document", icon: Image(systemName: "square.and.arrow.up"), action: .share)
                }
            )
        case .document:
            return AnyView(
                VStack {
                    menuButton(title: "Reply", icon: theme.images.messageMenu.reply, action: .reply)
//                    menuButton(title: "Copy", icon: Image(systemName: "doc.on.doc"), action: .copy)
                    menuButton(title: "Save or Share Document", icon: Image(systemName: "square.and.arrow.down"), action: .share)
//                    menuButton(title: "Share", icon: Image(systemName: "square.and.arrow.up"), action: .share)
                }
            )
        case .text:
            return AnyView(
                VStack {
                    menuButton(title: "Reply", icon: theme.images.messageMenu.reply, action: .reply)
                    menuButton(title: "Copy", icon: Image(systemName: "doc.on.doc"), action: .copy)
//                    menuButton(title: "Share", icon: Image(systemName: "square.and.arrow.up"), action: .share)
                }
            )
        }
    }
    
    func menuButton(title: String, icon: Image, action: MessageMenuAction) -> some View {
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
    /*
    func handleAction(_ action: MessageMenuAction) {
        switch action {
        case .copy:
            if let url = messageImageURL, let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) {
                UIPasteboard.general.image = image
            } else {
                UIPasteboard.general.string = messageText
            }
        case .saveImageToAlbum:
            if let url = messageImageURL {
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        onSaveSuccess?()
                    } else {
                        errorMessage = error?.localizedDescription ?? "Unknown error"
                    }
                }
                task.resume()
            }
        case .saveImageToDevice:
            saveImageToDevice()
        case .saveDocument:
            saveDocument()
        case .share:
            shareMessage()
        default:
            break
        }
    }
    */
    func messageType() -> MessageType {
        if let _ = messageImageURL {
            return .image
        } else if let _ = messageDocumentURL {
            return .document
        } else {
            return .text
        }
    }
    /*
    func saveImageToDevice() {
        guard let imageURL = messageImageURL else { return }
        
        // Create a URLSession instance
        let session = URLSession.shared
        
        // Create a data task to asynchronously load the image data
        let task = session.dataTask(with: imageURL) { data, response, error in
            // Check for errors
            if let error = error {
               debugPrint("\(logTAG) \(#line) \(#function) Error loading image data:", error.localizedDescription)
                return
            }
            
            // Ensure data is not nil
            guard let imageData = data else {
               debugPrint("\(logTAG) \(#line) \(#function) No data received")
                return
            }
            
            // Attempt to create UIImage from data
            if let image = UIImage(data: imageData) {
                // Perform UI-related tasks on the main thread
                DispatchQueue.main.async {
                    // Example: save image to the photo library
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    onSaveSuccess?()
                }
            } else {
               debugPrint("\(logTAG) \(#line) \(#function) Failed to create UIImage from data")
            }
        }
        
        // Start the data task
        task.resume()
    }
    
    func saveDocument() {
        guard let documentURL = messageDocumentURL else { return }
        
        do {
            let documentData = try Data(contentsOf: documentURL)
            
            // Get the document directory URL
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                // Construct the destination URL within the documents directory
                let destinationURL = documentsDirectory.appendingPathComponent(documentURL.lastPathComponent)
                
                // Write the file to the destination URL
                try documentData.write(to: destinationURL)
                
                // Perform UI-related tasks on the main thread
                DispatchQueue.main.async {
                    onSaveSuccess?() // Call callback on success
                }
            } else {
               debugPrint("\(logTAG) \(#line) \(#function) Documents directory not found")
            }
        } catch {
           debugPrint("\(logTAG) \(#line) \(#function) Error saving document:", error.localizedDescription)
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    func shareMessage() {
        let items: [Any] = [messageText]
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }*/
}

enum MessageType {
    case image
    case document
    case text
}

