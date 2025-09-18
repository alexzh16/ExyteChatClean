//
//  SwiftUIView.swift
//
//
//  Created by Alisa Mylnikova on 12.07.2022.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct URLMediaModel {
    let url: URL
}

extension URLMediaModel: MediaModelProtocol {
    
    var mediaType: MediaType? {
        if url.isImageFile {
            return .image
        }
        if url.isVideoFile {
            return .video
        }
        return .files
    }
    
    var duration: CGFloat? {
        if mediaType == .video {
            return CMTimeGetSeconds(AVURLAsset(url: url).duration)
        }
        return nil
    }
    
    func getURL() async -> URL? {
        url
    }
    
    func getThumbnailURL() async -> URL? {
        switch mediaType {
        case .image:
            return url
            
        case .video:
            return await url.getThumbnailURL()
            
        case .files:
            // Генерируем миниатюру для файла и сохраняем её в кэш или временную директорию
            if let thumbnail = await ThumbnailGenerator.generateThumbnail(for: url, size: CGSize(width: 100, height: 100)),
               let data = thumbnail.pngData() {
                let tempDir = FileManager.default.temporaryDirectory
                let thumbnailURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
                try? data.write(to: thumbnailURL)
                return thumbnailURL
            }
            return nil
        case .none:
            return nil
        }
    }
        
    func getData() async throws -> Data? {
        try? Data(contentsOf: url)
    }
    
    func getThumbnailData() async -> Data? {
        switch mediaType {
        case .image:
            return try? Data(contentsOf: url)
            
        case .video:
            return await url.getThumbnailData()
            
        case .files:
            // Генерируем миниатюру для файла и возвращаем её данные
            if let thumbnail = await ThumbnailGenerator.generateThumbnail(for: url, size: CGSize(width: 100, height: 100)) {
                return thumbnail.pngData()
            }
            return nil
        case .none:
            return nil
        }
    }
}

extension URLMediaModel: Identifiable {
    var id: String {
        url.absoluteString
    }
}

extension URLMediaModel: Equatable {
    static func ==(lhs: URLMediaModel, rhs: URLMediaModel) -> Bool {
        lhs.id == rhs.id
    }
}
