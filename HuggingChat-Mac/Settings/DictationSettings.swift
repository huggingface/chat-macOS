//
//  DictationSettings.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/9/24.
//

import SwiftUI
import WhisperKit
import KeyboardShortcuts

struct DictationSettings: View {
    
    @Environment(AudioModelManager.self) private var audioModelManager
    @AppStorage("selectedAudioModel") private var selectedModel: String = "None"
    @AppStorage("selectedAudioInput") private var selectedAudioInput: String = "None"
    @AppStorage("streamTranscript") private var streamTranscript: Bool = false
    
    var body: some View {
        Form {
            Section(content: {
                LabeledContent("CoreML Model:", content: {
                    HStack {
                        Picker("", selection: $selectedModel) {
                            Text("None")
                                .tag("None")
                            ForEach(audioModelManager.localModels, id: \.self) { model in
                                Text(" \(model.description.components(separatedBy: "_").dropFirst().joined(separator: " "))").tag(model.description)
                            }
                            .onChange(of: selectedModel, initial: false) { _, _ in
                                if selectedModel != "None" {
                                    audioModelManager.loadModel(selectedModel)
                                } else {
                                    audioModelManager.modelState = .unloaded
                                }
                                
                            }
                        }
                        StatusIndicatorView(audioState: audioModelManager.modelState)
                    }
                    .labelsHidden()
                })
                
                LabeledContent("Microphone:", content: {
                    HStack {
                        Picker("", selection: $selectedAudioInput) {
                            Text("None")
                                .tag("None")
                            if let audioDevices = audioModelManager.audioDevices {
                                ForEach(audioDevices, id: \.self) { device in
                                    Text(device.name)
                                        .tag(device.name)
                                }
                            }
                        }
                    }
                    .labelsHidden()
                })
                
            }, header: {
                Text("Dictation Model")
            }, footer: {
                Text("Transcription will run on your local device, privately and securely.")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .foregroundColor(.secondary)
            })
            
            Section(content: {
                KeyboardShortcuts.Recorder("Keyboard Shortcut:", name: .showTranscriptionPanel)
                Toggle("Stream Transcription (Beta):", isOn: $streamTranscript)
            }, header: {
                Text("Miscellaneous")
            }, footer: {
                Text(streamTranscript ? "Transcribed text will appear in the focused text field as you speak. Limited compatibility with non-native or web-based applications.":"Transcribed text will be copied to the your clipboard at the end of your recording.")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .foregroundColor(.secondary)
            })
        }
        .formStyle(.grouped)
        .onAppear {
            audioModelManager.fetchModels()
            audioModelManager.audioDevices = AudioProcessor.getAudioDevices()
         }
    }
    
    
}

#Preview {
    DictationSettings()
        .environment(AudioModelManager())
}
