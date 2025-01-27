//
//  NetworkService.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/22/25.
//

import Combine
import Foundation

final class NetworkService {
    private static let defaultBaseURL = "https://huggingface.co"
    fileprivate static var BASE_URL: String {
        get {
            UserDefaults.standard.string(forKey: UserDefaultsKeys.baseURL) ?? defaultBaseURL
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.baseURL)
        }
    }
    
    static func resetToDefaultURL() {
        BASE_URL = defaultBaseURL
    }
}

// MARK: Conversations
extension NetworkService {
    static func getConversations() -> AnyPublisher<[Conversation], HFError> {
        let endpoint = "\(BASE_URL)/chat/api/conversations"
        let request = URLRequest(url: URL(string: endpoint)!)
        return resolveRequest(request, decoder: JSONDecoder.ISO8601Millisec())
    }
    
    static func getConversation(id: String) -> AnyPublisher<Conversation, HFError> {
        let endpoint = "\(BASE_URL)/chat/api/conversation/\(id)"
        let request = URLRequest(url: URL(string: endpoint)!)
        return resolveRequest(request, decoder: JSONDecoder.ISO8601Millisec())
    }
    
    static func createConversation(base: BaseConversation) -> AnyPublisher<Conversation, HFError> {
        let endpoint = "\(BASE_URL)/chat/conversation"
        let headers = ["Content-Type": "application/json"]
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers

        do {
            let jsonData = try JSONEncoder().encode(base.toNewConversation())
            request.httpBody = jsonData
            return resolveRequest(request, decoder: JSONDecoder.ISO8601())
                .flatMap({ (newConversation: NewConversation) in
                    return getConversation(id: newConversation.id).eraseToAnyPublisher()
                }).eraseToAnyPublisher()
        } catch {
            return Fail(outputType: Conversation.self, failure: HFError.encodeError(error)).eraseToAnyPublisher()
        }
    }
    
    static func deleteConversation(id: String) -> AnyPublisher<Void, HFError> {
        let endpoint = "\(BASE_URL)/chat/conversation/\(id)"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "DELETE"
        return sendRequest(request).map { _ in Void() }.eraseToAnyPublisher()
    }
    
    static func editConversationTitle(conversation: Conversation) -> AnyPublisher<Void, HFError> {
        let endpoint = "\(BASE_URL)/chat/conversation/\(conversation.id)"
        let headers = ["Content-Type": "application/json"]
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = headers
        
        do {
            let jsonData = try JSONEncoder().encode(conversation.toTitleEditionBody())
            request.httpBody = jsonData
            return sendRequest(request).map { _ in Void() }.eraseToAnyPublisher()
        } catch {
            return Fail(outputType: Void.self, failure: HFError.encodeError(error)).eraseToAnyPublisher()
        }
    }
    
    static func shareConversation(id: String) -> AnyPublisher<SharedConversation, HFError> {
        let endpoint = "\(BASE_URL)/chat/conversation/\(id)/share"
        let headers = ["Content-Type": "application/json"]
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        return resolveRequest(request, decoder: JSONDecoder())
    }
}

// MARK: Models
extension NetworkService {
    static func getModels() -> AnyPublisher<[LLMModel], HFError> {
        let endpoint = "\(BASE_URL)/chat/api/models"
        let request = URLRequest(url: URL(string: endpoint)!)
        return resolveRequest(request, decoder: JSONDecoder.ISO8601())
    }
}

// MARK: Login/Sign up functions
extension NetworkService {
    static func loginChat() -> AnyPublisher<LoginChat, HFError> {
        let endpoint = URL(string: "\(BASE_URL)/chat/login?callback=huggingchat%3A%2F%2Flogin%2Fcallback")!
        var request = URLRequest(url: endpoint)

        var headers: [String: String] = [:]
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        headers["Accept"] = "*/*"
        headers["Referer"] = "\(BASE_URL)/chat/login"

        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpShouldHandleCookies = true
        request.httpBody = Data("".utf8)
        
        return resolveRequest(request)
    }
    
    static func validateSignIn(code: String, state: String) -> AnyPublisher<Void, HFError> {
        var headers: [String: String] = [:]
        headers["Accept"] = "*/*"
        headers["Referer"] = "\(BASE_URL)/"

        var request = URLRequest(url: URL(string: "\(BASE_URL)/chat/login/callback?code=\(code)&state=\(state)")!)
        request.allHTTPHeaderFields = headers

        return sendRequest(request)
        .map { s in
            Void()
        }.toNetworkError()
    }
    
    static func getCurrentUser() -> AnyPublisher<HuggingChatUser, HFError> {
        let endpoint = "\(BASE_URL)/chat/api/user"
        let request = URLRequest(url: URL(string: endpoint)!)
        
        return resolveRequest(request)
    }
}

// MARK: Helper functions
extension NetworkService {
    private static func resolveRequest<T: Decodable>(_ request: URLRequest, decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<T, HFError> {
        return sendRequest(request)
        .tryMap { data in
            guard let data = data else {
                throw HFError.unknown
            }
            print(String(data: data, encoding: .utf8) ?? "Could not convert data to string")
            do {
                let models = try decoder.decode(T.self, from: data)
                return models
            } catch {
                throw HFError.decodeError(error)
            }
        }.toNetworkError().eraseToAnyPublisher()
    }
    
    private static func sendRequest(_ request: URLRequest) -> AnyPublisher<Data?, HFError> {
        var req = request
        req.setValue(UserAgentBuilder.userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue(self.BASE_URL, forHTTPHeaderField: "Origin")
        let publisher = Deferred {
            Future<Data?, HFError> { promise in
                let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
                    if let error = error {
                        promise(.failure(HFError.networkError(error)))
                        return
                    }
                    
                    guard let response = response else {
                        promise(.failure(.noResponse))
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse else {
                        promise(.failure(.notHTTPResponse(response, data)))
                        return
                    }

                    guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                        promise(.failure(.httpError(httpResponse.statusCode, data)))
                        return
                    }
                    
                    promise(.success(data))
                }

                task.resume()
            }
        }

        return publisher.eraseToAnyPublisher()
    }
}

final class PostStream: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    private let BASE_URL: String = NetworkService.BASE_URL
    private let sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default..{
        $0.requestCachePolicy = .reloadIgnoringLocalCacheData
    }
    private lazy var session: URLSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: .main)
    
    private let encoder = JSONEncoder()..{
        $0.keyEncodingStrategy = .convertToSnakeCase
    }
    
    private var _update: PassthroughSubject<Data, HFError> = PassthroughSubject<Data, HFError>()

    func postPrompt(reqBody: PromptRequestBody, conversationId: String) -> AnyPublisher<Data, HFError> {
        let endpoint = "\(BASE_URL)/chat/conversation/\(conversationId)"
        
        let boundary = "------\(UUID().uuidString)"
        let headers = ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.setValue(UserAgentBuilder.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("https://huggingface.co", forHTTPHeaderField: "Origin")

        do {
            let jsonData = try encoder.encode(reqBody)
            var data = Data()
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"data\"\r\n\r\n".data(using: .utf8)!)
            data.append(jsonData)
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            request.httpBody = data
        } catch {
            return Fail(outputType: Data.self, failure: HFError.encodeError(error)).eraseToAnyPublisher()
        }

        let task = self.session.dataTask(with: request)
        task.delegate = self
        
        return _update.eraseToAnyPublisher().handleEvents(receiveRequest:  { _ in
            task.resume()
        }).eraseToAnyPublisher()
    }


    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        _update.send(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            _update.send(completion: .failure(HFError.networkError(error)))
            return
        }
        
        guard let response = task.response else {
            _update.send(completion: .failure(.noResponse))
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            _update.send(completion: .failure(.notHTTPResponse(response, nil)))
            return
        }
        
        if httpResponse.statusCode == 429 {
            _update.send(completion: .failure(.httpTooManyRequest))
            return
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            _update.send(completion: .failure(.httpError(httpResponse.statusCode, nil)))
            return
        }
        
        _update.send(completion: .finished)
    }
}
