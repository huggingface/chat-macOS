//
//  InputView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/30/24.
//

import SwiftUI
import UniformTypeIdentifiers
import Pow

struct InputView: View {
    
    var isLocal: Bool = false
    
    @Environment(ModelManager.self) private var modelManager
    @Environment(ConversationViewModel.self) private var conversationModel
    @Environment(AudioModelManager.self) private var audioModelManager
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
    @AppStorage("inlineCodeHiglight") private var inlineCodeHiglight: AccentColorOption = .blue
    @AppStorage("selectedTheme") private var selectedTheme: String = "Default"
    @AppStorage("useContext") private var useContext: Bool = false
    
    @State private var showingContext: Bool = false
    
    // File importer
    @State private var showFileImporter = false {
        didSet {
            if let floatingPanel = NSApp.windows.first(where: { $0 is FloatingPanel }) as? FloatingPanel {
                floatingPanel.updateFileImporterVisibility(showFileImporter)
            }
        }
    }
    
    // Focus Mode
    @State private var shouldFocus = false {
        didSet {
            if let floatingPanel = NSApp.windows.first(where: { $0 is FloatingPanel }) as? FloatingPanel {
                floatingPanel.updateFocusMode(shouldFocus)
            }
        }
    }
    
    // STT
    @Binding var isTranscribing: Bool
    
    init(isLocal: Bool = false,
         prompt: Binding<String>,
         isSecondaryTextFieldVisible: Binding<Bool>,
         animatablePrompt: Binding<String>,
         isMainTextFieldVisible: Binding<Bool>,
         allAttachments: Binding<[LLMAttachment]>,
         startLoadingAnimation: Binding<Bool>,
         isResponseVisible: Binding<Bool>,
         isTranscribing: Binding<Bool>) {
        
        self.isLocal = isLocal
        _prompt = prompt
        _isSecondaryTextFieldVisible = isSecondaryTextFieldVisible
        _animatablePrompt = animatablePrompt
        _isMainTextFieldVisible = isMainTextFieldVisible
        _allAttachments = allAttachments
        _startLoadingAnimation = startLoadingAnimation
        _isResponseVisible = isResponseVisible
        _isTranscribing = isTranscribing
        
        // Initialize showingContext with the AppStorage value
        _showingContext = State(initialValue: UserDefaults.standard.bool(forKey: "useContext"))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showingContext {
                ContextView(showingContext: $showingContext)
                    .padding(.horizontal, -9)
                    .transition(.move(edge: .top).combined(with: .blurReplace).combined(with: .opacity))
            }
            
            Group {
                if !allAttachments.isEmpty {
                    AttachmentView(allAttachments: $allAttachments)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.smooth(duration: 0.3), value: allAttachments.isEmpty)
            
            ZStack {
                if isSecondaryTextFieldVisible {
                    TextField("", text: $animatablePrompt, axis: .vertical)
                        .font(ThemingEngine.shared.currentTheme.quickBarFont)
                        .id("hidden-\(selectedTheme)")
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .lineLimit(4)
                        .frame(minHeight: 50, alignment: .top)
                        .allowsHitTesting(false)
                        .transition(.asymmetric(insertion: .identity, removal: .move(edge: .bottom).combined(with: .opacity)))
                }
                TextField("Ask anything...", text: $prompt, axis: .vertical)
                    .font(ThemingEngine.shared.currentTheme.quickBarFont)
                    .id("main-\(selectedTheme)")
                    .textFieldStyle(.plain)
                    .focused($isMainTextFieldFocused)
                    .font(.title3)
                    .lineLimit(4)
                    .frame(minHeight: 50, alignment: .top)
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
            HStack(alignment: .center, spacing: 2) {
                Group {
                    Menu {
                        // For now disable multimodality for local models
                        if !isLocal {
                            Button {
                                showFileImporter = true
                            } label: {
                                Label("Import", systemImage: "doc.circle")
                            }
                            .keyboardShortcut("I", modifiers: [.command])
                            
                            Divider()
                            
                            Button {
                                shouldFocus.toggle()
                            } label: {
                                Label(shouldFocus ? "Exit Focus Mode":"Enter Focus Mode", systemImage: "viewfinder.circle")
                            }
                            .keyboardShortcut("F", modifiers: [.command])
                            
                            Divider()
                            
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
                        Label("", systemImage: "slider.horizontal.3")
                            .labelStyle(.iconOnly)
                            .fontWeight(.semibold)
                            .imageScale(.medium)
                        
                    }
                    .focusEffectDisabled()
                    .help("More")
                    .menuStyle(MenuButtonStyle())
                    .menuIndicator(.hidden)
                    .fileImporter(
                        isPresented: $showFileImporter,
                        allowedContentTypes: getAllowedContentTypes(
                            isMultimodal: conversationModel.isMultimodal,
                            isLocal: isLocal,
                            isTools: conversationModel.isTools
                        ),
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
                        withAnimation(.spring(dampingFraction: 1)) {
                            isTranscribing.toggle()
                        }
                    }, label: {
                        Image(systemName: isTranscribing ? "mic.fill":"mic")
                            .fontWeight(.semibold)
                    })
                    .buttonStyle(HighlightButtonStyle())
                    .help("Toggle dictation")
                    
                    Button(action: {
                        withAnimation(.smooth(duration: 0.3)) {
                            showingContext.toggle()
                        }
                    }, label: {
                        Image(systemName: showingContext ? "doc.viewfinder.fill":"doc.viewfinder")
                            .fontWeight(.semibold)
                            .imageScale(.medium)
                    })
                    .buttonStyle(HighlightButtonStyle())
                    .help("Toggle context")
                }
                
                
                Spacer()
                
                if isTranscribing {
                    AudioBarView()
                    
                } else {
                    let externalModelName = selectedExternalModel.split(separator: "/", maxSplits: 1)[1]
                    Label(isLocal ? selectedLocalModel:String(externalModelName), systemImage: isLocal ? "laptopcomputer":"globe")
                        .foregroundStyle(.gray.opacity(0.5))
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .labelStyle(SpacedLabelStyle(spacing: 5))
                        .layoutPriority(100)
                        .transition(.movingParts.wipe(
                            angle: .degrees(180),
                            blurRadius: 50
                        ))
                }
                
                
                
            }
            .frame(height: 30)
            
        }
        .onChange(of: showingContext) {
            useContext = showingContext
            if useContext {
                conversationModel.fetchContext()
            }
        }
        .padding(.horizontal)
    }
    
    // Private methods
    private func handleFileImport(url: URL) {
        let filename = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()
        
        do {
            // Check file size - 10MB = 10 * 1024 * 1024 bytes
            //            let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            //            let maxSize = 10 * 1024 * 1024
            //
            //            guard fileSize <= maxSize else {
            //                throw HFError.fileLimitExceeded
            //            }
            
            guard let typeID = try url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
                  let utType = UTType(typeID) else { return }
            guard let supertypes = UTType(typeID)?.supertypes else { return }
            
            if allAttachments.contains(where: {
                $0.filename == filename &&
                $0.fileExtension == fileExtension &&
                $0.url == url &&
                $0.fileType == utType
            }) {
                return
            }
            
            if supertypes.contains(.image) {
                guard let imageData = try? Data(contentsOf: url),
                      let image = NSImage(data: imageData) else {
                    print("Failed to load image data from \(url)")
                    return
                }
                let attachment = LLMAttachment(
                    filename: filename,
                    fileExtension: fileExtension,
                    url: url,
                    fileIcon: image,
                    fileType: utType,
                    content: .image(image)
                )
                withAnimation(.smooth(duration: 0.3)) {
                    allAttachments.append(attachment)
                }
                
            } else if supertypes.contains(.text) {
                let textContents = try String(contentsOf: url)
                if !textContents.isEmpty {
                    let attachment = LLMAttachment(filename: filename,
                                                   fileExtension: fileExtension,
                                                   url: url,
                                                   fileIcon: NSWorkspace.shared.icon(forFile: url.path()),
                                                   fileType: utType,
                                                   content: .text(textContents))
                    withAnimation(.smooth(duration: 0.3)) {
                        allAttachments.append(attachment)
                    }
                }
            } else if utType == .pdf || typeID == "com.adobe.pdf" || fileExtension == "pdf" {
                // PDF handling code here
                guard let pdfData = try? Data(contentsOf: url) else {
                    print("Failed to load PDF data from \(url)")
                    return
                }
                let attachment = LLMAttachment(
                    filename: filename,
                    fileExtension: fileExtension,
                    url: url,
                    fileIcon: NSWorkspace.shared.icon(forFile: url.path()),
                    fileType: utType,
                    content: .pdf(pdfData)
                )
                withAnimation(.smooth(duration: 0.3)) {
                    allAttachments.append(attachment)
                }
            } else {
                print("Unsupported file type:", supertypes)
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
        
        //        if !allAttachments.isEmpty {
        //            let filteredContents = allAttachments.filter { attachment in
        //                attachment.fileType.conforms(to: .sourceCode) || attachment.fileType.conforms(to: .text)
        //            }
        //            if !filteredContents.isEmpty {
        //                // TODO: Fix this for local when multimodality is added
        //                prompt += "\n\n" + filteredContents.compactMap { attachment in
        //                    switch attachment.content {
        //                    case .text(let content):
        //                        return "\(attachment.filename):\n\(content)"
        //                    case .image(_):
        //                        return prompt
        //                    case .pdf(_):
        //                        return prompt
        //                    }
        //                }.joined(separator: "\n\n")
        //            }
        //        }
        if isLocal {
            let localPrompt = prompt
            Task {
                await modelManager.generate(prompt: localPrompt)
            }
        } else {
            let attachmentURLs = allAttachments
                .compactMap { $0.url?.path } // Unwrap optional URLs and convert to String paths
            conversationModel.sendAttributed(text: prompt, withFiles: attachmentURLs)
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
    
    private func getAllowedContentTypes(isMultimodal: Bool, isLocal: Bool, isTools: Bool) -> [UTType] {
        switch (isLocal, isMultimodal, isTools) {
        case (true, _, _):         return [.text, .sourceCode]
        case (_, true, true):      return [.text, .sourceCode, .pdf, .image]
        case (_, true, false):     return [.image]
        case (_, false, true):     return [.text, .sourceCode, .pdf]
        case (_, false, false):    return []
        }
    }
}

#Preview("dark") {
    ChatView()
        .frame(height: 300)
        .environment(ModelManager())
        .environment(ConversationViewModel())
        .environment(AudioModelManager())
        .colorScheme(.dark)
}

//#Preview {
//    InputView(isLocal: true, prompt: .constant(""), isSecondaryTextFieldVisible: .constant(false), animatablePrompt: .constant(""), isMainTextFieldVisible: .constant(true), allAttachments: .constant([]), startLoadingAnimation: .constant(true), isResponseVisible: .constant(false), isTranscribing: .constant(false))
//        .environment(ModelManager())
//        .environment(\.colorScheme, .dark)
//        .environment(ConversationViewModel())
//        .environment(AudioModelManager())
//        .padding()
//}

