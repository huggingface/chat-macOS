//
//  ModelLoader.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import CoreML
import Models
import Path

@Observable class ModelLoader {
    static let models = Path.documents / "hf-compiled-transformers"
    static let lastCompiledModel = models / "last-model.mlmodelc"
        
    static func load(url: URL?) async throws -> LanguageModel {
        
        func clearModels() throws {
            try models.delete()
            try ModelLoader.models.mkdir(.p)
        }
        // url: Optional(file:///Users/cyril/Library/Containers/cyrilzakka.HuggingChat-Mac/Data/Documents/StatefulMistral7BInstructInt4.mlpackage/)
        if let url = url {
            let compiledPath = models / url.deletingPathExtension().appendingPathExtension("mlmodelc").lastPathComponent
            if url.pathExtension == "mlmodelc" {
                // _copy_ to the models folder
                try clearModels()
                try Path(url: url)?.copy(to: compiledPath, overwrite: true)
            } else {
                // Compile and _move_
                print("Compiling model \(url)")
                let compiledURL = try await MLModel.compileModel(at: url)
                try clearModels()
                try Path(url: compiledURL)?.move(to: compiledPath, overwrite: true)
            }

            // Create symlink (alternative: store name in UserDefaults)
            try compiledPath.symlink(as: lastCompiledModel)
        }
        
        // Load last model used (or the one we just compiled)
        let lastURL = try lastCompiledModel.readlink().url
        return try LanguageModel.loadCompiled(url: lastURL, computeUnits: .cpuAndGPU)
    }
}
