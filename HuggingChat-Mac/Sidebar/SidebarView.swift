//
//  SidebarView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI
import Nuke
import NukeUI

struct SidebarView: View {
    @Environment(CoordinatorModel.self) private var coordinator
    @State private var searchChat: String = ""
    @State private var showingConfirmation = false
    @Binding var showShareSheet: Bool
    @AppStorage(UserDefaultsKeys.baseURL) var baseURL: String = "https://huggingface.co"
    
    var body: some View {
        VStack(spacing: 0) {
            @Bindable var coordinator = coordinator
            List {
                Section {
                    if !coordinator.conversations.isEmpty {
                        ForEach(coordinator.conversations) { conversation in
                            Text(conversation.title.withoutEmoji())
                                .lineLimit(1)
                                .font(.headline)
                                .padding(.leading, 5)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 35)
                                .contentShape(Rectangle())
                                .background {
                                    if
                                        coordinator.selectedConversation == conversation.id {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.quinary)
                                            .ignoresSafeArea(edges: .horizontal)
//                                            .offset(x: -5)
                                    }
                                }
                                .listRowInsets(EdgeInsets(top: 0, leading: -7, bottom: 0, trailing: -7))
                                .tag(conversation.id)
                                .onTapGesture {
                                    if conversation.id != coordinator.selectedConversation {
                                        coordinator.selectedConversation = conversation.id
                                        coordinator.loadConversationHistory()
                                    }
                                    
                                }
                                .contextMenu {
                                    Button {
                                        coordinator.selectedConversation = conversation.id
                                        coordinator.loadConversationHistory()
                                        coordinator.shareConversation()
                                        showShareSheet = true
                                    } label: {
                                        Label("Share Chat", systemImage: "square.and.arrow.up")
                                    }
                                    
                                    Link(destination: URL(string: "\(baseURL)/chat/conversation/" + conversation.serverId)!, label: {
                                        Label("Open in Browser", systemImage: "globe")
                                    })
                                    
                                    Divider()
                                    Button {
                                        coordinator.selectedConversation = conversation.id
                                        coordinator.loadConversationHistory()
                                        showingConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    
                } header: {
                    Text("Chats")
                        .font(.subheadline)
                        .fontWeight(.semibold)
//                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                }
            }
            .listStyle(.sidebar)
            
            
            // Profile Menu
            Menu {
                if let email = coordinator.currentUser?.email, !email.isEmpty {
                    Button {
                    } label: {
                        Text(verbatim: email)
                    }
                    .disabled(true)
                    Divider()
                }
                
                Button {
                    // TODO: Open settings
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                Divider()
                Button {
                    coordinator.logout()
                } label: {
                    Label("Log out", systemImage: "rectangle.portrait.and.arrow.forward")
                }
            } label: {
                HStack {
                    if let avatarURL = coordinator.currentUser?.avatarUrl, let url = URL(string: avatarURL.absoluteString) {
                        LazyImage(url: url) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 28, height: 28)
                                    .clipShape(Circle())
                            } else if state.error != nil {
                                DefaultAvatarView()
                            } else {
                                LoadingAvatarView()
                            }
                        }
                    } else {
                        DefaultAvatarView()
                    }

                    Text(coordinator.currentUser?.username ?? "User")
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.highlightOnPress)
            .frame(height: 60)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .buttonStyle(.plain)
            
        }
        .searchable(text: $searchChat, placement: .sidebar)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    coordinator.resetConversation()
                    
                }, label: {
                    Image(systemName: "square.and.pencil")
                })
            }
        }
        .confirmationDialog("Delete Chat", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let selectedConversation = coordinator.selectedConversation, let conversation = coordinator.conversations.first(where: { $0.id == selectedConversation }) {
                    coordinator.deleteConversation(id: conversation.serverId)
                    coordinator.selectedConversation = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this conversation? This action cannot be undone.")
        }
    }
}

// Extracted views for better organization
private struct DefaultAvatarView: View {
    var body: some View {
        ZStack {
            Circle()
                .foregroundStyle(.quinary)
                .frame(width: 28, height: 28)
            Text("🤗")
        }
    }
}

private struct LoadingAvatarView: View {
    var body: some View {
        ZStack {
            Color.secondary
            ProgressView()
        }
        .frame(width: 28, height: 28)
        .clipShape(Circle())
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
        .environment(CoordinatorModel())
}
