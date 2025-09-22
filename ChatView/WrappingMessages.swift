//
//  WrappingMessages.swift
//  PriCall3
//

import SwiftUI

extension ChatView {

    static func mapMessages(_ messages: [ExyteChatMessage], chatType: ChatType, replyMode: ReplyMode) -> [MessagesSection] {
        let result: [MessagesSection]
        switch replyMode {
        case .quote:
            result = mapMessagesQuoteModeReplies(messages, chatType: chatType, replyMode: replyMode)
        case .answer:
            result = mapMessagesCommentModeReplies(messages, chatType: chatType, replyMode: replyMode)
        }

        return result
    }

    static func mapMessagesQuoteModeReplies(_ messages: [ExyteChatMessage], chatType: ChatType, replyMode: ReplyMode) -> [MessagesSection] {
        let dates = Set(messages.map({ $0.createdAt.startOfDay() }))
            .sorted()
            .reversed()
        var result: [MessagesSection] = []

        for date in dates {
            let section = MessagesSection(
                date: date,
                rows: wrapMessages(messages.filter({ $0.createdAt.isSameDay(date) }), chatType: chatType, replyMode: replyMode)
            )
            result.append(section)
        }

        return result
    }

    static func mapMessagesCommentModeReplies(_ messages: [ExyteChatMessage], chatType: ChatType, replyMode: ReplyMode) -> [MessagesSection] {
        let firstLevelMessages = messages.filter { m in
            m.replyMessage == nil
        }

        let dates = Set(firstLevelMessages.map({ $0.createdAt.startOfDay() }))
            .sorted()
            .reversed()
        var result: [MessagesSection] = []

        for date in dates {
            let dayFirstLevelMessages = firstLevelMessages.filter({ $0.createdAt.isSameDay(date) })
            var dayMessages = [ExyteChatMessage]() // insert second level in between first level
            for m in dayFirstLevelMessages {
                var replies = getRepliesFor(id: m.id, messages: messages)
                replies.sort { $0.createdAt < $1.createdAt }
                if chatType == .conversation {
                    dayMessages.append(m)
                }
                dayMessages.append(contentsOf: replies)
                if chatType == .comments {
                    dayMessages.append(m)
                }
            }
            result.append(MessagesSection(date: date, rows: wrapMessages(dayMessages, chatType: chatType, replyMode: replyMode)))
        }

        return result
    }

    static private func getRepliesFor(id: String, messages: [ExyteChatMessage]) -> [ExyteChatMessage] {
        messages.compactMap { m in
            if m.replyMessage?.id == id {
                return m
            }
            return nil
        }
    }

    static func wrapMessages(_ messages: [ExyteChatMessage], chatType: ChatType, replyMode: ReplyMode) -> [MessageRow] {
        messages
            .enumerated()
            .map {(index, message) in
               let nextMessage: ExyteChatMessage? = {
                   if chatType == .conversation {
                       return index + 1 < messages.count ? messages[index + 1] : nil
                   } else {
                       return index - 1 >= 0 ? messages[index - 1] : nil
                   }
               }()
               
               let prevMessage: ExyteChatMessage? = {
                   if chatType == .conversation {
                       return index - 1 >= 0 ? messages[index - 1] : nil
                   } else {
                       return index + 1 < messages.count ? messages[index + 1] : nil
                   }
               }()
               
//                let index = $0.offset
//                let message = $0.element
//               let nextMessage = chatType == .conversation ? messages[index + 1] : messages[ index - 1]
//               let prevMessage = chatType == .conversation ? messages[index - 1] : messages[ index + 1]

                let nextMessageExists = nextMessage != nil
               let nextMessageIsSameUser = nextMessage?.user.id == message.user.id
                let prevMessageIsSameUser = prevMessage?.user.id == message.user.id

                let position: PositionInGroup
                if nextMessageExists, nextMessageIsSameUser, prevMessageIsSameUser {
                    position = .middle
                } else if !nextMessageExists || !nextMessageIsSameUser, !prevMessageIsSameUser {
                    position = .single
                } else if nextMessageExists, nextMessageIsSameUser {
                    position = .first
                } else {
                    position = .last
                }

                let nextMessageIsAReply = nextMessage?.replyMessage != nil
                let nextMessageIsFirstLevel = nextMessage?.replyMessage == nil
                let prevMessageIsFirstLevel = prevMessage?.replyMessage == nil

                let positionInComments: PositionInCommentsGroup
                if !nextMessageExists, message.replyMessage == nil {
                    positionInComments = .latestFirstLevelPost
                } else if !nextMessageExists {
                    positionInComments = .latestCommentInLatestGroup
                } else if message.replyMessage == nil && !nextMessageIsAReply {
                    positionInComments = .singleFirstLevelPost
                } else if message.replyMessage == nil && nextMessageIsAReply {
                    positionInComments = .firstLevelPost
                } else if nextMessageIsFirstLevel {
                    positionInComments = .lastComment
                } else if prevMessageIsFirstLevel {
                    positionInComments = .firstComment
                } else {
                    positionInComments = .middleComment
                }

                return MessageRow(message:message, positionInGroup: position, positionInCommentsGroup: positionInComments)
            }
            .reversed()
    }
}
