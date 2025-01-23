//
//  LoginView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct LoginView: View {
    
    @Environment(CoordinatorModel.self) private var coordinator
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    var body: some View {
        ZStack {
            Color.white
            LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.4), Color.yellow.opacity(0.1), Color.yellow.opacity(0)]), startPoint: UnitPoint(x: 0.5, y: 0), endPoint: UnitPoint(x: 0.5, y: 1))
            VStack {
                HStack {
                    Text("HuggingChat")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                    Image("huggy.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(.primary)
                        .background(Circle().fill(.black).frame(width: 20))
                        .frame(width: 32, height: 32)
                }
                .frame(maxHeight: .infinity, alignment: .center)
                
                
                Group {
                    Button(action: {
                        openURL(URL(string: "https://huggingface.co/join")!)
                    }, label: {
                        Text("Sign up")
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 8).fill(.clear))
                    })
                    .frame(height: 35)
                    .background(RoundedRectangle(cornerRadius: 8).fill(.black))
                    
                    .buttonStyle(.highlightOnPress(defaultBackground: .black))
                    
                    Button(action: {
                        coordinator.signin()
                    }, label: {
                        Text("Log in")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 8).fill(.clear))
                    })
                    .buttonStyle(.highlightOnPress)
                    .foregroundStyle(.black)
//                    .padding(.bottom)
                    
                    Text("AI models can make mistakes. Please double-check responses.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .padding(.horizontal, 30)
                
            }
        }
        
    }
}

#Preview {
    LoginView()
        .frame(width: 300, height: 400)
        .environment(CoordinatorModel())
}
