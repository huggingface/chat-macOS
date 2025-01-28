//
//  CoordinatorModel.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/22/25.
//


import SwiftUI
import Combine

@Observable class CoordinatorModel {
    
    // Conversations
    var conversations: [Conversation] = []
    var messages: [MessageViewModel] = []
    var selectedConversation: Conversation.ID?
    var sharedConversationLink: URL?
    
    // Model
    var activeModel: LLMViewModel?
    var useWebSearch: Bool = false
    var isInteractingWithModel: Bool = false
    
    // Auth
    var currentUser: HuggingChatUser?
    var token: String?
    var hfChatToken: String? {
        guard let token = HTTPCookieStorage.shared.cookies?.first(where: { $0.name == "hf-chat" })?.value else {
            return nil
        }
        return token
    }
    
    // Misc
    var error: HFError?
    private var cancellables = Set<AnyCancellable>()
    private var sendPromptHandler: SendPromptHandler?
    
    init() {
        let cookies = HTTPCookieStorage.shared.cookies!
        for cookie in cookies {
            print("\(cookie.name): \(cookie.value)")
        }
        self.refreshLoginState()
        
        // Fetch models
        getModels(shouldForceRefresh: true).sink(
            receiveCompletion: { _ in }, receiveValue: { _ in }
        ).store(in: &cancellables)
        
        self.activeModel = self.getLocalActiveModel()
    }
}

// MARK: Login functions
extension CoordinatorModel {
    func signin() {
        NetworkService.loginChat()
            .receive(on: DispatchQueue.main)
            .sink { completion in
            switch completion {
            case .failure(let error):
                UserDefaults.standard.set(false, forKey: UserDefaultsKeys.userLoggedIn)
                self.error = error
            case .finished: break
            }
        } receiveValue: { [weak self] loginChat in
            guard let url = self?.generateURL(from: loginChat.location) else { return }
            NSWorkspace.shared.open(url) // TODO: Should be a WKWebView
        }.store(in: &cancellables)
    }
    
    func validateSignup(code: String, state: String) {
        NetworkService.validateSignIn(code: code, state: state)
            .receive(on: DispatchQueue.main)
            .sink { completion in
            switch completion {
            case .finished: break
            case .failure(let error):
                UserDefaults.standard.set(false, forKey: UserDefaultsKeys.userLoggedIn)
                self.error = error
            }
        } receiveValue: { _ in
            self.refreshLoginState()
        }.store(in: &cancellables)
    }
    
    func refreshLoginState() {
        guard let _ = self.hfChatToken else {
            self.error = HFError.missingHFToken
            return
        }
        NetworkService.getCurrentUser()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.error = error
                    self?.currentUser = nil
                    UserDefaults.standard.set(false, forKey: UserDefaultsKeys.userLoggedIn)
                case .finished: break
                }
            } receiveValue: { [weak self] user in
                self?.currentUser = user
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.userLoggedIn)
            }.store(in: &cancellables)
    }
    
    func logout() {
        DispatchQueue.main.async { [weak self] in
            self?.currentUser = nil
            self?.selectedConversation = nil
            self?.resetLocalModels()
            UserDefaults.standard.setValue(false, forKey: UserDefaultsKeys.userLoggedIn)
        }
        
        let cookieStore = HTTPCookieStorage.shared.cookies
        for cookie in cookieStore ?? [] {
            let backgroundQueue = DispatchQueue(label: "background_queue",
                                                qos: .background)
            backgroundQueue.async {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
            
        }
    }
    
    private func generateURL(from location: String) -> URL? {
        let s_url = location
        guard var component = URLComponents(string: s_url) else { return nil }
        var queryItems = component.queryItems ?? []
        queryItems.append(URLQueryItem(name: "prompt", value: "login"))
        component.queryItems = queryItems

        return component.url
    }
}

// MARK: Conversation functions
extension CoordinatorModel {
    func fetchConversations() {
        NetworkService.getConversations()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.error = error
                case .finished:
                    break
                }
            } receiveValue: { [weak self] conversations in
                self?.conversations = conversations
#if DEBUG
                self?.selectedConversation = conversations.first?.id
                self?.loadConversationHistory()
#endif
            }
            .store(in: &cancellables)
    }
    
    func loadConversationHistory() {
       guard let selectedId = selectedConversation,
             let conversation = conversations.first(where: { $0.id == selectedId }) else {
           return
       }
        self.messages = []
       NetworkService.getConversation(id: conversation.serverId)
           .receive(on: DispatchQueue.main)
           .map { [weak self] (conversation: Conversation) -> [MessageViewModel] in
               guard self != nil else { return [] }
//               self.conversation = conversation
               return conversation.messages.compactMap({ (message: Message) -> MessageViewModel? in
                   return MessageViewModel(message: message)
                })
           }
           .sink { [weak self] completion in
               switch completion {
               case .failure(let error):
                   self?.error = error
               case .finished: break
               }
           } receiveValue: { [weak self] messages in
               self?.messages = messages
           }
           .store(in: &cancellables)
    }
    
    func deleteConversation(id: String) {
        guard let index = conversations.firstIndex(where: { $0.serverId == id }) else {
           return
        }
        conversations.remove(at: index)
        NetworkService.deleteConversation(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        self?.error = error
                        self?.fetchConversations()
                    }
            } receiveValue: { _ in
                
            }.store(in: &cancellables)
    }
    
    func shareConversation() {
        guard !messages.isEmpty, selectedConversation != nil, let conversation = conversations.first(where: { $0.id == selectedConversation }) else {
            return
        }
        
        NetworkService.shareConversation(id: conversation.serverId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.error = error
                }
            } receiveValue: { [weak self] sharedConversation in
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(sharedConversation.url.absoluteString, forType: .string)
                self?.sharedConversationLink = sharedConversation.url
            }
            .store(in: &cancellables)
    }
    
    func resetConversation() {
        cancellables = []
        selectedConversation = nil
        messages = []
    }
}

// MARK: Model functions
extension CoordinatorModel {
    func getModels(shouldForceRefresh: Bool = false) -> AnyPublisher<[LLMModel], HFError> {
        if let models = self.getLocalModels(), !shouldForceRefresh {
            return Just(models).setFailureType(to: HFError.self).eraseToAnyPublisher()
        }

        return NetworkService.getModels().handleEvents(receiveOutput: { [weak self] models in
            guard let self = self else { return }
            let localModels = self.getLocalModels()
            if let locals = localModels {
                for model in models {
                    guard let local = locals.first(where: { $0.id == model.id }) else { continue }
                    model.preprompt = local.preprompt
                }
            }
            
            self.saveModels(models)
        }).eraseToAnyPublisher()
    }
    
    func getLocalModels() -> [LLMModel]? {
        guard let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.models) else {
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
    
    private func saveModels(_ models: [LLMModel]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(models)
            UserDefaults.standard.set(data, forKey: UserDefaultsKeys.models)
        } catch {
            print("Unable to Encode [LLModel] (\(error))")
        }
    }
    
    private func getLocalActiveModel() -> LLMViewModel? {
        guard let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.activeModel) else {
            return nil
        }
        do {
            let decoder = JSONDecoder()
            let activeModel = try decoder.decode(LLMViewModel.self, from: data)
            return activeModel
        } catch {
            print("Unable to Decode Active Model (\(error))")
            return nil
        }
    }
    
    func setActiveModel(_ activeModel: LLMViewModel) {
        self.activeModel = activeModel
        self.saveActiveModel(activeModel)
    }
    
    func saveActiveModel(_ activeModel: LLMViewModel) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(activeModel)
            UserDefaults.standard.set(data, forKey: UserDefaultsKeys.activeModel)
        } catch {
            print("Unable to Encode Active Model (\(error))")
        }
    }
    
    func resetLocalModels() {
        UserDefaults.standard.setValue(nil, forKey: UserDefaultsKeys.models)
        UserDefaults.standard.set(nil, forKey: UserDefaultsKeys.activeModel)
        activeModel = nil
    }
}


// MARK: Messages
extension CoordinatorModel {
    private func createConversationAndSendPrompt(_ prompt: String, withFiles: [String]? = nil, usingTools: [String]? = nil) {
        if let model = self.activeModel {
            createConversation(with: model.toLLMModel(), prompt: prompt, withFiles: withFiles, usingTools: usingTools)
        }
    }
    
    private func createConversation(with model: LLMModel, prompt: String, withFiles: [String]? = nil, usingTools: [String]? = nil) {
        NetworkService.createConversation(base: model)
            .receive(on: DispatchQueue.main).sink { completion in
                switch completion {
                case .finished:
                    print("ConversationViewModel.createConversation finished")
                case .failure(let error):
                    self.error = error
                }
            } receiveValue: { [weak self] conversation in
                self?.selectedConversation = conversation.id
                self?.messages = conversation.messages.compactMap { MessageViewModel(message: $0) }
                self?.conversations.insert(conversation, at: 0)
                self?.send(text: prompt, withFiles: withFiles)
            }.store(in: &cancellables)
    }
    
    func send(text: String, withFiles: [String]? = nil) {
        isInteractingWithModel = true
    
        guard let selectedId = selectedConversation,
              let conversation = conversations.first(where: { $0.id == selectedId }),
              let previousId = messages.last?.id else {
            createConversationAndSendPrompt(text, withFiles: withFiles)
            return
        }
        var trimmedText = ""
        //        if useContext {
        //            if let contextAppSelectedText = contextAppSelectedText {
        //                trimmedText += "Selected Text: ```\(contextAppSelectedText)```"
        //            }
        //            if let contextAppFullText = contextAppFullText {
        //                // TODO: Truncate full context if needed
        //                trimmedText += "\n\nFull Text:```\(contextAppFullText)```"
        //            }
        //        }
        //
        trimmedText += text.trimmingCharacters(in: .whitespaces)
        let userMessage = MessageViewModel(author: .user, content: trimmedText, files: withFiles)
        messages.append(userMessage)
        
        let systemMessage = MessageViewModel(author: .assistant, content: "")
        messages.append(systemMessage)
        
        let req = PromptRequestBody(id: previousId, inputs: trimmedText, webSearch: useWebSearch, files: withFiles)
        sendPromptRequest(req: req, conversationID: conversation.serverId)
    }
    
    private func sendPromptRequest(req: PromptRequestBody, conversationID: String) {
        guard let lastMessage = messages.last else { return }
        let sendPromptHandler = SendPromptHandler(conversationId: conversationID, messageVM: lastMessage)
        self.sendPromptHandler = sendPromptHandler
        let pub = sendPromptHandler.update
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
        pub.scan((0, nil), { (tuple, prod) in
            (tuple.0 + 1, prod)
        }).eraseToAnyPublisher()
            .sink { [weak self] completion in
                guard let self else { return }
                self.isInteractingWithModel = false
                switch completion {
                case .finished:
                    self.sendPromptHandler = nil
                case .failure(let error):
                    
                    switch error {
                    case .httpTooManyRequest:
                        self.messages.removeLast(2)
                        self.error = error
                    default:
                        self.error = error
                    }
                }
    
            } receiveValue: { [weak self] obj in
                let (count, _) = obj
                if count == 1 {
                    self?.updateConversation(conversationID: conversationID)
                }
            }.store(in: &cancellables)

        sendPromptHandler.sendPromptReq(reqBody: req)
    }
    
    private func updateConversation(conversationID: String) {
        NetworkService.getConversation(id: conversationID).sink { [weak self] completion in
            switch completion {
            case .finished: break
            case .failure(let error):
                self?.error = error
            }
        } receiveValue: { [weak self] conversation in
            // Update conversation title
            let currentConversation = self?.conversations.first(where: { $0.id == self?.selectedConversation })
            if currentConversation?.title != conversation.title {
                currentConversation?.title = conversation.title
            }
            
            // Update messages ID
            let mMessages = conversation.messages
            if let messagesCount = self?.messages.count, mMessages.count == messagesCount, messagesCount >= 2 {
                self?.messages[messagesCount - 1].id = mMessages[messagesCount - 1].id
                self?.messages[messagesCount - 2].id = mMessages[messagesCount - 2].id
            } else {
                return
            }
            
        }.store(in: &cancellables)
    }
}
