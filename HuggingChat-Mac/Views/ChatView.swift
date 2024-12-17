//import Models
import UniformTypeIdentifiers
import MarkdownView
import SwiftUI
import WhisperKit

struct ChatView: View {
    
    @Environment(ModelManager.self) private var modelManager
    @Environment(ConversationViewModel.self) private var conversationModel
    @Environment(AudioModelManager.self) private var audioModelManager
    @Environment(MenuViewModel.self) private var menuModel
    @Environment(\.colorScheme) private var colorScheme
//    @AppStorage("appearance") private var appearance: Appearance = .auto
//    @AppStorage("inlineCodeHiglight") private var inlineCodeHiglight: AccentColorOption = .blue
//    @AppStorage("lightCodeBlockTheme") private var lightCodeBlockTheme: String = "xcode"
//    @AppStorage("darkCodeBlockTheme") private var darkCodeBlockTheme: String = "monokai-sublime"
//    @AppStorage("selectedTheme") private var selectedTheme: String = "Default"
//    @AppStorage("localModel") private var selectedLocalModel: String = "None"
    @AppStorage("isLocalGeneration") private var isLocalGeneration: Bool = false
//    
//    // Theme
//    @AppStorage("isAppleClassicUnlocked") var isAppleClassicUnlocked: Bool = false
//    @AppStorage("isChromeDinoUnlocked") var isChromeDinoUnlocked: Bool = false
//    
//    // Audio
//    @AppStorage("selectedAudioModel") private var selectedAudioModel: String = "None"
//    @AppStorage("selectedAudioInput") private var selectedAudioInput: String = "None"
//    @AppStorage("smartDictation") private var smartDictation: Bool = false
//    @AppStorage("useContext") private var useContext: Bool = false
    
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
    
    // STT
    @State private var isTranscribing: Bool = false
    
    // Nav
    @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
    
    // Ripple animation vars
    //    @State var counter: Int = 0
    //    @State var origin: CGPoint = .init(x: 0.5, y: 0.5)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Button(action: {
                        withAnimation {
                            columnVisibility = columnVisibility == .detailOnly ? .automatic : .detailOnly
                        }
                    }) {
                        Image(systemName: "sidebar.left")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(HighlightButtonStyle())
                    .help("Toggle Sidebar")
                    
                    Spacer()
                    
                    Button(action: {
                                   
                    }) {
                        Image(systemName: "pip.enter")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(HighlightButtonStyle())
                    .help("Enter Focus Mode")
                    
                    Button(action: {

                    }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.secondary)
                            .imageScale(.medium)
                    }
                    .buttonStyle(HighlightButtonStyle())
                    .help("New Chat")
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .fontDesign(.rounded)
                .fontWeight(.semibold)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.3))
                
                Divider()
                    .overlay( colorScheme == .dark ? Color.black:.clear)
                
                // Response View
                ConversationView(columnVisibility: $columnVisibility, isLocal: isLocalGeneration)
                //                ResponseView(isResponseVisible: $isResponseVisible, responseSize: $responseSize, isLocal: isLocalGeneration)
                
                
                // ErrorView
                //            if conversationModel.state == .error || modelManager.loadState.isError {
                //                if cardIndex == 0 &&  modelManager.loadState.isError {
                //                    // Local
                //                    if selectedLocalModel != "None" {
                //                        switch modelManager.loadState {
                //                        case .error(let error):
                //                            ScrollView {
                //                                Text(error)
                //                                    .padding(20)
                //                                    .onGeometryChange(for: CGRect.self) { proxy in
                //                                        proxy.frame(in: .global)
                //                                    } action: { newValue in
                //                                        errorSize.width = newValue.width
                //                                        errorSize.height = min(max(newValue.height, 20), 100)
                //                                    }
                //                            }
                //                            .frame(maxWidth: .infinity, alignment: .leading)
                //
                //                            .frame(height: errorSize.height)
                //                            .background(.ultraThickMaterial)
                //                            .overlay {
                //                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                //                                    .stroke(.secondary.opacity(0.5), lineWidth: 1.0)
                //                            }
                //                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                //                        default:
                //                            EmptyView()
                //                        }
                //
                //                    }
                //
                //                }
                //
                //                if cardIndex == 1 && conversationModel.state == .error {
                //                    // Server
                //                    ScrollView {
                //                        Text(conversationModel.error?.description ?? "")
                //                            .padding(20)
                //                            .onGeometryChange(for: CGRect.self) { proxy in
                //                                proxy.frame(in: .global)
                //                            } action: { newValue in
                //                                errorSize.width = newValue.width
                //                                errorSize.height = min(max(newValue.height, 20), 100)
                //                            }
                //                    }
                //                    .frame(maxWidth: .infinity, alignment: .leading)
                //
                //                    .frame(height: errorSize.height)
                //                    .background(.ultraThickMaterial)
                //                    .overlay {
                //                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                //                            .stroke(.secondary.opacity(0.5), lineWidth: 1.0)
                //                    }
                //                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                //                }
                //            }
                
//                if selectedLocalModel != "None" {
//                    CardStack([
//                        AnyView(localInputView.focused($focusedField, equals: .localInput)), // It physically pains me to do type erasure like this
//                        AnyView(serverInputView.focused($focusedField, equals: .serverInput)),
//                    ], selectedIndex: $cardIndex)
//                    
//                } else {
//                    serverInputView.focused($focusedField, equals: .serverInput)
//                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .background(.thickMaterial)
        .overlay(content: {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(.secondary.opacity(0.5), lineWidth: 1.0)
        })
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        //        .modifier(Shake(animatableData: CGFloat(errorAttempts)))
        //        .padding()
        //        .padding(.horizontal, 10) // Allows for shake animation
        
        
//        .onAppear {
//            if isLocalGeneration {
//                cardIndex = 0
//                focusedField = .localInput
//            } else {
//                cardIndex = 1
//                focusedField = .serverInput
//            }
//            conversationModel.getActiveModel()
//            checkAndClearChat()
//        }
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


#Preview("dark") {
    ChatView()
        .frame(width: 300, height: 400)
        .environment(ModelManager())
        .environment(ConversationViewModel())
        .environment(AudioModelManager())
        .environment(MenuViewModel())
    
//        .colorScheme(.dark)
}
