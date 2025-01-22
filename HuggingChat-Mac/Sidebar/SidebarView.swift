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
                Section("Chats", content: {
                    LazyHStack {
                        
                    }
                })
                
            }
            
            // Profile Pic
            Menu {
                if let email = coordinator.currentUser?.email, email != "" {
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
                    Label("Settings", systemImage: "folder.badge.plus")
                }
                Divider()
                Button {
                    coordinator.logout()
                } label: {
                    Label("Log out", systemImage: "rectangle.stack.badge.person.crop")
                }
            } label: {
                HStack {
                    if let avatarURL = coordinator.currentUser?.avatarUrl {
                        LazyImage(url: URL(string: avatarURL.absoluteString)) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 28, height: 28)
                                    .clipShape(Circle())
                            } else if state.error != nil {
                                ZStack {
                                    Color.secondary
                                }
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                            } else {
                                ZStack {
                                    Color.secondary
                                    ProgressView()
                                }
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                            }
                        }
                            
                                                    
                    } else {
                        ZStack {
                            Circle()
                                .foregroundStyle(.quinary)
                                .frame(width: 28, height: 28)
                            Text("🤗")
                        }
                    }
//                    LazyImage(url: URL(string: thumbnail)) { state in
//
//                    }

                    Text(coordinator.currentUser?.username ?? "Cyril Zakka")
                        
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
    
    
    // MARK: Helper functions
    
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
        .environment(CoordinatorModel())
}


