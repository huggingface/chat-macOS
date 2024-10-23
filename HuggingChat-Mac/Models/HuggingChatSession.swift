//
//  HuggingChatSession.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import SwiftUI
import Combine
import Foundation
import WebKit
import SafariServices
import AuthenticationServices

@Observable class HuggingChatSession {
    static let shared: HuggingChatSession = HuggingChatSession()

    var clientID: String?
    var token: String?
    var conversations: [Conversation] = []
    var availableLLM: [LLMModel] = []
    var currentConversation: String = ""
    var currentUser: HuggingChatUser?
    
    private var cancellables: [AnyCancellable] = []

    init() {
//        if !UserDefaults.standard.bool(forKey: "userLoggedIn") {
//            
//            UserDefaults.standard.setValue(true, forKey: "userLoggedIn")
//        } else {
//            // TODO: No need to login
//        }
        
        let cookies = HTTPCookieStorage.shared.cookies!
        
        for cookie in cookies {
            print("\(cookie.name): \(cookie.value)")
        }
    }

//    var user: AnyPublisher<HuggingChatUser?, Never> {
//        return _user.eraseToAnyPublisher()
//    }
//    
//    private var _user: PassthroughSubject<HuggingChatUser?, Never> = PassthroughSubject<HuggingChatUser?, Never>()
    
    func refreshLoginState() {
//        let cookies = HTTPCookieStorage.shared.cookies!
        NetworkService.getCurrentUser()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
            switch completion {
            case .failure(let error):
                print(error.localizedDescription)
                self?.currentUser = nil
            case .finished: break
            }
        } receiveValue: { [weak self] user in
            self?.currentUser = user
        }.store(in: &cancellables)

    }
    
    var hfChatToken: String? {
        guard let token = HTTPCookieStorage.shared.cookies?.first(where: { $0.name == "hf-chat" })?.value else {
            return nil
        }
        return token
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
            self?.currentConversation = ""
            DataService.shared.resetLocalModels()
            UserDefaults.standard.setValue(false, forKey: "userLoggedIn")
            UserDefaults.standard.setValue(false, forKey: "onboardingDone")
        }
    }
}
