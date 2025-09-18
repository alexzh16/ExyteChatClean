//
//  Created by Alex.M on 16.06.2022.
//

import Foundation

public enum AttachmentType: String, Codable {
    case image
    case video
    case files
    
    public var title: String {
        switch self {
        case .image:
            return "Image"
        case .video:
            return "Video"
        default:
            return "Files"
        }
    }

    public init(mediaType: MediaType) {
        switch mediaType {
        case .image:
            self = .image
        case .video:
            self = .video
        case .files:
            self = .files
        }
    }
}

public struct Attachment: Codable, Identifiable, Hashable {
    public let id: String
    public let thumbnail: URL
    public let full: URL
    public let type: AttachmentType

    public init(id: String, thumbnail: URL, full: URL, type: AttachmentType) {
        self.id = id
        self.thumbnail = thumbnail
        self.full = full
        self.type = type
    }

    public init(id: String, url: URL, type: AttachmentType) {
        self.init(id: id, thumbnail: url, full: url, type: type)
    }
}
/*
// Новый enum, включающий новый кейс .files
public enum ExtendedMediaType: String, Codable {
    case image
    case video
    case files
    
    public init(mediaType: MediaType) {
        switch mediaType {
        case .image:
            self = .image
        case .video:
            self = .video
        case .files:
            self = .files
        }
    }
    
    public init(mediaType: MediaType?, defaultType: ExtendedMediaType = .files) {
        if let mediaType = mediaType {
            self.init(mediaType: mediaType)
        } else {
            self = defaultType
        }
    }
}

// Расширение для Media, добавляющее свойство extendedType
public extension Media {
    var extendedType: ExtendedMediaType {
        return ExtendedMediaType(mediaType: self.type)
    }
}
*/
