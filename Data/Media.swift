//
//  Created by Alex.M on 31.05.2022.
//

import Foundation
import Combine

public enum MediaType {
    case image
    case video
    case files
}

public struct ExyteChatMedia: Identifiable, Equatable {
    public var id = UUID()
    internal let source: MediaModelProtocol

    public static func == (lhs: ExyteChatMedia, rhs: ExyteChatMedia) -> Bool {
        lhs.id == rhs.id
    }
}

public extension ExyteChatMedia {

    var type: MediaType {
        source.mediaType ?? .files
    }

    var duration: CGFloat? {
        source.duration
    }

    func getURL() async -> URL? {
        await source.getURL()
    }

    func getThumbnailURL() async -> URL? {
        await source.getThumbnailURL()
    }

    func getData() async -> Data? {
        try? await source.getData()
    }

    func getThumbnailData() async -> Data? {
        await source.getThumbnailData()
    }
}
