//
//  AttachmentView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/26/24.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum AttachmentContent {
    case text(String)
    case image(NSImage)
}


struct LLMAttachment: Identifiable, Equatable {
    var id = UUID()
    var filename: String
    var fileExtension: String
    var url: URL?
    var fileIcon: NSImage?
    var fileType: UTType
    var content: AttachmentContent
    
    static func == (lhs: LLMAttachment, rhs: LLMAttachment) -> Bool {
        lhs.filename == rhs.filename &&
        lhs.fileExtension == rhs.fileExtension &&
        lhs.url == rhs.url &&
        lhs.fileType == rhs.fileType
    }
}

struct AttachmentView: View {
    
    @Binding var allAttachments: [LLMAttachment]
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 5) {
                ForEach(Array(allAttachments.enumerated()), id: \.element.id) { index, attachment in
                    AttachmentPill(allAttachments: $allAttachments, attachment: attachment)
                }
            }
        }
        .scrollIndicators(.never)
    }
}

struct AttachmentPill: View {
    
    @Binding var allAttachments: [LLMAttachment]
    var attachment: LLMAttachment?
    
    @State private var showRemoveButton: Bool = false
    
    var body: some View {
        if let attachment {
            ZStack {
                HStack(alignment: .center, spacing: 5) {
                    if let icon = attachment.fileIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .scaledToFit()
                            .mask(RoundedRectangle(cornerRadius: 5))
                            .frame(width: 30, height: 30)
                    } else {
                        Image(nsImage: NSWorkspace.shared.icon(for: attachment.fileType))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    }
                    Text("\(attachment.filename)")
                        .font(ThemingEngine.shared.currentTheme.markdownFont?.footnote ?? .footnote)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    Button(action: {
                        allAttachments.removeAll { $0.id == attachment.id }
                    }, label: {
                        Label("", systemImage: "xmark.circle.fill")
                            .labelStyle(.iconOnly)
                    })
                    .buttonStyle(.plain)
                    .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 5)
            .frame(height: 45)
            .frame(width: 160)
            .background(.primary.quinary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .fixedSize()
            .onHover { state in
                showRemoveButton = state
            }
        }
    }
}

#Preview {
    
    InputView(isLocal: true, prompt: .constant(""), isSecondaryTextFieldVisible: .constant(false), animatablePrompt: .constant(""), isMainTextFieldVisible: .constant(true), allAttachments: .constant([LLMAttachment(
        filename: "Sample Document.png",
        fileExtension: "png",
        url: URL(string: "file:///sample.png"),
        fileIcon: NSImage(named: "huggy.bp")!,
        fileType: .image,
        content: .image(NSImage(named: "huggy.bp")!)
    )]), startLoadingAnimation: .constant(true), isResponseVisible: .constant(false))
        .environment(ModelManager())
        .environment(\.colorScheme, .dark)
        .environment(ConversationViewModel())
//    AttachmentPill(allAttachments: .constant([]))
}
