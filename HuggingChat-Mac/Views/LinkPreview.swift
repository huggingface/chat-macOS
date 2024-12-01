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
    @State private var averageColor: Color = .clear
    
    var body: some View {
        HStack(spacing: 7) {
            // Icon/Image View
            Group {
                if let iconProvider = metadata?.iconProvider {
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
                    .lineLimit(2)
                
                
                Text(link.hostname)
//                    .getContrastText(backgroundColor: averageColor)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
            }
            
        }

        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 5)
        .padding(.horizontal, 5)
//        .background(averageColor)
        .background(.regularMaterial)
        .cornerRadius(6)
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
        let provider = LPMetadataProvider()
        
        provider.startFetchingMetadata(for: link.link) { metadata, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching metadata: \(error)")
                }
                self.metadata = metadata
                self.isLoading = false
            }
        }
    }
}

// Helper view to display the icon
struct IconView: View {
    let iconProvider: NSItemProvider
    @Binding var averageColor: Color
    @State private var icon: NSImage?
    
    var body: some View {
        Group {
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(6)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            loadIcon()
        }
    }
    
    private func loadIcon() {
        iconProvider.loadObject(ofClass: NSImage.self) { image, error in
            if let error = error {
                print("Error loading icon: \(error)")
                return
            }
            
            DispatchQueue.main.async {
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
    VStack(spacing: 16) {
        LinkPreview(link: WebSearchSource(
            link: URL(string: "https://www.apple.com")!,
            title: "Apple",
            hostname: "apple.com"
        ))
        .frame(maxWidth: 160)
        
        LinkPreview(link: WebSearchSource(
            link: URL(string: "https://www.githusb.com")!,
            title: "GitHub",
            hostname: "github.com"
        ))
        .frame(maxWidth: 160)
    }
    .padding()
}
