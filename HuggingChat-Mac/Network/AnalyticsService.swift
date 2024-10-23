//
//  AnalyticsService.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import Combine
import Foundation
import AppKit

final class AnalyticsService {
    static let shared: AnalyticsService = AnalyticsService()
    
    private let PlausibleAPIEventURL = URL(string: "https://plausible.io/api/event")!
    private let PlausibleDomain: String = "hugging.chat"

    private var cancellables: [AnyCancellable] = []
    
    private init() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(applicationDidBecomeActive),
                                               name: NSApplication.didBecomeActiveNotification, // UIApplication.didBecomeActiveNotification for swift 4.2+
            object: nil)
    }
    
    private func plausibleRequest(name: String, path: String, properties: [String: String]) {
        var req = URLRequest(url: PlausibleAPIEventURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var props = properties
        props["AppVersion"] = UserAgentBuilder.appVersion
        props["BuildNumber"] = UserAgentBuilder.buildNumber
        props["Device"] = UserAgentBuilder.device
        props["OS"] = UserAgentBuilder.osVersion
        
        var jsonObject: [String: Any] = ["name": name, "url": constructPageviewURL(path: path), "domain": PlausibleDomain]
        if !props.isEmpty {
            jsonObject["props"] = props
        }
        
        let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject)
        req.httpBody = jsonData
        
        NetworkService.sendRequest(req).sink { completion in
            switch completion {
                
            case .finished:
                print("Plausible Request Sent for event: \(path)")
            case .failure(let error):
                print("Plausible Request Failed:\n\(error)")
            }
        } receiveValue: { data in
            guard let data = data, let s = String(data: data, encoding: .utf8) else { return }
            print("plausible response: \(s)")
        }.store(in: &cancellables)
    }
    
    
    func appOpen() {
        plausibleRequest(name: "event", path: "AppOpen", properties: [:])
    }
    
    func createConversation(model: String) {
        plausibleRequest(name: "event", path: "CreateConversation", properties: ["Model": model])
    }
    
    @objc func applicationDidBecomeActive() {
        appOpen()
    }
    
    private func constructPageviewURL(path: String) -> String {
        let url = URL(string: "https://\(PlausibleDomain)")!

        return url.appendingPathComponent(path).absoluteString
    }
}

public enum PlausibleError: Error {
    case domainNotSet
    case invalidDomain
    case eventIsPageview
}
