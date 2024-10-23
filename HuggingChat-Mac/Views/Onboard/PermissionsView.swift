//
//  PermissionsView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/18/24.
//

import SwiftUI
import AVFAudio

struct PermissionsView: View {
    @State private var microphoneAccessGranted = false
    @State private var accessibilityFeaturesGranted = false
    
    var body: some View {
        ZStack {
            Color.white
            LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.4), Color.yellow.opacity(0.1), Color.yellow.opacity(0)]), startPoint: UnitPoint(x: 0.5, y: 0), endPoint: UnitPoint(x: 0.5, y: 1))
            VStack {
                HStack {
//                    Image("huggy.fill")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .symbolRenderingMode(.multicolor)
//                        .background(Circle().fill(.black).frame(width: 20))
//                        .frame(width: 32, height: 32)
                    Text("Permissions")
                        .font(.largeTitle)
                        .fontDesign(.rounded)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                .padding(.top, 50)
                
                Text("To unlock all Hugging Chat features, you will need to grant the app some necessary permissions.")
                    .font(.callout)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                Spacer()
                ScrollView {
                    PermissionCell(icon: "microphone.circle.fill", title: "Microphone Access", subtitle: "Access to your microphone is needed for transcription and voice-mode purposes.", isGranted: $microphoneAccessGranted) {
                        Task {
                            await requestMicrophoneAccess()
                        }
                    }
                    PermissionCell(icon: "accessibility.fill", title: "Accessibility Features", subtitle: "Accessibility features are needed for enhanced user interaction and support.", isGranted: $accessibilityFeaturesGranted) {
                        requestAccessibilityFeatures()
                    }
                }
                
                Button(action: {
                    if microphoneAccessGranted && accessibilityFeaturesGranted {
                        // TODO: Go to success view
                    }
                }, label: {
                    Text("All Set!")
                        .fontWeight(.medium)
                })
                .controlSize(.regular)
                .buttonStyle(.plain)
                .frame(height: 45)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .background(RoundedRectangle(cornerRadius: 8).fill(microphoneAccessGranted && accessibilityFeaturesGranted ? .black : .gray))
                .disabled(!microphoneAccessGranted || !accessibilityFeaturesGranted)
                .padding(.vertical)
            }
            .padding()
        }
        .ignoresSafeArea(.container, edges: .top)
    }
    
    private func requestMicrophoneAccess() async {
            let granted = await AVAudioApplication.requestRecordPermission()
            DispatchQueue.main.async {
                self.microphoneAccessGranted = granted
                if !granted {
                    // TODO: Go to system settings
                }
            }
        }
    
    private func requestAccessibilityFeatures() {
        // Implement accessibility features permission request
        // This is a placeholder and should be replaced with actual implementation
        
            self.accessibilityFeaturesGranted = true
        
    }
}

struct PermissionCell: View {
    var icon: String
    var title: String
    var subtitle: String
    @Binding var isGranted: Bool
    var action: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .symbolRenderingMode(.multicolor)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.black)
                Text(subtitle)
                    .foregroundStyle(.black.opacity(0.7))
                    .font(.subheadline)
            }
            
            Spacer()
            
            Toggle("", isOn: $isGranted)
                .toggleStyle(.switch)
                .onChange(of: isGranted) {
                    action()
                }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    PermissionsView()
        .frame(width: 300, height: 400)
}
