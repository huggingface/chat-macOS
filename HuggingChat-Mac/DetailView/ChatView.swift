//
//  ChatView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct ChatView: View {
    
    var isPipMode: Bool = false
    var isPreviewMode: Bool = false
    var onPipToggle: () -> Void
    
    @EnvironmentObject private var appDelegate: AppDelegate
    @Environment(CoordinatorModel.self) private var coordinator
    @Environment(\.colorScheme) var colorScheme
    
    // Toolbar
    @State private var showingPopover: Bool = false
    @State private var showPipToolbar: Bool = false
    @Binding var showShareSheet: Bool
    
    // Scrollview animation
    @State var scrollViewHeight: CGFloat = 0
    @State var anchorToBottom: Bool = false
    @State var showScrollToBottom: Bool = false
    @State var contentHeight : CGFloat = 0
    @State var size: CGSize = .zero
    
    private var backgroundMaterial: some View {
        ZStack {
            if isPipMode {
                Rectangle.semiOpaqueWindow(withStyle: .toolTip)
                Rectangle().fill(.regularMaterial)
            } else {
                Rectangle.semiOpaqueWindow()
                Rectangle().fill(.regularMaterial)
            }
            
        }
    }
    
    var body: some View {
        
        ZStack {
            ChatBackgroundView(isPipMode: isPipMode)
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    if isPipMode {
                        if showPipToolbar {
                            PiPToolbarView(
                                onPipToggle: onPipToggle,
                                onNewConversation: { /* Handle new conversation */ }
                            )
                            
                        } else {
                            Rectangle()
                                .fill(.clear)
                                .frame(height: 40).zIndex(100)
                            
                        }
                    }
                    
                    Group {
                        if let _ = coordinator.selectedConversation {
                            ChatMessageListView(
                                parentWidth: size.width,
                                contentHeight: size.height,
                                isPipMode: isPipMode,
                                showPipToolbar: showPipToolbar,
                                showScrollToBottom: $showScrollToBottom
                            )
                            .onChange(of: coordinator.messages.count) { oldValue, newValue in
                                guard oldValue == 0 else { return }
                                guard newValue > 0 else { return }
                                proxy.scrollTo(coordinator.messages[coordinator.messages.count - 1].id, anchor: .bottom)
                            }
//                            .onAppear {
//                                print("view appeared")
//                                DispatchQueue.main.async {
//                                    guard coordinator.messages.count > 0 else {
//                                        return
//                                    }
//                                    print("view appeared again")
//                                    withAnimation(.easeOut) {
//                                        proxy.scrollTo(coordinator.messages[coordinator.messages.count - 1].id, anchor: .bottom)
//                                    }
//                                }
//                            }
                            
                        } else {
                            ChatEmptyStateView()
                        }
                    }
                    .overlay {
                        if !isPreviewMode {
                            VStack {
                                Spacer()
                                ChatBackgroundView(isPipMode: isPipMode)
                                    .frame(height: 50, alignment: .bottom)
                                    .mask(LinearGradient(gradient: Gradient(stops: [
                                        .init(color: .black, location: 0),
                                        .init(color: .black, location: 0.01),
                                        .init(color: .clear, location: 1)
                                    ]), startPoint: .bottom, endPoint: .top))
                            }
                            .allowsHitTesting(false)
                        }
                    }
                    
                    if !isPreviewMode {
                        InputView() {
                            DispatchQueue.main.async {
                                withAnimation(.easeOut) {
                                    proxy.scrollTo(coordinator.messages[coordinator.messages.count - 1].id, anchor: .bottom)
                                }
                            }
                        }
                        .padding([.horizontal, .bottom])
                        .overlay(alignment: .top) {
                            if showScrollToBottom {
                                ScrollToBottomButton {
                                    DispatchQueue.main.async {
                                        withAnimation(.easeOut) {
                                            proxy.scrollTo(coordinator.messages[coordinator.messages.count - 1].id, anchor: .bottom)
                                        }
                                    }
                                        
                                    
                                }
                            }
                        }
                }
                        
                }
            }
        }
        .onGeometryChange(for: CGSize.self) { geometry in
            return geometry.size
        } action: { newValue in
            size = newValue
        }
        .onChange(of: size) { oldValue, newValue in
            size = newValue
        }
        .overlay(content: {
            if isPipMode {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.gray.opacity(0.5), lineWidth: 1.0)
            }
        })
        .clipShape(RoundedRectangle(cornerRadius: isPipMode ? 22:0, style: .continuous))
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {
                    showingPopover = true
                }, label: {
                    titleView()
                })
                .buttonStyle(.accessoryBar)
                .popover(isPresented: $showingPopover, arrowEdge: .bottom) {
                    ModelListView()
                        .frame(width: 320)
                        .frame(maxHeight: 400)
                }
                
            }
            
            ToolbarItemGroup(placement: .confirmationAction) {
                Spacer()
                Button(action: {
                    if coordinator.selectedConversation != nil {
                        coordinator.shareConversation()
                    }
//                    coordinator.showShareSheet = true
                    showShareSheet.toggle()
                }, label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                })
                .disabled(coordinator.selectedConversation == nil)
                Button(action: {
                    onPipToggle()
                }, label: {
                    Label("Picture in Picture", systemImage: "pip")
                })
            }
        }
        .onHover { over in
            showPipToolbar = over
        }
    }
    
    @ViewBuilder
    func titleView() -> some View {
        HStack(alignment: .bottom, spacing: 5) {
            let modelName = coordinator.activeModel?.displayName.split(separator: "/").last ?? ""
            let companyName = coordinator.activeModel?.displayName.split(separator: "/").first ?? ""
//            let primaryName = modelName.split(separator: "-").first ?? ""
//            let secondaryName = modelName.components(separatedBy: primaryName).last?.trimmingCharacters(in: .whitespaces) ?? ""
            Text(companyName)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .fontWeight(.medium)
                .font(.title3)
                .contentTransition(.numericText())
            Text(modelName)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
                .font(.body)
                .contentTransition(.numericText())
            Image(systemName: "chevron.right")
                .imageScale(.small)
        }
       
        .frame(maxWidth: .infinity, alignment: .leading)
        .layoutPriority(100)
    }
}

// MARK: Subviews
// 1. Background Material View
struct ChatBackgroundView: View {
    let isPipMode: Bool
    
    var body: some View {
        ZStack {
            if isPipMode {
                Rectangle.semiOpaqueWindow(withStyle: .toolTip)
                Rectangle().fill(.regularMaterial)
            } else {
                Rectangle.semiOpaqueWindow()
                Rectangle().fill(.regularMaterial)
            }
        }
    }
}

// 2. PiP Toolbar View
struct PiPToolbarView: View {
    
    @Environment(CoordinatorModel.self) private var coordinator
    let onPipToggle: () -> Void
    let onNewConversation: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onPipToggle) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            
            Spacer()
            
//            Button(action: {  }) {
//                Image(systemName: "pip.exit")
//            }
//            .buttonStyle(.accessoryBar)
            
            Button(action: onNewConversation) {
                Image(systemName: "square.and.pencil")
            }
            .buttonStyle(.accessoryBar)
        }
        .frame(height: 40)
        .foregroundStyle(.primary)
        .padding(.horizontal)
    }
}

// 3. Message List View
struct ChatMessageListView: View {
    @Environment(CoordinatorModel.self) private var coordinator
    let parentWidth: CGFloat
    let contentHeight: CGFloat
    let isPipMode: Bool
    let showPipToolbar: Bool
    @Binding var showScrollToBottom: Bool
    
    var body: some View {
        if #available(macOS 15.0, *) {
            ScrollView {
                LazyVStack {
                    ForEach(coordinator.messages) { message in
                        MessageView(message: message, parentWidth: parentWidth)
                            .id(message.id)
                            .listRowSeparator(.hidden)
                            .padding(.bottom)
                            .padding(.horizontal)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .scrollClipDisabled(isPipMode && !showPipToolbar)
            
           
            .onScrollGeometryChange(for: Bool.self) { geometry in
                return geometry.contentOffset.y + geometry.bounds.height >=
                geometry.contentSize.height - 100 // Added padding
            } action: { wasGreater, isGreater in
                showScrollToBottom = !isGreater
            }
            .contentMargins(.bottom, 50, for: .scrollContent)
            .contentMargins(.bottom, 50, for: .scrollIndicators)
        } else {
            List {
                // Fallback for older versions
            }
        }
    }
}

// 4. Scroll To Bottom Button
struct ScrollToBottomButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.down")
                .fontWeight(.medium)
                .imageScale(.small)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .padding(5)
                .background {
                    Circle()
                        .fill(colorScheme == .dark ? Color(.windowBackgroundColor) : .white)
                        .frame(width: 30, height: 30)
                        .shadow(radius: 2)
                }
        }
        .frame(width: 30, height: 30)
        .offset(y: -40)
        .buttonStyle(.plain)
        .transition(.scale(0.8, anchor: .bottom).combined(with: .opacity))
    }
}

// 5. Empty State View
struct ChatEmptyStateView: View {
    var body: some View {
        ZStack {
            Image("huggy")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .symbolRenderingMode(.none)
                .foregroundStyle(.tertiary)
                .frame(width: 55, height: 55)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

struct ModelListView: View {
    @State var hoverState: Bool = false
    @State var toggleExpansion: Bool = false
    
    let modelMapping: [String: String] = [
        "CohereForAI/c4ai-command-r-plus-08-2024":"Best model for tool use",
        "deepseek-ai/DeepSeek-R1-Distill-Qwen-32B":"Uses advanced reasoning",
        "microsoft/Phi-3.5-mini-instruct":"Faster for most questions",
        "Qwen/QwQ-32B-Preview":"Great for most tasks"
    ]
    
    var body: some View {
        if let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.models),
           let models = try? JSONDecoder().decode([LLMModel].self, from: data) {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(models, id: \.id) { model in
                        if let customDescription = modelMapping[model.name] {
                            ModelCellView(model: model, description: customDescription)
                        }
                    }
                    
                    VStack {
                        HStack {
                            Text("More models")
                                .id("more-models-id")
                                
                            
                            Spacer()
                            Image(systemName: "chevron.right")
                                .rotationEffect(toggleExpansion ? .degrees(90):.zero, anchor: .center)
                            
                        }
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 7)
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            withAnimation(.snappy) {
                                toggleExpansion.toggle()
                            } completion: {
                                DispatchQueue.main.async {
                                    withAnimation(.snappy) {
                                        proxy.scrollTo("more-models-id", anchor: toggleExpansion ? .top:.bottom)
                                    }
                                }
                            }
                        }
                        .background {
                            if hoverState {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.quinary)
                            }
                        }
                        .onHover { isHovering in
                            hoverState = isHovering
                        }
                        
                        if toggleExpansion {
                            ForEach(models.filter { !modelMapping.keys.contains($0.name) }, id: \.id) { model in
                                ModelCellView(
                                    model: model,
                                    description: model.description
                                )
                            }
                        }
                            
                    }
                }
                .scrollIndicators(.hidden)
                .padding(10)
            }
        }
    }
}

struct ModelCellView: View {
    @Environment(CoordinatorModel.self) private var coordinator
    @Environment(\.dismiss) var dismiss
    
    var model: LLMModel
    var description: String
    @State var hoverState: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(model.displayName)
                Text(description)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if coordinator.activeModel?.id == model.id {
                Image(systemName: "checkmark")
            }
           
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 5)
        .padding(.horizontal, 7)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .background {
            if hoverState {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quinary)
            }
        }
        .onTapGesture {
            withAnimation {
                coordinator.setActiveModel(LLMViewModel(model: model))
            }
            dismiss()
            // TODO: Reset stuff?
        }
        .onHover { isHovering in
            hoverState = isHovering
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(AppDelegate())
        .environment(CoordinatorModel())
}

//#Preview {
//    ChatView(
//        isPipMode: true,
//        onPipToggle: { }
//    )
//        .frame(width: 300, height: 500)
//        .environment(CoordinatorModel())
//}
