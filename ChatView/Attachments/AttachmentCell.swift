//
//  Created by Alex.M on 16.06.2022.
//

import SwiftUI

struct AttachmentCell: View {
   let logTAG = "AttachmentCell"
   @Environment(\.chatTheme) private var theme
   
   let attachment: Attachment
   let onTap: (Attachment) -> Void
   
   @State private var isPresentingPreview = false
   @State private var downloadedFileURL: URL?
   @State private var isLoading = false
   
   var body: some View {
      Group {
         if attachment.type == .image {
            content
         } else if attachment.type == .video {
            content
               .overlay {
                  theme.images.message.playVideo
                     .resizable()
                     .foregroundColor(.white)
                     .frame(width: 36, height: 36)
               }
         } else if attachment.type == .files {
            content
         }
         else {
            content
               .overlay {
                  Text("Unknown")
               }
         }
      }
      .contentShape(Rectangle())
      .onTapGesture {
         if attachment.type == .files {
            isLoading = true
            downloadFile(from: attachment.full) { url in
               DispatchQueue.main.async {
                  isLoading = false
                  if let url = url {
                     downloadedFileURL = url
                     isPresentingPreview = true
                     //                            onTap(attachment)
                  }
               }
            }
         } else {
            onTap(attachment)
         }
      }
      .sheet(isPresented: $isPresentingPreview) {
         if let url = downloadedFileURL {
            AttachmentPreview(url: url, isPresented: $isPresentingPreview)
         }
      }
      .overlay {
         if isLoading {
            ProgressView()
         }
      }
      
   }
   
   var content: some View {
      AsyncImageView(url: attachment.thumbnail)
   }
   
   func downloadFile(from url: URL, completion: @escaping (URL?) -> Void) {
      let task = URLSession.shared.downloadTask(with: url) { tempLocalUrl, response, error in
         guard let tempLocalUrl = tempLocalUrl, error == nil else {
            debugPrint("\(logTAG) \(#line) \(#function) Error downloading file: \(error?.localizedDescription ?? "Unknown error")")
            completion(nil)
            return
         }
         
         let fileManager = FileManager.default
         let targetUrl = fileManager.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
         
         do {
            if fileManager.fileExists(atPath: targetUrl.path) {
               try fileManager.removeItem(at: targetUrl)
            }
            try fileManager.moveItem(at: tempLocalUrl, to: targetUrl)
            completion(targetUrl)
         } catch {
            debugPrint("\(logTAG) \(#line) \(#function) Error moving file: \(error.localizedDescription)")
            completion(nil)
         }
      }
      task.resume()
   }
}

struct AttachmentPreview: View {
   let url: URL
   @Binding var isPresented: Bool
   
   var body: some View {
      NavigationView {
         QuickLookView(url: url)
            .navigationBarItems(trailing: Button("Done") {
               isPresented = false
            })
      }
   }
}

struct AsyncImageView: View {
   
   @Environment(\.chatTheme) var theme
   let url: URL
   
   var body: some View {
      CachedAsyncImage(url: url, urlCache: .imageCache) { imageView in
         imageView
            .resizable()
            .scaledToFill()
      } placeholder: {
         ZStack {
            Rectangle()
               .foregroundColor(theme.colors.inputLightContextBackground)
               .frame(minWidth: 100, minHeight: 100)
            ActivityIndicator(size: 30, showBackground: false)
         }
      }
   }
}
