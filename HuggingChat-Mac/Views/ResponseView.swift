//
//  ResponseView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 10/1/24.
//

import SwiftUI
import MarkdownView

struct CustomImageProvider: ImageDisplayable {
    func makeImage(url: URL, alt: String?) -> some View {
        AnimatedImageView(imageURL: url)
    }
}

struct ResponseView: View {
    @Environment(ConversationViewModel.self) private var conversationModel
    @Environment(ModelManager.self) private var modelManager
    
    @AppStorage("inlineCodeHiglight") private var inlineCodeHiglight: AccentColorOption = .blue
    @AppStorage("lightCodeBlockTheme") private var lightCodeBlockTheme: String = "xcode"
    @AppStorage("darkCodeBlockTheme") private var darkCodeBlockTheme: String = "monokai-sublime"
    
    @Binding var isResponseVisible: Bool
    @Binding var responseSize: CGSize
    
    var isLocal: Bool = false
    
    var body: some View {
        if isLocal {
            if !modelManager.outputText.isEmpty {
                if isResponseVisible {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading) {
                                if ThemingEngine.shared.currentTheme.markdownFont == nil {
                                    MarkdownView(text: modelManager.outputText)
                                        .padding(.vertical)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fontGroup(DefaultFontGroup.automatic)
                                        .markdownRenderingThread(.background)
                                        .tint(inlineCodeHiglight.color, for: .inlineCodeBlock)
                                        .codeHighlighterTheme(CodeHighlighterTheme(lightModeThemeName: lightCodeBlockTheme, darkModeThemeName: darkCodeBlockTheme))
                                        .multilineTextAlignment(.leading)
                                        .textSelection(.enabled)
                                        .id(8)
                                } else {
                                    MarkdownView(text: modelManager.outputText)
                                        .padding(.vertical)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .markdownRenderingThread(.background)
                                        .fontGroup(ThemingEngine.shared.currentTheme.markdownFont!)
                                        .tint(inlineCodeHiglight.color, for: .inlineCodeBlock)
                                        .codeHighlighterTheme(CodeHighlighterTheme(lightModeThemeName: lightCodeBlockTheme, darkModeThemeName: darkCodeBlockTheme))
                                        .multilineTextAlignment(.leading)
                                        .textSelection(.enabled)
                                        .id(8)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onGeometryChange(for: CGRect.self) { proxy in
                                proxy.frame(in: .global)
                            } action: { newValue in
                                responseSize.width = newValue.width
                                responseSize.height = min(max(newValue.height, 20), 320)
                            }
                        }
                        .onChange(of: modelManager.outputText, {
                            DispatchQueue.main.async {
                                withAnimation {
                                    proxy.scrollTo(8, anchor: .bottom)
                                }
                            }
                        })
                    }
                    .frame(height: responseSize.height)
                    .contentMargins(.horizontal, 20, for: .scrollContent)
                    .scrollIndicators(.hidden)
                    .background(.ultraThickMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        } else {
            if let message = conversationModel.message,
               !message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               isResponseVisible {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading) {
                                if ThemingEngine.shared.currentTheme.markdownFont == nil {
                                    MarkdownView(text: (conversationModel.imageURL != nil ? "![Generated Image](\(conversationModel.imageURL!))\n\n\n\n": "") + message.content)
                                        .imageProvider(CustomImageProvider(), forURLScheme: "https")
                                        .padding(.vertical)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fontGroup(DefaultFontGroup.automatic)
                                        .markdownRenderingThread(.background)
                                        .tint(inlineCodeHiglight.color, for: .inlineCodeBlock)
                                        .codeHighlighterTheme(CodeHighlighterTheme(lightModeThemeName: lightCodeBlockTheme, darkModeThemeName: darkCodeBlockTheme))
                                        .multilineTextAlignment(.leading)
                                        .textSelection(.enabled)
                                        .id(8)
                                } else {
                                    MarkdownView(text: (conversationModel.imageURL != nil ? "![Generated Image](\(conversationModel.imageURL!))\n\n\n\n": "") + message.content)
                                        .imageProvider(CustomImageProvider(), forURLScheme: "https")
                                        .padding(.vertical)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .markdownRenderingThread(.background)
                                        .fontGroup(ThemingEngine.shared.currentTheme.markdownFont!)
                                        .tint(inlineCodeHiglight.color, for: .inlineCodeBlock)
                                        .codeHighlighterTheme(CodeHighlighterTheme(lightModeThemeName: lightCodeBlockTheme, darkModeThemeName: darkCodeBlockTheme))
                                        .multilineTextAlignment(.leading)
                                        .textSelection(.enabled)
                                        .id(8)
                                }
                                
                                
                                
                                // Sources
                                if let webSearch = conversationModel.message?.webSearch, webSearch.sources.count > 0 && conversationModel.isInteracting == false {
                                    Divider()
                                    Text("Sources")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .padding(.vertical, 5)
                                        
                                    
                                    ScrollView(.horizontal) {
                                        HStack {
                                            ForEach(webSearch.sources) { source in
                                                LinkPreview(link: source)
                                                    .frame(width: 150)
                                            }
                                        }
                                    }
                                    .padding(.bottom)
                                    .scrollIndicators(.hidden)
                                    .scrollClipDisabled()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onGeometryChange(for: CGRect.self) { proxy in
                                proxy.frame(in: .global)
                            } action: { newValue in
                                responseSize.width = newValue.width
                                responseSize.height = min(max(newValue.height, 175), 500)
                            }
                        }
//                        .safeAreaInset(edge: .bottom) {
//                            if let imageURL = conversationModel.imageURL {
//                                ResponseToolBar(imageURL: imageURL)
//                            }
//                        }
                        
                        .onChange(of: conversationModel.message?.content, {
                            DispatchQueue.main.async {
                                withAnimation {
                                    proxy.scrollTo(8, anchor: .bottom)
                                }
                            }
                        })
                    }
                    .frame(height: responseSize.height)
                    .contentMargins(.horizontal, 20, for: .scrollContent)
                    .scrollIndicators(.hidden)
                    .background(.ultraThickMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.secondary.opacity(0.5), lineWidth: 1.0)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
            }
        }
    }
}




