//
//  DataService.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import Combine
import Foundation

final class ActiveModel: Codable {
    var id: String
    
    init(model: LLMModel) {
        self.id = model.id
    }
}

final class DataService {
    static let shared: DataService = DataService()

    private var conversations: [Conversation]?
    private(set) var activeModel: ActiveModel?
    private var cancellables = [AnyCancellable]()

    init() {
        getModels(shouldForceRefresh: true).sink(
            receiveCompletion: { _ in }, receiveValue: { _ in }
        ).store(in: &cancellables)
        
        self.activeModel = DataService.getLocalActiveModel()
    }

    func setActiveModel(_ activeModel: ActiveModel) {
        self.activeModel = activeModel
        DataService.saveActiveModel(activeModel)
    }
    
    func saveModels(models: [LLMModel]) {
        DataService.saveModels(models)
    }

    func getModel(id: String) -> AnyPublisher<LLMModel, HFError> {
        return getModels().tryMap({ models in
            if let model = models.first(where: { $0.id == id }) {
                return model
            } else {
                throw HFError.modelNotFound
            }
        })
        .mapError({ error in
            guard let error = error as? HFError else {
                return HFError.unknown
            }
            return error
        })
        .eraseToAnyPublisher()
    }

    func getModels(shouldForceRefresh: Bool = false) -> AnyPublisher<[LLMModel], HFError> {
        if let models = DataService.getLocalModels(), !shouldForceRefresh {
            return Just(models).setFailureType(to: HFError.self).eraseToAnyPublisher()
        }

        return NetworkService.getModels().handleEvents(receiveOutput: { models in
            let localModels = DataService.getLocalModels()
            if let locals = localModels {
                for model in models {
                    guard let local = locals.first(where: { $0.id == model.id }) else { continue }
                    model.preprompt = local.preprompt
                }
            }

            DataService.saveModels(models)
        }).eraseToAnyPublisher()
    }
    
    func getActiveModel() -> AnyPublisher<AnyObject, HFError> {
        guard let activeModel = activeModel else {
            return getModels(shouldForceRefresh: false).tryMap { models in
                guard let model = models.first else {
                    throw HFError.unknown
                }
                return model
            }.mapError({ error in
                if let error = error as? HFError {
                    return error
                } else {
                    return HFError.unknown
                }
            }).eraseToAnyPublisher()
        }
        
        if let model = DataService.getLocalModels()?.first(where: {$0.id == activeModel.id}) {
            return Just(model).setFailureType(to: HFError.self).eraseToAnyPublisher()
        } else {
            return Fail(outputType: AnyObject.self, failure: HFError.unknown).eraseToAnyPublisher()
        }
    }

    private static func getLocalModels() -> [LLMModel]? {
        guard let data = UserDefaults.standard.data(forKey: "models") else {
            return nil
        }
        do {
            let decoder = JSONDecoder()
            let models = try decoder.decode([LLMModel].self, from: data)
            return models
        } catch {
            print("Unable to Decode [LLModel] (\(error))")
            return nil
        }
    }

    static func saveModels(_ models: [LLMModel]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(models)
            UserDefaults.standard.set(data, forKey: "models")
        } catch {
            print("Unable to Encode [LLModel] (\(error))")
        }
    }
    
    static func saveActiveModel(_ activeModel: ActiveModel) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(activeModel)
            UserDefaults.standard.set(data, forKey: "active_model")
        } catch {
            print("Unable to Encode Active Model (\(error))")
        }
    }
    
    private static func getLocalActiveModel() -> ActiveModel? {
        guard let data = UserDefaults.standard.data(forKey: "active_model") else {
            return nil
        }
        do {
            let decoder = JSONDecoder()
            let activeModel = try decoder.decode(ActiveModel.self, from: data)
            return activeModel
        } catch {
            print("Unable to Decode Active Model (\(error))")
            return nil
        }
    }

    func resetLocalModels() {
        UserDefaults.standard.setValue(nil, forKey: "models")
        UserDefaults.standard.set(nil, forKey: "active_model")
        activeModel = nil
    }
}
