//
//  Message.swift
//  Chat
//
//  Created by Alisa Mylnikova on 20.04.2022.
//

import SwiftUI

public struct ExyteChatMessage: Identifiable, Hashable {
   
   public enum Status: Equatable, Hashable {
      case sending
      case sent
      case read
      case error(DraftMessage)
      
      public func hash(into hasher: inout Hasher) {
         switch self {
         case .sending:
            hasher.combine("sending")
         case .sent:
            hasher.combine("sent")
         case .read:
            hasher.combine("read")
         case .error:
            hasher.combine("error")
         }
      }
      
      public static func == (lhs: ExyteChatMessage.Status, rhs: ExyteChatMessage.Status) -> Bool {
         switch (lhs, rhs) {
         case (.sending, .sending), (.sent, .sent), (.read, .read), (.error(_), .error(_)):
            return true
         default:
            return false
         }
      }
   }
   
   public var id: String
   public var user: ExyteChatUser
   public var status: Status?
   public var createdAt: Date
   
   public var text: String
   public var attachments: [Attachment]
   public var recording: ExyteChatRecording?
   public var replyMessage: ReplyMessage?
   public var replyToMessageId: String?
   public var links: [URL]
   public var triggerRedraw: UUID?
   
   public init(id: String,
               user: ExyteChatUser,
               status: Status? = nil,
               createdAt: Date = Date(),
               text: String = "",
               attachments: [Attachment] = [],
               recording: ExyteChatRecording? = nil,
               replyMessage: ReplyMessage? = nil,
               replyToMessageId: String? = nil,
               links: [URL] = []) {
      
      self.id = id
      self.user = user
      self.status = status
      self.createdAt = createdAt
      self.text = text
      self.attachments = attachments
      self.recording = recording
      self.replyMessage = replyMessage
      self.replyToMessageId = replyToMessageId
      self.links = links
   }
   
   public static func makeMessage(
      id: String,
      user: ExyteChatUser,
      status: Status? = nil,
      draft: DraftMessage
   ) async -> ExyteChatMessage {
      let attachments = await draft.medias.asyncCompactMap { media -> Attachment? in
         guard let thumbnailURL = await media.getThumbnailURL() else {
            return nil
         }
         
         switch media.type {
         case .image:
            return Attachment(id: UUID().uuidString, url: thumbnailURL, type: .image)
         case .video:
            guard let fullURL = await media.getURL() else {
               return nil
            }
            return Attachment(id: UUID().uuidString, thumbnail: thumbnailURL, full: fullURL, type: .video)
         case .files:
            guard let fullURL = await media.getURL() else {
               return nil
            }
            return Attachment(id: UUID().uuidString, thumbnail: thumbnailURL, full: fullURL, type: .files)
         }
      }
      
      return ExyteChatMessage(id: id, user: user, status: status, createdAt: draft.createdAt, text: draft.text, attachments: attachments, recording: draft.recording, replyMessage: draft.replyMessage)
   }
}

extension ExyteChatMessage {
   var time: String {
      DateFormatter.timeFormatter.string(from: createdAt)
   }
}

extension ExyteChatMessage: Equatable {
   public static func == (lhs: ExyteChatMessage, rhs: ExyteChatMessage) -> Bool {
      lhs.id == rhs.id &&
      lhs.user == rhs.user &&
      lhs.status == rhs.status &&
      lhs.createdAt == rhs.createdAt &&
      lhs.text == rhs.text &&
      lhs.attachments == rhs.attachments &&
      lhs.recording == rhs.recording &&
      lhs.replyMessage == rhs.replyMessage
   }
}

public struct ExyteChatRecording: Codable, Hashable {
   public var duration: Double
   public var waveformSamples: [CGFloat]
   public var url: URL?
   
   public init(duration: Double = 0.0, waveformSamples: [CGFloat] = [], url: URL? = nil) {
      self.duration = duration
      self.waveformSamples = waveformSamples
      self.url = url
   }
}

public struct ReplyMessage: Codable, Identifiable, Hashable {
   public static func == (lhs: ReplyMessage, rhs: ReplyMessage) -> Bool {
      lhs.id == rhs.id &&
      lhs.user == rhs.user &&
      lhs.createdAt == rhs.createdAt &&
      lhs.text == rhs.text &&
      lhs.attachments == rhs.attachments &&
      lhs.recording == rhs.recording
   }
   
   public var id: String
   public var user: ExyteChatUser
   public var createdAt: Date
   public var text: String
   public var attachments: [Attachment]
   public var recording: ExyteChatRecording?
   
   public init(id: String,
               user: ExyteChatUser,
               createdAt: Date = Date(),
               text: String = "",
               attachments: [Attachment] = [],
               recording: ExyteChatRecording? = nil) {
      
      self.id = id
      self.user = user
      self.createdAt = createdAt
      self.text = text
      self.attachments = attachments
      self.recording = recording
   }
   
   func toMessage() -> ExyteChatMessage {
      ExyteChatMessage(id: id, user: user, text: text, attachments: attachments, recording: recording)
   }
}

public extension ExyteChatMessage {
    func toReplyMessage() -> ReplyMessage {
        ReplyMessage(id: id, user: user, createdAt: createdAt, text: text, attachments: attachments, recording: recording)
    }
}

//public extension ExyteChatMessage {
//   func toReplyMessage() async -> ReplyMessage {
//      await ReplyMessage.createReplyMessage(id: id, user: user, text: text, originalMessage: self)
//   }
//}
//
//// метод для создания ответа на сообщение с генерацией миниатюр
public extension ReplyMessage {
   static func createReplyMessage(
      id: String,
      user: ExyteChatUser,
      createdAt: String = "",
      text: String = "",
      originalMessage: ExyteChatMessage
   ) async -> ReplyMessage {
      let attachments = await originalMessage.attachments.asyncCompactMap { attachment -> Attachment? in
         let url = attachment.full
         let mediaModel = URLMediaModel(url: url)
         
         guard let thumbnailURL = await mediaModel.getThumbnailURL() else {
            return nil
         }
         
         // Создаем новый Attachment с миниатюрой
         switch mediaModel.mediaType {
         case .image:
            return Attachment(id: attachment.id, url: thumbnailURL, type: .image)
         case .video:
            guard let fullURL = await mediaModel.getURL() else {
               return nil
            }
            return Attachment(id: attachment.id, thumbnail: thumbnailURL, full: fullURL, type: .video)
         case .files:
            guard let fullURL = await mediaModel.getURL() else {
               return nil
            }
            return Attachment(id: attachment.id, thumbnail: thumbnailURL, full: fullURL, type: .files)
         case .none:
            return nil
         }
      }
      
      return ReplyMessage(id: id, user: user, text: text, attachments: attachments)
   }
}
