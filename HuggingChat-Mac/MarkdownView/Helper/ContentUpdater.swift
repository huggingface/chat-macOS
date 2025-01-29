import Combine
import SwiftUI

/// Update content 0.3s after the user stops entering.
class ContentUpdater: ObservableObject {
    /// Send all the changes from raw text
    private var relay = PassthroughSubject<String, Never>()
    
    /// A publisher to notify MarkdownView to update its content.
    var textUpdater: AnyPublisher<String, Never>
    
    init() {
        textUpdater = relay
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func push(_ text: String) {
        relay.send(text)
    }
}

class MarkdownTextStorage: ObservableObject {
    @MainActor static let `default` = MarkdownTextStorage()
    @Published var text: String? = nil
    
    internal init() { }
}

/// A Markdown Rendering Mode.
public enum MarkdownRenderingMode: Sendable {
    /// Immediately re-render markdown view when text changes.
    case immediate
    /// Re-render markdown view efficiently by adding a debounce to the pipeline.
    ///
    /// When input markdown text is heavy and will be modified in real time, use this mode will help you reduce CPU usage thus saving battery life.
    case optimized
}

struct MarkdownRenderingModeKey: EnvironmentKey {
    static let defaultValue: MarkdownRenderingMode = .immediate
}

/// Thread to render markdown content on.
public enum MarkdownRenderingThread: Sendable {
    /// Render & Update markdown content on main thread.
    case main
    /// Render markdown content on background thread, while updating view on main thread.
    case background
}

struct MarkdownRenderingThreadKey: EnvironmentKey {
    static let defaultValue: MarkdownRenderingThread = .background
}

extension EnvironmentValues {
    /// Markdown rendering mode
    var markdownRenderingMode: MarkdownRenderingMode {
        get { self[MarkdownRenderingModeKey.self] }
        set { self[MarkdownRenderingModeKey.self] = newValue }
    }
    
    /// Markdown rendering thread
    var markdownRenderingThread: MarkdownRenderingThread {
        get { self[MarkdownRenderingThreadKey.self] }
        set { self[MarkdownRenderingThreadKey.self] = newValue }
    }
}

// MARK: - Markdown Rendering Mode

extension View {
    /// MarkdownView rendering mode.
    ///
    /// - Parameter renderingMode: Markdown rendering mode.
    public func markdownRenderingMode(_ renderingMode: MarkdownRenderingMode) -> some View {
        environment(\.markdownRenderingMode, renderingMode)
    }
    
    /// The thread to render content.
    ///
    /// - Parameter thread: The thread for rendering markdown content on.
    public func markdownRenderingThread(_ thread: MarkdownRenderingThread) -> some View {
        environment(\.markdownRenderingThread, thread)
    }
}
