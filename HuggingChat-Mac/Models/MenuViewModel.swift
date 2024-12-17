//
//  MenuViewModel.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 12/17/24.
//

import SwiftUI
import Combine

enum GroupedConversationType {
    case section, conversation(Conversation)
}

struct GroupedConversation: Identifiable {
    var id: String {
        switch type {
        case .section:
            return "section-\(title)"
        case .conversation(let conversation):
            return "conv-\(conversation.id)"
        }
    }
    let title: String
    let type: GroupedConversationType
}

@Observable final class MenuViewModel {
    var conversations: [String: [Conversation]] = [:]
    
    private var cancellables = [AnyCancellable]()
    
    var currentConversationId: String = ""

    func refreshState() {
        HuggingChatSession.shared.refreshLoginState()
        if (HuggingChatSession.shared.currentUser != nil) {
            self.getConversations()
        } else {
            self.conversations = [:]
        }
        
        if let conversation = HuggingChatSession.shared.currentConversation {
            self.currentConversationId = conversation
        }
    }
    
    func didSelectConversation(at indexPath: IndexPath) {
//        let conv = conversations[indexPath.row]
//        guard case let .conversation(conversation) = conv.type else { return }
//        currentConversationId = conversation.id
//        internalDelegate?.reloadData()
//        
//        DispatchQueue.main.asyncAfter(deadline: .now()) {
//            self.delegate?.didSelect(conversation: conversation)
//        }
    }
    
    func deleteConversation(at indexPath: IndexPath) {
//        guard case let .conversation(conversation) = conversations[indexPath.row].type else { return }
//        conversations.remove(at: indexPath.row)
//        internalDelegate?.reloadData()
//        
//        NetworkService.deleteConversation(id: conversation.id)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                    switch completion {
//                    case .finished: break
//                    case .failure(let error):
//                        self?.delegate?.showError(error: error)
//                        self?.getConversations()
//                    }
//            } receiveValue: { _ in
//                
//            }.store(in: &cancellables)
    }
    
    func editConversationTitle(at indexPath: IndexPath, title: String) {
//        guard case let .conversation(conversation) = conversations[indexPath.row].type, !title.isEmpty else { return }
//        conversation.title = title
//        internalDelegate?.reloadData()
//        
//        NetworkService.editConversationTitle(conversation: conversation)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                    switch completion {
//                    case .finished: break
//                    case .failure(let error):
//                        self?.delegate?.showError(error: error)
//                        self?.getConversations()
//                    }
//            } receiveValue: { _ in
//                
//            }.store(in: &cancellables)
    }

    func getConversations() {
        NetworkService.getConversations()
            .receive(on: DispatchQueue.main)
            .sink { completion in
            switch completion {
            case .finished: break
            case .failure(let error):
                print(error.localizedDescription)
            }
        } receiveValue: { [weak self] conversations in
            let conversations = MenuViewModel.groupConversationsByDates(
                conversations: conversations)
            if !conversations.isEmpty {
                self?.conversations = conversations
            }
            
        }.store(in: &cancellables)
    }
    
    func getConversation(withServerId id: String) -> Conversation? {
        for (_, conversations) in conversations {
            if let conversation = conversations.first(where: { $0.serverId == id }) {
                return conversation
            }
        }
        return nil
    }

    static func groupConversationsByDates(conversations: [Conversation]) -> [String: [Conversation]] {
        let date = Date()
        let calendar = Calendar.current
        
        // Get start of today
        let startOfToday = calendar.startOfDay(for: date)
        
        // Initialize the grouped dictionary
        var grouped: [String: [Conversation]] = [
            "Today": [],
            "This Week": [],
            "This Month": [],
            "Older": []
        ]
        
        for conversation in conversations {
            if calendar.isDate(conversation.updatedAt, inSameDayAs: date) {
                grouped["Today"]?.append(conversation)
            } else if conversation.updatedAt >= calendar.date(byAdding: .day, value: -7, to: startOfToday)! {
                grouped["This Week"]?.append(conversation)
            } else if conversation.updatedAt >= calendar.date(byAdding: .day, value: -30, to: startOfToday)! {
                grouped["This Month"]?.append(conversation)
            } else {
                grouped["Older"]?.append(conversation)
            }
        }
        
        // Remove empty sections
        return grouped.filter { !$0.value.isEmpty }
    }
}
