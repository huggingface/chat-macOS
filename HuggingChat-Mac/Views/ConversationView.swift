//
//  ConversationView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 12/13/24.
//

import SwiftUI

enum FocusedField {
    case localInput
    case serverInput
}

struct SidebarContent: View {
    @Environment(MenuViewModel.self) private var menuModel
    @Environment(ConversationViewModel.self) private var conversationModel
    
    private let sectionOrder = ["Today", "This Week", "This Month", "Older"]
    
    var body: some View {
        List(selection: Binding(
                   get: { menuModel.currentConversationId },
                   set: { menuModel.currentConversationId = $0 }
        )) {
            ForEach(sectionOrder, id: \.self) { section in
                Section(section) {
                    ForEach(menuModel.conversations[section] ?? []) { conversation in
                        
                            Text(conversation.title)
                            .tag(conversation.serverId)
                                .lineLimit(1)
                            
                        
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .task {
            menuModel.getConversations()
            menuModel.refreshState()
        }
    }
}

struct DetailContent: View {
    
    
    @Environment(ModelManager.self) private var modelManager
    @Environment(MenuViewModel.self) private var menuModel
    @Environment(ConversationViewModel.self) private var conversationModel
    @Environment(AudioModelManager.self) private var audioModelManager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appearance") private var appearance: Appearance = .auto
    @AppStorage("inlineCodeHiglight") private var inlineCodeHiglight: AccentColorOption = .blue
    @AppStorage("lightCodeBlockTheme") private var lightCodeBlockTheme: String = "xcode"
    @AppStorage("darkCodeBlockTheme") private var darkCodeBlockTheme: String = "monokai-sublime"
    @AppStorage("selectedTheme") private var selectedTheme: String = "Default"
    @AppStorage("localModel") private var selectedLocalModel: String = "None"
    @AppStorage("isLocalGeneration") private var isLocalGeneration: Bool = false
    
    // Theme
    @AppStorage("isAppleClassicUnlocked") var isAppleClassicUnlocked: Bool = false
    @AppStorage("isChromeDinoUnlocked") var isChromeDinoUnlocked: Bool = false
    
    // Audio
    @AppStorage("selectedAudioModel") private var selectedAudioModel: String = "None"
    @AppStorage("selectedAudioInput") private var selectedAudioInput: String = "None"
    @AppStorage("smartDictation") private var smartDictation: Bool = false
    @AppStorage("useContext") private var useContext: Bool = false
    
    // Animation
    @State var cardIndex: Int = 0
    
    // Text field
    @State private var prompt: String = ""
    @FocusState private var focusedField: FocusedField?
    @State private var isMainTextFieldVisible: Bool = true
    
    @State private var isSecondaryTextFieldVisible: Bool = false
    @State private var animatablePrompt: String = ""
    @State private var startLoadingAnimation: Bool = false
    
    // Chat history handling
    @AppStorage("chatClearInterval") private var chatClearInterval: String = "never"
    @State private var lastChatTime: Date = Date()
    
    // File handling
    @State private var allAttachments: [LLMAttachment] = []
    
    // Error
    @State var errorAttempts: Int = 0
    @State private var errorSize: CGSize = CGSize(width: 0, height: 100)
    
    // Response
    @State var meshSpeed: CGFloat = 0.4
    @State private var responseSize: CGSize = CGSize(width: 0, height: 320)
    
    // STT
    @State private var isTranscribing: Bool = false
    var isLocal: Bool
    
    var body: some View {
        NavigationStack {
            if !isLocal {
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 15) {
                            ForEach(conversationModel.messages) { message in
                                MessageView(message: message)
                            }
                        }
                    }.overlay {
                        if conversationModel.messages.isEmpty {
                            ZStack {
                                Image("huggy")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .symbolRenderingMode(.none)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 45, height: 45)
                            }
                            .frame(maxHeight: .infinity, alignment: .center)
                        }
                    }
                    .contentMargins(.horizontal, 20, for: .scrollContent)
                    .contentMargins(.top, 10, for: .scrollContent)
                    .contentMargins(.bottom, -40, for: .scrollContent)
                    .scrollIndicators(.hidden)
                    .safeAreaInset(edge: .bottom, content: {
                        if selectedLocalModel != "None" {
                            CardStack([
                                AnyView(localInputView.focused($focusedField, equals: .localInput)), // It physically pains me to do type erasure like this
                                AnyView(serverInputView.focused($focusedField, equals: .serverInput)),
                            ], selectedIndex: $cardIndex)
                            
                        } else {
                            serverInputView.focused($focusedField, equals: .serverInput)
                        }
                    })
                    .defaultScrollAnchor(.bottom)
                }
            }
        }
        // Prevent content from causing layout shifts
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        .onAppear {
            if isLocalGeneration {
                cardIndex = 0
                focusedField = .localInput
            } else {
                cardIndex = 1
                focusedField = .serverInput
            }
            conversationModel.getActiveModel()
            checkAndClearChat()
            
        }
        
        .onChange(of: menuModel.currentConversationId) {
            if let conversation = menuModel.getConversation(withServerId: menuModel.currentConversationId) {
                conversationModel.loadConversation(conversation)
            }
        }
        
        .onChange(of: conversationModel.state) {
            if conversationModel.state == .error {
                prompt = animatablePrompt
                isChromeDinoUnlocked = true
                withAnimation(.default) {
                    self.errorAttempts += 1
                }
            }
        }
        .onChange(of:  modelManager.loadState.isError) {
            if modelManager.loadState.isError {
                prompt = animatablePrompt
                isChromeDinoUnlocked = true
                withAnimation(.default) {
                    self.errorAttempts += 1
                }
            }
        }
        
        .preferredColorScheme(colorScheme(for: appearance))
        .onChange(of: cardIndex) {
            if cardIndex == 0 {
                focusedField = .localInput
            } else if cardIndex == 1{
                focusedField = .serverInput
            }
        }
        
        
        // MARK: STT
        .onChange(of: isTranscribing) {
            if isTranscribing {
                if selectedAudioModel != "None" && selectedAudioInput != "None" && audioModelManager.modelState == .loaded  {
                    audioModelManager.resetState()
                    audioModelManager.startRecording(true, source: .chat)
                }
            } else {
                audioModelManager.stopRecording(false)
            }
        }
        .onChange(of: audioModelManager.isTranscriptionComplete) { old, new in
            if audioModelManager.isTranscriptionComplete && audioModelManager.transcriptionSource == .chat {
                prompt += audioModelManager.getFullTranscript()
            }
        }
    }
    
    @ViewBuilder
    private var localInputView: some View {
        
        InputView(
            isLocal: true,
            prompt: $prompt,
            isSecondaryTextFieldVisible: $isSecondaryTextFieldVisible,
            animatablePrompt: $animatablePrompt,
            isMainTextFieldVisible: $isMainTextFieldVisible,
            allAttachments: $allAttachments,
            startLoadingAnimation: $startLoadingAnimation,
            isTranscribing: $isTranscribing
        )
        .padding(.vertical, 7)
        .background(.regularMaterial)
        .overlay(content: {
            if startLoadingAnimation {
                ZStack {
                    AnimatedMeshGradient(colors: ThemingEngine.shared.currentTheme.animatedMeshMainColors, speed: $meshSpeed)
                        .mask {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(lineWidth: 6.0)
                        }
                }
                .transition(.opacity)
                .allowsHitTesting(false)
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.secondary.opacity(0.5), lineWidth: 1.0)
            }
        })
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        //        .fixedSize(horizontal: false, vertical: true)
        .padding([.bottom, .horizontal], 15)
        .padding(.top, 5)
    }
    
    @ViewBuilder
    private var serverInputView: some View {
        InputView(
            prompt: $prompt,
            isSecondaryTextFieldVisible: $isSecondaryTextFieldVisible,
            animatablePrompt: $animatablePrompt,
            isMainTextFieldVisible: $isMainTextFieldVisible,
            allAttachments: $allAttachments,
            startLoadingAnimation: $startLoadingAnimation,
            isTranscribing: $isTranscribing
        )
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 20.0)
                .fill(.ultraThickMaterial)
//                            .opacity(0.25)
                            .shadow(radius: 10.0)
                            
        }
//        .background(.quinary)
        .overlay(content: {
            if startLoadingAnimation {
                ZStack {
                    AnimatedMeshGradient(colors: ThemingEngine.shared.currentTheme.animatedMeshMainColors, speed: $meshSpeed)
                        .mask {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(lineWidth: 6.0)
                        }
                }
                .transition(.opacity)
                .allowsHitTesting(false)
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.secondary.opacity(0.5), lineWidth: 1.0)
            }
        })
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        //        .fixedSize(horizontal: false, vertical: true)
        .padding([.bottom, .horizontal], 15)
        .padding(.top, 5)
    }
    
    
    private func colorScheme(for appearance: Appearance) -> ColorScheme? {
        switch appearance {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            return nil
        }
    }
    
    private func checkAndClearChat() {
        let currentTime = Date()
        let timeInterval = currentTime.timeIntervalSince(lastChatTime)
        
        switch chatClearInterval {
        case "15min":
            if timeInterval >= 15 * 60 {
                clearChat()
            }
        case "1hour":
            if timeInterval >= 60 * 60 {
                clearChat()
            }
        case "1day":
            if timeInterval >= 24 * 60 * 60 {
                clearChat()
            }
        case "never":
            // Do nothing
            break
        default:
            // Handle unexpected values
            print("Unexpected chat clear interval: \(chatClearInterval)")
        }
    }
    
    private func clearChat() {
        allAttachments.removeAll()
        conversationModel.stopGenerating()
        conversationModel.reset()
        modelManager.clearText()
        conversationModel.message = nil
        prompt = ""
        animatablePrompt = ""
    }
}

struct ConversationView: View {
    
    @Environment(ConversationViewModel.self) private var conversationModel
    @Environment(ModelManager.self) private var modelManager
    @Environment(MenuViewModel.self) private var menuModel
    
    @AppStorage("inlineCodeHiglight") private var inlineCodeHiglight: AccentColorOption = .blue
    @AppStorage("lightCodeBlockTheme") private var lightCodeBlockTheme: String = "xcode"
    @AppStorage("darkCodeBlockTheme") private var darkCodeBlockTheme: String = "monokai-sublime"
    
    //    @Binding var responseSize: CGSize
    
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    var isLocal: Bool = false
    
    var body: some View {
        
        NavigationSplitView(columnVisibility: $columnVisibility,
                            preferredCompactColumn: .constant(.sidebar),
                            sidebar: {
            SidebarContent()
                .navigationSplitViewColumnWidth(150)
        }, detail: {
            //            Color.green
            DetailContent(isLocal: isLocal)
                
        })
        
        
        
        
        
        //        .background(.ultraThickMaterial)
        //        .overlay {
        //            RoundedRectangle(cornerRadius: 16, style: .continuous)
        //                .stroke(.secondary.opacity(0.5), lineWidth: 1.0)
        //        }
        //        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        
        
    }
}

//#Preview {
//    ConversationView(isResponseVisible: .constant(true), responseSize: .constant(CGSize(width: 300, height: 500)))
//        .environment(ModelManager())
//        .environment(ConversationViewModel())
//}

#Preview("dark") {
    ZStack(alignment: .top) {
        ChatView()
            .frame(width: 400, height: 400)
            .environment(ModelManager())
            .environment(ConversationViewModel())
            .environment(AudioModelManager())
            .environment(MenuViewModel())
//            .colorScheme(.dark)
    }
}
