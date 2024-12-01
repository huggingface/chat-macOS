//
//  ResponseToolBar.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 11/29/24.
//

import SwiftUI
import Pow
import QuickLook
import UniformTypeIdentifiers

struct AnimatedImageView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var quickLookURL: URL?
    @State private var imageDataToExport: Data?
    @State private var isAnimating: Bool = false
    let imageURL: URL
    
    // File exporter
    @State private var showFileExporter = false {
        didSet {
            if let floatingPanel = NSApp.windows.first(where: { $0 is FloatingPanel }) as? FloatingPanel {
                floatingPanel.updateFileImporterVisibility(showFileExporter)
            }
        }
    }
    
    private func prepareForExport() {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                DispatchQueue.main.async {
                    self.imageDataToExport = data
                    self.showFileExporter = true
                }
            } catch {
                print("Error preparing for export: \(error)")
            }
        }
    }
    
    private func copyToClipboard() {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                if let nsImage = NSImage(data: data) {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.writeObjects([nsImage])
                }
            } catch {
                print("Error copying to clipboard: \(error)")
            }
        }
    }
    
    private func prepareForQuickLook() {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                
                // Create temporary file for Quick Look
                let tempDir = FileManager.default.temporaryDirectory
                let tempFileURL = tempDir.appendingPathComponent(UUID().uuidString + ".png")
                
                try data.write(to: tempFileURL)
                
                DispatchQueue.main.async {
                    self.quickLookURL = tempFileURL
                }
            } catch {
                print("Error preparing for Quick Look: \(error)")
            }
        }
    }
    
    var body: some View {
        ZStack {
            AsyncImage(
                url: imageURL,
                transaction: .init(animation: .easeInOut(duration: 1.8))
            ) { phase in
                ZStack {
                    if colorScheme == .dark {
                        Color.black
                            .frame(width: 100, height: 100)
                            .opacity(isAnimating ? 1:0)
                            
                    } else {
                        Color.clear
                            .frame(width: 100, height: 100)
                            .opacity(isAnimating ? 1:0)
                            
                    }
                    
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .zIndex(1)
                            .transition(colorScheme == .dark ? .movingParts.filmExposure:.movingParts.snapshot)
                            .onTapGesture {
                                prepareForQuickLook()
                            }
                            .contextMenu {
                                Button {
                                    prepareForExport()
                                } label: {
                                    Label("Save As...", systemImage: "square.and.arrow.down.on.square")
                                }
                                
                                Button {
                                    copyToClipboard()
                                } label: {
                                    Label("Copy Image", systemImage: "doc.on.doc")
                                }
                            }
                        
                    case .failure(_):
                        ZStack(alignment: .center) {
                            if colorScheme == .dark {
                                Color.black
                            } else {
                                Color.clear
                            }
                            VStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .imageScale(.large)
                                    .symbolVariant(.slash)
                                Text("Error loading image")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }.padding(.horizontal, 5)
                            
                        }
                        .aspectRatio(1, contentMode: .fit)
                        
                        .transition(.opacity)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .frame(height: 100)

                        
                        //                .frame(maxWidth: .infinity, alignment: .leading)
                    
                    case .empty:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
                .onAppear {
                    withAnimation(.easeInOut) {
                        isAnimating = true
                    }
                }
                .aspectRatio(contentMode: .fit)
            }
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 100)
        .quickLookPreview($quickLookURL)
        .fileExporter(
            isPresented: $showFileExporter,
            document: imageDataToExport.map { ImageFileDocument(imageData: $0) },
            contentType: .png,
            defaultFilename: "image.png"
        ) { result in
            if case .failure(let error) = result {
                print("Error exporting file: \(error.localizedDescription)")
            }
        }
    }
}

// Document type for file export
struct ImageFileDocument: FileDocument {
    static var readableContentTypes = [UTType.png]
    
    let imageData: Data
    
    init(imageData: Data) {
        self.imageData = imageData
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.imageData = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: imageData)
    }
}

#Preview {
    AnimatedImageView(imageURL: URL(string: "https://huggingface.co/chat/conversation/674be2b16a073f26942d7cd6/output/c90fe5b3b6342fba6994ae51460ff48859ceb0516fbceb35c10f3641bd1661ad")!)
        .frame(width: 400)
}
