//
//  SwiftUIView.swift
//
//
//  Created by Alex.M on 07.07.2022.
//

import SwiftUI

struct MessageTextView: View {
   let logTAG = "MessageTextView"
   let text: String?
   let messageUseMarkdown: Bool
   @State private var linkMetadata: LinkMetadata?
   @EnvironmentObject private var appEnvironment: AppEnvironment
   
   var body: some View {
      VStack(alignment: .leading, spacing: 10) {
         if let text = text, !text.isEmpty {
            textView(text)
         }
         if let url = FormValidator.extractFirstURL(from: text ?? "") {
            if appEnvironment.isLinkPreviewEnabled {
               if let metadata = linkMetadata {
                  LinkPreviewView(metadata: metadata)
               }
            } else {
               LinkPreviewDisabledView(url: url, linkMetadata: $linkMetadata)
            }
         }
      }
      .onAppear {
         if appEnvironment.isLinkPreviewEnabled,
            let text = text,
            let url = FormValidator.extractFirstURL(from: text) {
            Task {
               if let metadata = await LinkPreviewProvider.shared.fetchMetadata(for: url) {
                  self.linkMetadata = metadata
               }
            }
         }
      }
   }
   
   
   private func getProcessedText(text: String) -> NSAttributedString {
      let words = text.split(separator: " ")
      let processedWords = words.map { word -> String in
         if let url = FormValidator.extractFirstURL(from: String(word)) {
            return url.absoluteString
         }
         return String(word)
      }
      let processedText = processedWords.joined(separator: " ") + " \n"
      debugPrint("\(logTAG) \(#line) \(#function) \(processedText)")
      let attributes: [NSAttributedString.Key: Any] = [
         .font: UIFont.systemFont(ofSize: 18)
      ]
      return NSAttributedString(string: processedText, attributes: attributes)
   }
   
   @ViewBuilder
   private func textView(_ text: String) -> some View {
      if messageUseMarkdown,
         let attributed = try? AttributedString(markdown: text, options: String.markdownOptions) {
         Text(attributed)
      } else {
         let url = FormValidator.extractFirstURL(from: text)
         let email = FormValidator.extractFirstEmail(from: text)
         if let url = url {
            let attributedString = getProcessedText(text: text)
            TextViewWrapper(attributedText: attributedString)
               .fixedSize(horizontal: false, vertical: true)
               .lineLimit(nil)
               .frame(maxWidth: .infinity, alignment: .leading)
            //                    .font(.system(size: 36))
            //                    .font(.largeTitle)
               .onTapGesture {
                  UIApplication.shared.open(url)
               }
               .contextMenu {
                  Button("Open URL") {
                     UIApplication.shared.open(url)
                  }
               }
         } else if let email = email {
            let attributedString = getProcessedText(text: text)
            TextViewWrapper(attributedText: attributedString)
               .fixedSize(horizontal: false, vertical: true)
               .lineLimit(nil)
               .frame(maxWidth: .infinity, alignment: .leading)
               .onTapGesture {
                  let emailUrl = URL(string: "mailto:\(email)")!
                  UIApplication.shared.open(emailUrl)
               }
               .contextMenu {
                  Button("Copy Email") {
                     UIPasteboard.general.string = email
                  }
               }
            /*
             if FormValidator.extractFirstURL(from: text) != nil {
             let attributedString = getProcessedText(text: text)
             TextViewWrapper(attributedText: attributedString)
             .fixedSize(horizontal: false, vertical: true)
             .lineLimit(nil)
             .frame(maxWidth: .infinity, alignment: .leading)
             } else if FormValidator.extractFirstEmail(from: text) != nil {
             let attributedString = getProcessedText(text: text)
             TextViewWrapper(attributedText: attributedString)
             .fixedSize(horizontal: false, vertical: true)
             .lineLimit(nil)
             .frame(maxWidth: .infinity, alignment: .leading)*/
         } else {
            Text(text)
         }
      }
   }
   
}

struct TextViewWrapper: UIViewRepresentable {
   @EnvironmentObject var appEnvironment: AppEnvironment
   let attributedText: NSAttributedString
   
   func makeUIView(context: UIViewRepresentableContext<TextViewWrapper>) -> UITextView {
      let textView = UITextView()
      textView.isEditable = false
      textView.isScrollEnabled = false
      textView.isUserInteractionEnabled = true
      textView.isSelectable = true
      textView.backgroundColor = .clear
      textView.textColor = self.appEnvironment.messageTextColor
      textView.dataDetectorTypes = [.link]
      textView.linkTextAttributes = [
         .foregroundColor: self.appEnvironment.linkTextColor,
         .underlineStyle: NSUnderlineStyle.single.rawValue
      ]
      textView.translatesAutoresizingMaskIntoConstraints = false
      textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
      textView.setContentHuggingPriority(.defaultLow, for: .vertical)
      textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
      textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
      textView.attributedText = attributedText
      //        textView.textContainer.lineBreakMode = .byWordWrapping
      //        textView.textContainer.lineFragmentPadding = 0
      
      textView.adjustsFontForContentSizeCategory = true
      return textView
   }
   
   func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<TextViewWrapper>) {
      uiView.attributedText = attributedText
      uiView.textColor = self.appEnvironment.messageTextColor
      //        uiView.invalidateIntrinsicContentSize()
   }
   
   static func dismantleUIView(_ uiView: UITextView, coordinator: Self.Coordinator) {
      uiView.removeFromSuperview()
   }
}
