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
        let cookieStore = HTTPCookieStorage.shared.cookies
        for cookie in cookieStore ?? [] {
            let backgroundQueue = DispatchQueue(label: "background_queue",
                                                qos: .background)
            backgroundQueue.async {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
            
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.currentUser = nil
            self?.selectedConversation = nil
            self?.resetLocalModels()
            UserDefaults.standard.setValue(false, forKey: UserDefaultsKeys.userLoggedIn)
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
    
    private func getLocalModels() -> [LLMModel]? {
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
            print("createConversationAndSendPrompt")
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
        guard let selectedId = selectedConversation,
              let conversation = conversations.first(where: { $0.id == selectedId }),
              let previousId = messages.last?.id else {
            print("Creating conversation")
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
        // TODO: Add state here
        guard let lastMessage = messages.last else { return }
        let sendPromptHandler = SendPromptHandler(conversationId: conversationID, messageVM: lastMessage)
        self.sendPromptHandler = sendPromptHandler
        let messageRow = self.messages.last!
//        let messageRow = sendPromptHandler.messageRow
//        
        let pub = sendPromptHandler.update
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
        pub.sink { [weak self] completion in
                    guard let self else { return }
                    switch completion {
                    case .finished:
                        self.sendPromptHandler = nil
                    case .failure(let error):
                        switch error {
                        case .httpTooManyRequest:
                            self.error = .verbose("You've sent too many requests. Please try logging in before sending a message.")
                        default:
                            self.error = error
                        }
                    }
                } receiveValue: { [weak self] _ in
                    // No need to do anything here since we're updating the message in place
                }.store(in: &cancellables)
//        pub.scan((0, messageRow)) { (tuple, newMessage) in
//            (tuple.0 + 1, newMessage)
//        }.eraseToAnyPublisher()
//            .sink { [weak self] completion in
//                guard let self else { return }
//                switch completion {
//                case .finished:
//                    self.sendPromptHandler = nil
////                    isInteracting = false
//                    self.sendPromptHandler = nil
////                    state = .loaded
//                case .failure(let error):
//                    switch error {
//                    case .httpTooManyRequest:
////                        self.messages.removeLast(2)
////                        self.state = .error
//                        self.error = .verbose("You've sent too many requests. Please try logging in before sending a message.")
////                        print(error.localizedDescription)
//                    default:
////                        self.state = .error
//                        self.error = error
//                        print(error.localizedDescription)
//                    }
//                }
//            } receiveValue: { [weak self] obj in
//                print(obj, "verbose")
//                guard let self else { return }
//                let (count, messageRow) = obj
//                print("message row")
////                if count == 1 {
////                    self.updateConversation(conversationID: conversationID)
////                }
////                
////                self.message = messageRow
////                print(messageRow)
////                if let lastIndex = self.messages.lastIndex(where: { $0.id == messageRow.id }) {
////                    self.messages[lastIndex] = messageRow
////                }
////
////                if let fileInfo = self.message?.fileInfo,
////                   fileInfo.mime.hasPrefix("image/"),
////                   let conversationID = self.conversation?.id {
////                    self.imageURL = "https://huggingface.co/chat/conversation/\(conversationID)/output/\(fileInfo.sha)"
////                }
////                
//            }.store(in: &cancellables)
//
        sendPromptHandler.sendPromptReq(reqBody: req)
    }
}
