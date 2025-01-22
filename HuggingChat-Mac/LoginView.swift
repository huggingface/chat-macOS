//
//  LoginView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct LoginView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            HStack {
                Text("HuggingChat")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Image("huggy.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            
            
            Group {
                Button(action: {
                    
                }, label: {
                    Text("Sign up")
                        .fontWeight(.medium)
                        .foregroundStyle(colorScheme == .dark ? .black:.white)
                })
                .frame(height: 45)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 8).fill(.primary))
                
                .buttonStyle(.plain)
                
                Button(action: {
                    
                }, label: {
                    Text("Log in")
                        .fontWeight(.medium)
                })
                .background(RoundedRectangle(cornerRadius: 8).fill(.clear))
                .frame(height: 45)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.primary)
                .buttonStyle(.simpleHighlight)
                .padding(.bottom)
            }
            .padding(.horizontal, 40)
            
        }
        
        
    }
}

#Preview {
    LoginView()
        .frame(width: 300, height: 400)
}
