//
//  SuccessView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/25/24.
//

import SwiftUI

struct SuccessView: View {

    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(CoordinatorModel.self) private var coordinator
    @State private var activateConfetti = false
    @AppStorage("onboardingDone") private var onboardingDone: Bool = false
    
    var body: some View {
        ZStack {
            Color.white
            LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.4), Color.yellow.opacity(0.1), Color.yellow.opacity(0)]), startPoint: UnitPoint(x: 0.5, y: 0), endPoint: UnitPoint(x: 0.5, y: 1))
            VStack {
                HStack {
                    Image("huggy.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .symbolRenderingMode(.multicolor)
                        .background(Circle().fill(.black).frame(width: 20))
                        .frame(width: 32, height: 32)
                    Text("Hurray!")
                        .font(.largeTitle)
                        .fontDesign(.rounded)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                .padding(.top, 50)
                
                Text("You're only 3 taps away from using some of the most powerful open source AI models in the world.")
                    .font(.callout)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Spacer()
                Image("keys")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(2)
                Spacer()
                Button(action: {
                    onboardingDone = true
                    dismissWindow()
                }, label: {
                    Text("Awesome!")
                        .fontWeight(.medium)
                })
                .controlSize(.small)
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .frame(height: 30)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 8).fill(.black))
                .padding(.top, 50)
                
                
                Text("You can change the keyboard shortcut in the settings section of the app")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
            }
            .padding()
            if activateConfetti {
                ConfettiView(emissionDuration: 2)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .onAppear {
            activateConfetti = true
        }
    }
    
    private func generateURL(from location: String, appleToken: String? = nil) -> URL? {
        var s_url = location
        if appleToken != nil {
            s_url = location.replacingOccurrences(of: "/oauth/authorize", with: "/login/apple")
        }
        guard var component = URLComponents(string: s_url) else { return nil }
        var queryItems = component.queryItems ?? []
        queryItems.append(URLQueryItem(name: "prompt", value: "login"))
        if let appleToken = appleToken {
            queryItems.append(URLQueryItem(name: "id_token", value: appleToken))
        }
        component.queryItems = queryItems

        return component.url
    }
}

#Preview {
    SuccessView()
        .frame(width: 300, height: 400)
        .environment(CoordinatorModel())
}
