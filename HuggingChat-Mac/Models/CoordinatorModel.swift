//
//  CoordinatorModel.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/24/24.
//

import SwiftUI
import Combine

@Observable class CoordinatorModel {
    
    private var cancellables = Set<AnyCancellable>()
    
    func signin() {
        NetworkService.loginChat()
            .receive(on: DispatchQueue.main)
            .sink { completion in
            switch completion {
            case .failure(let error):
                print(error.localizedDescription) // TODO: Handle error
//                self?.showError(error: error)
            case .finished: break
            }
        } receiveValue: { [weak self] loginChat in
            guard let url = self?.generateURL(from: loginChat.location) else { return }
            NSWorkspace.shared.open(url) // TODO: Should be a WKWebView
        }.store(in: &cancellables)
    }
    
    func appleSignin(token: String) {
        NetworkService.loginChat()
            .receive(on: DispatchQueue.main)
            .sink { completion in
            switch completion {
            case .failure(let error):
                print(error.localizedDescription)
//                self?.showError(error: error)
            case .finished: break
            }
        } receiveValue: { [weak self] loginChat in
            guard let url = self?.generateURL(from: loginChat.location, appleToken: token) else { return }
            NSWorkspace.shared.open(url)
        }.store(in: &cancellables)
    }
    
    func validateSignup(code: String, state: String) {
//        DispatchQueue.main.async {
//            self.delegate?.dismissController(animated: true)
//        }
        NetworkService.validateSignIn(code: code, state: state)
            .receive(on: DispatchQueue.main)
            .sink { completion in
            switch completion {
            case .finished:
                print("Connected")
//                self?.showInfo(info: "Connected")
            case .failure(let error):
                print(error.localizedDescription)
//                self?.showError(error: error)
            }
        } receiveValue: { _ in
            print("SignIn Validated")
            HuggingChatSession.shared.refreshLoginState()
            UserDefaults.standard.set(true, forKey: "userLoggedIn")
            
//            self?.conversationViewModel.reset()
//            self?.loadMostRecentConversation()
//            self?.delegate?.removeRequestLoginPopupIfNeeded()
        }.store(in: &cancellables)
    }
    
    private func generateURL(from location: String, appleToken: String? = nil) -> URL? {
        var s_url = location
        if appleToken != nil {
            s_url = location.replacingOccurrences(of: "/oauth/authorize", with: "/login/apple")
        }
        guard var component = URLComponents(string: s_url) else { return nil }
        var queryItems = component.queryItems ?? []
        queryItems.append(URLQueryItem(name: "prompt", value: "login"))
        if let appleToken = appleToken {
            queryItems.append(URLQueryItem(name: "id_token", value: appleToken))
        }
        component.queryItems = queryItems

        return component.url
    }
}
