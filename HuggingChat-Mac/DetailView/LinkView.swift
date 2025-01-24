//
//  LinkView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/24/25.
//

import Foundation
import SwiftUI
import LinkPresentation
import NukeUI

// Cache manager to avoid fetching link metadata from web when needed
final class MetadataCacheManager {
    static let shared = MetadataCacheManager()
    private let cache = NSCache<NSString, LPLinkMetadata>()
    
    private init() {
        cache.countLimit = 100 // Maximum number of items
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    func metadata(for url: String) -> LPLinkMetadata? {
        return cache.object(forKey: url as NSString)
    }
    
    func setMetadata(_ metadata: LPLinkMetadata, for url: String) {
        cache.setObject(metadata, forKey: url as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}


struct LinkPreview: View {
    var link: WebSearchSource
    @State private var metadata: LPLinkMetadata?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var averageColor: Color = .gray.opacity(0.3)
    
    var body: some View {
        HStack(spacing: 7) {
            Group {
                if isLoading {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 25, height: 25)
                        .overlay(ProgressView().controlSize(.small))
                } else if let iconProvider = metadata?.iconProvider {
                    Circle()
//                    IconView(iconProvider: iconProvider, averageColor: $averageColor)
//                        .frame(width: 25, height: 25)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.tertiary)
                        .frame(width: 25, height: 25)
                        .overlay {
                            Image(systemName: "link")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(.tertiary)
                                .frame(width: 15, height: 15)
                        }
                }
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(metadata?.title ?? link.link.absoluteString)
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)
                    .font(.caption2)
                    .lineLimit(1)
                Text(link.link.absoluteString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .background(Color.gray.quinary)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary.opacity(0.2), lineWidth: 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
//            if let validURL = URL(string: link.url) {
//                UIApplication.shared.open(validURL)
//            }
        }
        .task {
            await loadMetadata()
        }
    }
    
    private func loadMetadata() async {
        print("Loading metatadata")
        if let cachedMetadata = MetadataCacheManager.shared.metadata(for: link.link.absoluteString) {
            print("Found metatadata in cache")
            await MainActor.run {
                self.metadata = cachedMetadata
                self.isLoading = false
            }
            return
        }
        
        isLoading = true
        error = nil
        
        guard let validURL = URL(string: link.link.absoluteString) else {
            print("Invalid URL")
            self.isLoading = false
            self.error = URLError(.badURL)
            return
        }
        
        let provider = LPMetadataProvider()
        
        do {
            let fetchedMetadata = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<LPLinkMetadata, Error>) in
                provider.startFetchingMetadata(for: validURL) { metadata, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let metadata = metadata {
                        continuation.resume(returning: metadata)
                    } else {
                        continuation.resume(throwing: URLError(.unknown))
                    }
                }
            }
            
            // Cache the fetched metadata
            MetadataCacheManager.shared.setMetadata(fetchedMetadata, for: link.link.absoluteString)
            
            await MainActor.run {
                self.metadata = fetchedMetadata
            }
        } catch {
            await MainActor.run {
                print("Error fetching metadata: \(error)")
                self.error = error
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
}

// MARK: Subviews
struct SourcesPillView: View {
    
    var webSources: [WebSearchSource]
    @State var highlightOnHover: Bool = false
    @State var showPopover: Bool = false
    
    var body: some View {
        let remainingCount = max(webSources.count - 4, 0)
        Button(action: {
            showPopover = true
        }, label: {
            HStack {
                Text("Sources")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                linkPhotoArray()
                
                if remainingCount > 0 {
                    Text("+\(remainingCount)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                        
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.quinary, lineWidth: 1)
                    .fill(highlightOnHover ? Color.gray.quinary:Color.clear.quinary)
            }
        })
        .buttonStyle(.plain)
        .popover(isPresented: $showPopover, arrowEdge: .top) {
                    Text("Your content here")
                        .font(.headline)
                        .padding()
                }
        .onHover { isHovering in
            highlightOnHover = isHovering
        }
        
        
    }
    
    @ViewBuilder
    func linkPhotoArray() -> some View {
       

            HStack(spacing: -5) {
                // First circle without mask
                if let firstSource = webSources.first {
                    Circle()
                        .fill(.gray.quinary)
                        .frame(width: 18, height: 18)
                        .zIndex(Double(webSources.prefix(4).count))
                }
                
                // Subsequent circles with mask
                ForEach(Array(zip(webSources.prefix(4).dropFirst().indices, webSources.prefix(4).dropFirst())), id: \.0) { index, item in
                    Circle()
                        .fill(.gray.quinary)
                        .frame(width: 18, height: 18)
                        .zIndex(Double(webSources.prefix(4).count - index - 1))
                        .blendMode(.destinationOver)
                }
                .mask {
                    ZStack(alignment: .center) {
                        Rectangle()
                        Circle()
                            .frame(width: 17, height: 20, alignment: .center)
                            .offset(x:-10)
                            .blendMode(.destinationOut)
                    }
                }
            }
    }
}



#Preview {
    SourcesPillView(webSources: [
        WebSearchSource(link: URL(string: "https://www.google.com")!, title: "", hostname: "Google"),
        WebSearchSource(link: URL(string: "https://www.google.com")!, title: "", hostname: "Google"),
        WebSearchSource(link: URL(string: "https://www.google.com")!, title: "", hostname: "Google"),
        WebSearchSource(link: URL(string: "https://www.google.com")!, title: "", hostname: "Google"),
        WebSearchSource(link: URL(string: "https://www.google.com")!, title: "", hostname: "Google"),
        WebSearchSource(link: URL(string: "https://www.google.com")!, title: "", hostname: "Google")
    ])
}
