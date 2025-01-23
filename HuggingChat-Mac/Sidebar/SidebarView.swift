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
    
    var body: some View {
        VStack {
            List {
                Section("Chats") {
                    LazyHStack {
                        // Your chat content here
                    }
                }
            }
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
                Button(action: {}, label: {
                    Image(systemName: "square.and.pencil")
                })
            }
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
