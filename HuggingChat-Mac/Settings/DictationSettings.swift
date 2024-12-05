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
    @AppStorage("smartDictation") private var smartDictation: Bool = false
    @AppStorage("useLocalCleanup") private var useLocalCleanup: Bool = false
    
    var body: some View {
        Form {
            Section(content: {
                LabeledContent("Model Name:", content: {
                    HStack {
                        Picker("", selection: $selectedModel) {
                            Text("None")
                                .tag("None")
                            ForEach(audioModelManager.availableLocalModels.filter { $0.downloadState == .downloaded }) { model in
                                Text(model.id).tag(model.id)
                            }
                            .onChange(of: selectedModel, initial: false) { _, _ in
                                if selectedModel != "None" {
                                    audioModelManager.loadModel(selectedModel)
                                } else {
                                    audioModelManager.whisperKit = nil
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
                                .onChange(of: selectedAudioInput) { _, _ in
                                    if selectedAudioInput != "None" {
                                        audioModelManager.selectedAudioInput = selectedAudioInput
                                    }
                                    
                                }
                            }
                        }
                    }
                    .labelsHidden()
                })
                
            }, header: {
                Text("Dictation Model")
            }, footer: {
                Text("Transcription will run on your local device, privately and securely. The first time you use it, it may take a few minutes to load the model.")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .foregroundColor(.secondary)
            })
            
            Section(content: {
                KeyboardShortcuts.Recorder("Global Transcription Shortcut:", name: .showTranscriptionPanel)
//                Toggle("Smart Dictation", isOn: $smartDictation)
//                if smartDictation {
//                       Toggle("Local Model Only", isOn: $useLocalCleanup)
//                   }
            }, header: {
                Text("Miscellaneous")
            }, footer: {
//                Text(smartDictation ?
//                    useLocalCleanup ? "Uses a local AI model to clean and format transcripts using contextual information, for maximum privacy at the cost of accuracy and speed." : "Uses a server-based AI model along with contextual information to clean and format transcripts. Your data is never used for training."
//                    : "Raw transcripts are inserted directly without formatting.")
//                    .font(.footnote)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .multilineTextAlignment(.leading)
//                    .lineLimit(nil)
//                    .foregroundColor(.secondary)
            })
        }
        .formStyle(.grouped)
        .onAppear {
            audioModelManager.fetchModels()
            audioModelManager.setupMicrophone()
         }
    }
}

#Preview {
    DictationSettings()
        .environment(AudioModelManager())
}
