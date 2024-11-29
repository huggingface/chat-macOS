//
//  InputView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/30/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct InputView: View {
    
    var isLocal: Bool = false
    
    @Environment(ModelManager.self) private var modelManager
    @Environment(ConversationViewModel.self) private var conversationModel
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var prompt: String
    @Binding var isSecondaryTextFieldVisible: Bool
    @Binding var animatablePrompt: String
    @Binding var isMainTextFieldVisible: Bool
    @Binding var allAttachments: [LLMAttachment]
    @Binding var startLoadingAnimation: Bool
    @Binding var isResponseVisible: Bool
    
    @FocusState private var focusedField: ChatView.FocusedField?
    @FocusState private var isMainTextFieldFocused: Bool
    
    @AppStorage("localModel") private var selectedLocalModel: String = "None"
    @AppStorage("externalModel") private var selectedExternalModel: String = "meta-llama/Meta-Llama-3.1-70B-Instruct"
    @AppStorage("isAppleClassicUnlocked") private var isAppleClassicUnlocked: Bool = false
    @AppStorage("selectedTheme") private var selectedTheme: String = "Default"
    
    // File importer
    @State private var showFileImporter = false {
        didSet {
            if let floatingPanel = NSApp.windows.first(where: { $0 is FloatingPanel }) as? FloatingPanel {
                floatingPanel.updateFileImporterVisibility(showFileImporter)
            }
        }
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if allAttachments.count > 0 {
                AttachmentView(allAttachments: $allAttachments)
            }
            ZStack {
                if isSecondaryTextFieldVisible {
                    TextField("", text: $animatablePrompt, axis: .vertical)
                        .font(ThemingEngine.shared.currentTheme.quickBarFont)
                        .id("hidden-\(selectedTheme)")
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .lineLimit(4)
                        .allowsHitTesting(false)
                        .transition(.asymmetric(insertion: .identity, removal: .move(edge: .bottom).combined(with: .opacity)))
                }
                TextField("Type your message", text: $prompt, axis: .vertical)
                    .font(ThemingEngine.shared.currentTheme.quickBarFont)
                    .id("main-\(selectedTheme)")
                    .textFieldStyle(.plain)
                    .focused($isMainTextFieldFocused)
                    .font(.title3)
                    .lineLimit(4)
                    .opacity(isMainTextFieldVisible ? 1:0)
                    .onSubmit {
                        if prompt == "Think different." && isAppleClassicUnlocked == false  {
                            isAppleClassicUnlocked = true
                            submitMessage()
                        }
                        if !prompt.isEmpty {
                            submitMessage()
                        }
                    }
            }
            .onChange(of: conversationModel.state) {
                if conversationModel.state == .generating {
                    withAnimation(.easeIn) {
                        startLoadingAnimation = true
                    }
                } else {
                    withAnimation(.easeIn) {
                        startLoadingAnimation = false
                    }
                }
            }
            .onChange(of: modelManager.running) {
                if modelManager.running {
                    withAnimation(.easeIn) {
                        startLoadingAnimation = true
                    }
                } else {
                    withAnimation(.easeIn) {
                        startLoadingAnimation = false
                    }
                }
            }
            HStack {
                Group {
                Menu {
                    Button {
                        showFileImporter = true
                    } label: {
                        Label("Import", systemImage: "doc.circle")
                    }
                    .keyboardShortcut("I", modifiers: [.command])
                    
                    Divider()
                    
                    // Conversations
                    if !isLocal {
                        Link(destination: URL(string: "https://huggingface.co/chat/conversation/" + (conversationModel.conversation?.id ?? ""))!, label: {
                            Label("Open Conversation", systemImage: "globe")
                        })
                        .keyboardShortcut("O")
                        .disabled(conversationModel.conversation?.id == nil)
                    }
                    
                    Button {
                        clearChat()
                    } label: {
                        Label("New Conversation", systemImage: "plus")
                    }
                    .keyboardShortcut("N", modifiers: [.command])
                    
                    Divider()
                    
                    // Settings
                    SettingsLink(label: {
                        Label("Settings...", systemImage: "gearshape")
                    })
                    .keyboardShortcut(",", modifiers: [.command])
                    
                    Divider()
                    
                    // Quit
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }, label: {
                        Label("Quit", systemImage: "xmark.circle")
                    })
                    .keyboardShortcut("Q")
                } label: {
                    Label("", systemImage: "plus")
                        .fontWeight(.semibold)
                }
                .focusEffectDisabled()
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 20, alignment: .leading)
                .fileImporter(
                    isPresented: $showFileImporter,
                    allowedContentTypes: (conversationModel.isMultimodal && !isLocal) ? [.text, .sourceCode, .image]:[.text, .sourceCode],
                    allowsMultipleSelection: true
                ) { result in
                    switch result {
                    case .success(let files):
                        files.forEach { url in
                            let gotAccess = url.startAccessingSecurityScopedResource()
                            if !gotAccess { return }
                            // Handle URL based on type
                            handleFileImport(url: url)
                            url.stopAccessingSecurityScopedResource()
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
                
                Button(action: {
                    // TODO: Start dictation
                }, label: {
                    Image(systemName: "mic.fill")
                        .fontWeight(.semibold)
                })
                .buttonStyle(.plain)
                
                Button(action: {
                    // TODO: Start dictation
                }, label: {
                    Image(systemName: "waveform")
                        .fontWeight(.semibold)
                })
                .buttonStyle(.plain)
            }
                
                
                Spacer()
                let externalModelName = selectedExternalModel.split(separator: "/", maxSplits: 1)[1]
                Label(isLocal ? selectedLocalModel:String(externalModelName), systemImage: isLocal ? "laptopcomputer":"globe")
                    .foregroundStyle(.tertiary)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .layoutPriority(100)
            }
    
            
        }
    }
    
    // Private methods
    private func handleFileImport(url: URL) {
        let filename = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()
        
        do {
            guard let typeID = try url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
                  let utType = UTType(typeID) else { return }
            guard let supertypes = UTType(typeID)?.supertypes else { return }
            if supertypes.contains(.image) {
                print("Image")
            } else if supertypes.contains(.text) {
                let textContents = try String(contentsOf: url)
                if !textContents.isEmpty {
                    let attachment = LLMAttachment(filename: filename, fileExtension: fileExtension, url: url, fileIcon: NSWorkspace.shared.icon(forFile: url.path()), fileType: utType, content: .text(textContents))
                    allAttachments.append(attachment)
                }
            }
        } catch {
            print("\(error.localizedDescription)")
        }
    }
    
    private func clearChat() {
        if isLocal {
            modelManager.clearText()
        } else {
            conversationModel.stopGenerating()
            conversationModel.reset()
            conversationModel.message = nil
        }
        allAttachments.removeAll()
        isResponseVisible = false
        prompt = ""
        animatablePrompt = ""
    }
    
    private func submitMessage() {
        isResponseVisible = true
        animatablePrompt = prompt
        isMainTextFieldVisible = false
        isSecondaryTextFieldVisible = true
        
        if !allAttachments.isEmpty {
            let filteredContents = allAttachments.filter { attachment in
                attachment.fileType.conforms(to: .sourceCode) || attachment.fileType.conforms(to: .text)
            }
            if !filteredContents.isEmpty {
                prompt += "\n\n" + filteredContents.compactMap { attachment in
                    switch attachment.content {
                    case .text(let content):
                        return "\(attachment.filename):\n\(content)"
                    }
                }.joined(separator: "\n\n")
            }
        }
        if isLocal {
            let localPrompt = prompt
            Task {
                await modelManager.generate(prompt: localPrompt)
            }
        } else {
            conversationModel.sendAttributed(text: prompt)
        }
        allAttachments = []
        prompt = ""
        withAnimation(.easeIn(duration: 0.2)) {
            isSecondaryTextFieldVisible = false
            isMainTextFieldVisible = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isMainTextFieldFocused = true
        }
    }
}

#Preview("dark") {
    ChatView()
        .frame(height: 300)
        .environment(ModelManager())
        .environment(ConversationViewModel())
        .colorScheme(.dark)
}

#Preview {
    InputView(isLocal: true, prompt: .constant(""), isSecondaryTextFieldVisible: .constant(false), animatablePrompt: .constant(""), isMainTextFieldVisible: .constant(true), allAttachments: .constant([]), startLoadingAnimation: .constant(true), isResponseVisible: .constant(false))
        .environment(ModelManager())
        .environment(\.colorScheme, .dark)
        .environment(ConversationViewModel())
}

