//
//  LinkPreview.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 11/30/24.
//

import SwiftUI
import LinkPresentation

struct LinkPreview: View {
    var link: WebSearchSource
    @State private var metadata: LPLinkMetadata?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var averageColor: Color = .gray.opacity(0.3)
    
    var body: some View {
        HStack(spacing: 7) {
            // Icon/Image View
            Group {
                if isLoading {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 30, height: 30)
                        .overlay {
                            ProgressView()
                                .controlSize(.small)
                        }
                } else if let iconProvider = metadata?.iconProvider {
                    IconView(iconProvider: iconProvider, averageColor: $averageColor)
                        .frame(width: 30, height: 30)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 30, height: 30)
                        .overlay {
                            Image(systemName: "link")
                        }
                }
            }
            
            // Title and URL
            VStack(alignment: .leading, spacing: 0) {
                Text(metadata?.title ?? link.title)
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)
//                    .getContrastText(backgroundColor: averageColor)
                    .font(.caption2)
                    .lineLimit(1)
                
                Text(link.hostname)
//                    .getContrastText(backgroundColor: averageColor)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 5)
        .padding(.horizontal, 5)
        .background(.ultraThickMaterial)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.secondary.opacity(0.5), lineWidth: 1.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onTapGesture {
            NSWorkspace.shared.open(link.link)
        }
        .onAppear {
            if metadata == nil {
                loadMetadata()
            }
        }
    }
    
    private func loadMetadata() {
        isLoading = true
        error = nil
        
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: link.link) { metadata, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error fetching metadata: \(error)")
                    self.error = error
                    return
                }
                
                self.metadata = metadata
            }
        }
    }
}

struct IconView: View {
    let iconProvider: NSItemProvider
    @Binding var averageColor: Color
    @State private var icon: NSImage?
    @State private var loadError: Error?
    
    var body: some View {
        Group {
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(6)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                    if loadError != nil {
                        Image(systemName: "link")
                    } else {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
        }
        .onAppear {
            loadIcon()
        }
    }
    
    private func loadIcon() {
        iconProvider.loadObject(ofClass: NSImage.self) { image, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error loading icon: \(error)")
                    self.loadError = error
                    return
                }
                
                if let nsImage = image as? NSImage {
                    self.icon = nsImage
                    
                    // Calculate average color from CGImage
//                    if let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
//                        if let avgColor = findAverageColor(cgImage: cgImage, algorithm: .squareRoot) {
//                            self.averageColor = avgColor
//                        }
//                    }
                }
            }
        }
    }
}

// Preview
#Preview {
    VStack() {
        LinkPreview(link: WebSearchSource(
            link: URL(string: "https://www.apple.com")!,
            title: "Apple",
            hostname: "apple.com"
        ))
        
        
        LinkPreview(link: WebSearchSource(
            link: URL(string: "https://www.github.com")!,
            title: "GitHub",
            hostname: "github.com"
        ))
    }
    .padding(.horizontal)
    .frame(maxWidth: 160)
    
}
