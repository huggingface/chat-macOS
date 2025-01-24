//
//  LinkView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/24/25.
//

import Foundation
import SwiftUI
import LinkPresentation

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
    var iconOnly: Bool = false
    
    @State private var metadata: LPLinkMetadata?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var icon: NSImage?
    
    var body: some View {
        
        HStack(alignment: .top) {
                Group {
                    if isLoading {
                        ZStack {
                            Circle()
                                .fill(.gray.quinary)
                                .overlay {
                                    ProgressView()
                                        .controlSize(.mini)
                                }
                        }
                    } else if let icon = icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                    } else {
                        ZStack {
                            Circle()
                                .fill(.gray.quinary)
                                .overlay {
                                    Image(systemName: "link")
                                        .imageScale(.small)
                                }
                        }
                    }
                }
                .frame(width: 18, height: 18)
                
                VStack(alignment: .leading) {
                    if !iconOnly {
                        Text(link.title)
                            .fontWeight(.medium)
                        
                        if let metaURL = metadata?.url {
                            Text(metaURL.absoluteString)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        .padding(.vertical, 5)
        
        .task {
            await loadMetadata()
        }
        .onChange(of: metadata) { oldValue, newValue in
            if newValue != nil {
                if let iconProvider = newValue?.iconProvider {
                    Task {
                        do {
                            let loadedIcon = try await loadIcon(iconProvider: iconProvider)
                            await MainActor.run {
                                self.icon = loadedIcon
                            }
                        } catch {
                            self.error = error
                        }
                    }
                }
            }
            
        }
    }
    
    private func loadMetadata() async {
        if let cachedMetadata = MetadataCacheManager.shared.metadata(for: link.link.absoluteString) {
            await MainActor.run {
                self.metadata = cachedMetadata
                self.isLoading = false
            }
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        error = nil
        guard let validURL = URL(string: link.link.absoluteString) else {
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
                self.error = error
            }
        }
    }
    
    private func loadIcon(iconProvider: NSItemProvider) async throws -> NSImage {
        return try await withCheckedThrowingContinuation { continuation in
            iconProvider.loadObject(ofClass: NSImage.self) { image, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let nsImage = image as? NSImage else {
                    continuation.resume(throwing: NSError(
                        domain: "IconLoaderError",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to NSImage"]
                    ))
                    return
                }
                
                continuation.resume(returning: nsImage)
            }
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
                    .font(.headline)
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
                    .stroke(Color.gray.quinary, lineWidth: 1.5)
                    .fill(highlightOnHover ? Color.gray.quinary:Color.clear.quinary)
            }
        })
        .buttonStyle(.plain)
        .popover(isPresented: $showPopover, arrowEdge: .top) {
            SourcesListView(webSources: webSources)
                .frame(width: 400, height: 400)
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
                    LinkPreview(link: firstSource, iconOnly: true)
                        .frame(width: 18, height: 18)
                        .zIndex(Double(webSources.prefix(4).count))
                }
                
                // Subsequent circles with mask
                ForEach(Array(zip(webSources.prefix(4).dropFirst().indices, webSources.prefix(4).dropFirst())), id: \.0) { index, item in
                    LinkPreview(link: item, iconOnly: true)
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

// MARK: Subviews
struct SourcesListView: View {
    
    var webSources: [WebSearchSource]
    
    var body: some View {
        List {
            Section("Citations", content: {
                ForEach(webSources) { source in
                    LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                        LinkPreview(link: source, iconOnly: false)
                            .padding(.horizontal, 5)
                    }
                }
            })
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        
    }
}


#Preview {
    SourcesListView(webSources: [
        WebSearchSource(link: URL(string: "http://huggingface.co")!, title: "HuggingFace", hostname: "Google"),
        WebSearchSource(link: URL(string: "http://huggingface.co")!, title: "HuggingFace", hostname: "Google"),
        WebSearchSource(link: URL(string: "http://huggingface.co")!, title: "HuggingFace", hostname: "Google"),
        WebSearchSource(link: URL(string: "http://huggingface.co")!, title: "HuggingFace", hostname: "Google"),
        WebSearchSource(link: URL(string: "http://huggingface.co")!, title: "HuggingFace", hostname: "Google"),
        WebSearchSource(link: URL(string: "http://huggingface.co")!, title: "HuggingFace", hostname: "Google")
    ])
}
