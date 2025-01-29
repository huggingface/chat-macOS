import SwiftUI
#if canImport(_Concurrency)
import _Concurrency

// MARK: - Task

extension View {
    /// Serve as a combination of `onAppear` and `onChange` on unsupported platforms,
    /// and native `task` modifier on supported platforms.
    /// - Parameters:
    ///   - id: The value to observe for changes. The value must conform to the `Equatable` protocol.
    ///   - priority: The task priority to use when creating the asynchronous task. The default priority is `userInitiated`.
    ///   - action: A closure that SwiftUI calls as an asynchronous task before the view appears. SwiftUI can automatically cancel the task after the view disappears before the action completes. If the id value changes, SwiftUI cancels and restarts the task.
    /// - Returns: A view that runs the specified action asynchronously before the view appears, or restarts the task with the id value changes.
    func _task<E: Equatable>(id: E, priority: TaskPriority = .userInitiated, @_inheritActorContext _ action: @escaping @Sendable () async -> Void) -> some View {
        modifier(_TaskModifier(id: id, priority: priority, action: action))
    }
}

fileprivate struct _TaskModifier<E: Equatable>: ViewModifier {
    var id: E
    var priority: TaskPriority
    var action: @Sendable () async -> Void
    @State private var currentTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *) {
            content.task(id: id, priority: priority) {
                await action()
            }
        } else {
            content
                .onAppear { currentTask = Task(priority: priority, operation: action) }
                .onDisappear { currentTask?.cancel() }
                .onChange(of: id) { _ in
                    currentTask?.cancel()
                    currentTask = Task(priority: priority, operation: action)
                }
        }
    }
}
#endif


// MARK: - Overlay

extension View {
    /// Layers a secondary view in front of this view.
    ///
    /// A combination of the better API and old platforms support.
    ///
    /// - Parameters:
    ///   - alignment: The alignment for overlay in relation to this view.
    ///   - content: The view to layer in front of this view.
    /// - Returns: A view that layers overlay in front of the view.
    func _overlay(alignment: Alignment = .center, @ViewBuilder content: @escaping () -> some View) -> some View {
        modifier(_OverlayModifier(alignment: alignment, overlay: content))
    }
}

fileprivate struct _OverlayModifier<Overlay: View>: ViewModifier {
    var alignment: Alignment
    @ViewBuilder var overlay: () -> Overlay
    
    func body(content: Content) -> some View {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *) {
            content.overlay(alignment: alignment) { overlay() }
        } else {
            content.overlay(overlay(), alignment: alignment)
        }
    }
}
