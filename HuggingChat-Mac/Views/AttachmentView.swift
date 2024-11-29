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
    var attachment: LLMAttachment
    @State private var showRemoveButton: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 5) {
            if let icon = attachment.fileIcon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
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
            Spacer(minLength: 5)
            
            Button("Remove", systemImage: "xmark.circle.fill", action: {
                allAttachments.removeAll { $0.id == attachment.id }
            })
            .labelsHidden()
            .frame(width: 15)
            .frame(maxHeight: .infinity, alignment: .center)
            .opacity(showRemoveButton ? 1:0)
            .buttonStyle(.borderless)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 5)
        .padding(.leading, 10)
        .frame(height: 45)
        .frame(maxWidth: 160)
        .background(.primary.quinary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .fixedSize()
        .onHover { state in
            showRemoveButton = state
        }
    }
}
