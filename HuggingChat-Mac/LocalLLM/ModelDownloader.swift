//
//  ModelDownloader.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import SwiftUI

@Observable class ModelDownloader: ObservableObject {
    var progress: Float = 0
    var totalSize: Float = 0
    var isDownloading: Bool = false
    
    var progressString: String {
        guard totalSize > 0 else { return "0 MB of 0 MB (0%)" }
        
        let downloadedSize = progress * totalSize
        let percentage = Int(progress * 100)
        
        let downloadedSizeMB = String(format: "%.1f", downloadedSize / 1_000_000)
        let totalSizeMB = String(format: "%.1f", totalSize / 1_000_000)
        
        return "\(downloadedSizeMB) MB of \(totalSizeMB) MB (\(percentage)%)"
    }
}
