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
    var messages: [Message] = []
    var selectedConversation: Conversation.ID?
    
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
    
    init() {
        let cookies = HTTPCookieStorage.shared.cookies!
        for cookie in cookies {
            print("\(cookie.name): \(cookie.value)")
        }
        self.refreshLoginState()
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
//            self?.currentConversation = ""
//            DataService.shared.resetLocalModels()
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
           .sink { [weak self] completion in
               switch completion {
               case .failure(let error):
                   self?.error = error
               case .finished: break
               }
           } receiveValue: { [weak self] conv in
               self?.messages = conv.messages
           }
           .store(in: &cancellables)
    }
//
//    private func buildHistory(conversation: Conversation) -> [MessageRow] {
//        let messages = conversation.messages.compactMap({ (message: Message) -> MessageRow? in
//           return MessageRow(message: message)
//        })
////        let historyParser = HistoryParser(isDarkMode: isDarkMode)
////        messages = historyParser.parseMessages(messages: messages)
//        return messages
//    }
}
