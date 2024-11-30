//
//  ResponseToolBar.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 11/29/24.
//

import SwiftUI
import Pow

struct AnimatedImageView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    let imageURL: URL
    
    var body: some View {
        HStack {
            Button(action: { }, label: {
                AsyncImage(
                    url: imageURL,
                  transaction: .init(animation: .easeInOut(duration: 1.8))
                ) { phase in
                  ZStack {
                      if colorScheme == .dark {
                          Color.black
                              .frame(width: 120, height: 120)
                      } else {
                          Color.clear
                              .frame(width: 120, height: 120)
                      }
                    switch phase {
                    case .success(let image):
                      image
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .zIndex(1)
                        .transition(colorScheme == .dark ? .movingParts.filmExposure:.movingParts.snapshot)
                        
                    case .failure(_):
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .imageScale(.large)
                                .symbolVariant(.slash)
                            Text("There was an error loading the image")
                                .font(.caption2)
                                
                        }.transition(.opacity)
                    case .empty:
                      EmptyView()
                    @unknown default:
                      EmptyView()
                    }
                  }
                  .aspectRatio(contentMode: .fit)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            })
            .buttonStyle(.borderless)
        }
    }
}

//#Preview {
//    AnimatedImageView(imageURL: "https://huggingface.co/chat/conversation/674aa4c3ffeac63b3bf1e85a/output/6f5d500641f3c234313f43447fe85445e0430a05aba3ae9d5e1e57570029c1b4")
//}
