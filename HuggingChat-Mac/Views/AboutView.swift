//
//  AboutView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/17/24.
//

import SwiftUI
import Pow
import SwiftPackageList

struct AboutView: View {
    
    @AppStorage("isPixelPalsUnlocked") var isPixelPalsUnlocked: Bool = false
    @AppStorage("numberOfTimesInteracted") var numberOfTimesInteracted: Int = 0
    @State var isLiked = false
    
    private func addInteraction() {
        numberOfTimesInteracted += 1
        if numberOfTimesInteracted > 20 {
            isPixelPalsUnlocked = true
        }
    }
    
    var body: some View {
        HStack(alignment: .center) {
            ZStack {
//                RoundedRectangle(cornerRadius: 25)
//                    .fill(.white.gradient)
//                    .frame(width: 100, height: 100)
                ZStack {
                    Image("huggy.bp")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(.yellow.gradient)
                        .background(Circle().fill(.black).frame(height: 35))
                        .frame(width: 120, height: 120)
                    Circle()
                        .fill(.clear)
                        .frame(width: 120, height: 120)
                        .changeEffect(
                            .spray(origin: .center) {
                                Image(systemName: numberOfTimesInteracted == 20 ? "star.fill" :"heart.fill")
                                    .foregroundStyle(numberOfTimesInteracted == 20 ? .yellow:.red)
                              .zIndex(100)
                          }, value: isLiked)
                }
                .onTapGesture { location in
                    withAnimation(.movingParts.overshoot(duration: 0.4)) {
                        isLiked.toggle()
                    }
                    addInteraction()
                }
                    
            }
            .padding(.horizontal)
            VStack(alignment: .leading) {
                Text("HuggingChat")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text("Version: \(Bundle.main.appVersionLong) (\(Bundle.main.appBuild)) ")
                    .font(.subheadline)
                Text(Bundle.main.copyright)
                    .lineLimit(nil)
//                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.vertical, 5)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Button("Acknowledgements", action: {
                        let url = Bundle.main.acknowledgementsURL
                        if let url {
                            NSWorkspace.shared.open(url)
                        }
                    })
                    Button("Privacy Policy", action: {
                        NSWorkspace.shared.open(URL(string: "https://huggingface.co/privacy")!)
                    })
                }
                
                
                    
            }
        }
        .padding()
    }
}

#Preview {
    AboutView()
        .frame(width: 450, height: 175)
}
