//
//  NetworkService.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

// swift-format-ignore-file
import Combine
import Foundation

public enum DateDecodingStrategy {
    case formatted(DateFormatter)
}

final class NetworkService {
    private static let defaultBaseURL = "https://huggingface.co"
    fileprivate static var BASE_URL: String {
        get {
            UserDefaults.standard.string(forKey: "baseURL") ?? defaultBaseURL
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "baseURL")
        }
    }
    
    static func resetToDefaultURL() {
        BASE_URL = defaultBaseURL
    }
    
    // Helper method to update BASE_URL
    static func updateBaseURL(_ newURL: String) {
        BASE_URL = newURL
    }
//    fileprivate static let BASE_URL: String = "http://192.168.1.111:5173"
//    fileprivate static let BASE_URL: String = "https://dc7a-83-83-23-99.ngrok-free.app"


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

    static func createConversation(base: BaseConversation) -> AnyPublisher<Conversation, HFError> {
        AnalyticsService.shared.createConversation(model: base.id)
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

    static func getConversation(id: String) -> AnyPublisher<Conversation, HFError> {
        let endpoint = "\(BASE_URL)/chat/api/conversation/\(id)"
        let request = URLRequest(url: URL(string: endpoint)!)
        return resolveRequest(request, decoder: JSONDecoder.ISO8601Millisec())
    }
    
    static func getMyAssistants() -> AnyPublisher<[Assistant], HFError> {
        let endpoint = "\(BASE_URL)/chat/api/user/assistants"
        let request = URLRequest(url: URL(string: endpoint)!)
        return resolveRequest(request, decoder: JSONDecoder.ISO8601Millisec())
    }
    
    static func getAssistants(page: Int = 0) -> AnyPublisher<AssistantResponse, HFError> {
        let endpoint = "\(BASE_URL)/chat/api/assistants?p=\(page)"
        let request = URLRequest(url: URL(string: endpoint)!)
        return resolveRequest(request, decoder: JSONDecoder.ISO8601Millisec())
    }
    
    static func getAssistant(id: String) -> AnyPublisher<Assistant, HFError> {
        let endpoint = "\(BASE_URL)/chat/api/assistant/\(id)"
        let request = URLRequest(url: URL(string: endpoint)!)
        return resolveRequest(request, decoder: JSONDecoder.ISO8601Millisec())
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

    static func getConversations() -> AnyPublisher<[Conversation], HFError> {
        let endpoint = "\(BASE_URL)/chat/api/conversations"
        let request = URLRequest(url: URL(string: endpoint)!)
        return resolveRequest(request, decoder: JSONDecoder.ISO8601Millisec())
    }

    static func getModels() -> AnyPublisher<[LLMModel], HFError> {
        let endpoint = "\(BASE_URL)/chat/api/models"
        let request = URLRequest(url: URL(string: endpoint)!)
        return resolveRequest(request, decoder: JSONDecoder.ISO8601())
    }
    
    static func shareConversation(id: String) -> AnyPublisher<SharedConversation, HFError> {
        let endpoint = "\(BASE_URL)/chat/conversation/\(id)/share"
        let headers = ["Content-Type": "application/json"]
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        return resolveRequest(request, decoder: JSONDecoder())
    }
    
    static func getCurrentUser() -> AnyPublisher<HuggingChatUser, HFError> {
        guard let _ = HuggingChatSession.shared.hfChatToken else {
            return Fail(outputType: HuggingChatUser.self, failure: HFError.missingHFToken).eraseToAnyPublisher()
        }
        let endpoint = "\(BASE_URL)/chat/api/user"
        let request = URLRequest(url: URL(string: endpoint)!)
        
        return resolveRequest(request)
    }
    
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private static func resolveRequest<T: Decodable>(_ request: URLRequest, decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<T, HFError> {
        return sendRequest(request)
        .tryMap { data in
            guard let data = data else {
                throw HFError.unknown
            }

            do {
                let models = try decoder.decode(T.self, from: data)
                return models
            } catch {
                throw HFError.decodeError(error)
            }
        }.toNetworkError().eraseToAnyPublisher()
    }
    
    static func sendRequest(_ request: URLRequest) -> AnyPublisher<Data?, HFError> {
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
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: endpoint)!)
        
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(UserAgentBuilder.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("\(BASE_URL)", forHTTPHeaderField: "Origin")
        
        var data = Data()
        
        // Add the files. Add tools Document Parser if supported.
        // TODO: Limit to 10MB per file otherwise error out
        if let filePaths = reqBody.files {
            for (_, filePath) in filePaths.enumerated() {
                let fileURL = URL(fileURLWithPath: filePath)
                let filename = fileURL.lastPathComponent
                do {
                    let fileData = try Data(contentsOf: fileURL)
                    let base64String = fileData.base64EncodedString()
                    
                    data.append("--\(boundary)\r\n".data(using: .utf8)!)
                    data.append("Content-Disposition: form-data; name=\"files\"; filename=\"base64;\(filename)\"\r\n".data(using: .utf8)!)
                    data.append("Content-Type: \(mimeType(for: fileURL))\r\n\r\n".data(using: .utf8)!)
                    data.append(base64String.data(using: .utf8)!)
                    data.append("\r\n".data(using: .utf8)!)
                } catch {
                    print("Error reading file: \(error)")
                }
            }
        }
        
        // Create a cleaned request body without files for JSON
        var cleanedReqBody = reqBody
        cleanedReqBody.files = nil
        
        // Add the JSON part
        do {
            let jsonData = try encoder.encode(cleanedReqBody)
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"data\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
            data.append(jsonData)
            data.append("\r\n".data(using: .utf8)!)
        } catch {
            return Fail(outputType: Data.self, failure: HFError.encodeError(error)).eraseToAnyPublisher()
        }
        
        // Add the final boundary
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = data

        let task = self.session.dataTask(with: request)
        task.delegate = self
        
        return _update.eraseToAnyPublisher().handleEvents(receiveRequest: { _ in
            task.resume()
        })
        .eraseToAnyPublisher()
    }
    
    func mimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension
        
        switch pathExtension.lowercased() {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "pdf":
            return "application/pdf"
        default:
            return "application/octet-stream"
        }
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

