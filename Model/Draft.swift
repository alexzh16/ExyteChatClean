//
//  Created by Alex.M on 17.06.2022.
//

import Foundation

public struct DraftMessage {
    public var id: String?
    public let text: String
    public let recording: Recording?
    public let replyMessage: ReplyMessage?
    public var replyToMessageId: String?
    public let createdAt: Date
    public let medias: [Media]
    public let isReadMessage: Bool
    public var files: [FileAttachment]
    
    public init(id: String? = nil,
                text: String,
                medias: [Media],
                files: [FileAttachment],
                recording: Recording?,
                replyMessage: ReplyMessage?,
                createdAt: Date,
                isReadMessage: Bool? = false,
                replyToMessageId: String? = nil
    ) {
        self.id = id
        self.text = text
        self.medias = medias
        self.files = files
        self.recording = recording
        self.replyMessage = replyMessage
        self.createdAt = createdAt
        self.isReadMessage = isReadMessage ?? false
        self.replyToMessageId = replyToMessageId
    }
}
