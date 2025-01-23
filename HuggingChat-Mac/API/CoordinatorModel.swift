//
//  CoordinatorModel.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/22/25.
//


import SwiftUI
import Combine

@Observable class CoordinatorModel {
    
    var currentUser: HuggingChatUser?
    var token: String?
    
    var error: HFError?
    var hfChatToken: String? {
        guard let token = HTTPCookieStorage.shared.cookies?.first(where: { $0.name == "hf-chat" })?.value else {
            return nil
        }
        return token
    }
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
