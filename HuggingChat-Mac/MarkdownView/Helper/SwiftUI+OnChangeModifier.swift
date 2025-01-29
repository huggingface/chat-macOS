import SwiftUI

extension View {
    
    /// Adds a modifier for this view that fires an action when a specific
    /// value changes.
    ///
    /// You can use `onChange` to trigger a side effect as the result of a
    /// value changing, such as an `Environment` key or a `Binding`.
    ///
    /// The system may call the action closure on the main actor, so avoid
    /// long-running tasks in the closure. If you need to perform such tasks,
    /// detach an asynchronous background task.
    ///
    /// When the value changes, the new version of the closure will be called,
    /// so any captured values will have their values from the time that the
    /// observed value has its new value. The old and new observed values are
    /// passed into the closure. In the following code example, `PlayerView`
    /// passes both the old and new values to the model.
    ///
    ///     struct PlayerView: View {
    ///         var episode: Episode
    ///         @State private var playState: PlayState = .paused
    ///
    ///         var body: some View {
    ///             VStack {
    ///                 Text(episode.title)
    ///                 Text(episode.showTitle)
    ///                 PlayButton(playState: $playState)
    ///             }
    ///             .onChange(of: playState) { oldState, newState in
    ///                 model.playStateDidChange(from: oldState, to: newState)
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - value: The value to check against when determining whether
    ///     to run the closure.
    ///   - initial: Whether the action should be run when this view initially
    ///     appears.
    ///   - action: A closure to run when the value changes.
    ///   - oldValue: The old value that failed the comparison check (or the
    ///     initial value when requested).
    ///   - newValue: The new value that failed the comparison check.
    ///
    /// - Returns: A view that fires an action when the specified value changes.
    @_disfavoredOverload
    @available(iOS, introduced: 14.0, deprecated: 17.0)
    @available(macOS, introduced: 11.0, deprecated: 14.0)
    @available(tvOS, introduced: 14.0, deprecated: 17.0)
    @available(watchOS, introduced: 7.0, deprecated: 10.0)
    @available(visionOS, unavailable)
    public func onChange<E: Equatable>(
        of value: E,
        initial: Bool = false,
        _ action: @escaping (_ oldValue: E, _ newValue: E) -> Void
    ) -> some View {
        modifier(
            OnChangeModifier(
                value: value,
                initial: initial,
                action: .init(action)
            )
        )
    }
    
    /// Adds a modifier for this view that fires an action when a specific
    /// value changes.
    ///
    /// You can use `onChange` to trigger a side effect as the result of a
    /// value changing, such as an `Environment` key or a `Binding`.
    ///
    /// The system may call the action closure on the main actor, so avoid
    /// long-running tasks in the closure. If you need to perform such tasks,
    /// detach an asynchronous background task.
    ///
    /// When the value changes, the new version of the closure will be called,
    /// so any captured values will have their values from the time that the
    /// observed value has its new value. In the following code example,
    /// `PlayerView` calls into its model when `playState` changes model.
    ///
    ///     struct PlayerView: View {
    ///         var episode: Episode
    ///         @State private var playState: PlayState = .paused
    ///
    ///         var body: some View {
    ///             VStack {
    ///                 Text(episode.title)
    ///                 Text(episode.showTitle)
    ///                 PlayButton(playState: $playState)
    ///             }
    ///             .onChange(of: playState) {
    ///                 model.playStateDidChange(state: playState)
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - value: The value to check against when determining whether
    ///     to run the closure.
    ///   - initial: Whether the action should be run when this view initially
    ///     appears.
    ///   - action: A closure to run when the value changes.
    ///
    /// - Returns: A view that fires an action when the specified value changes.
    @_disfavoredOverload
    @available(iOS, introduced: 14.0, deprecated: 17.0)
    @available(macOS, introduced: 11.0, deprecated: 14.0)
    @available(tvOS, introduced: 14.0, deprecated: 17.0)
    @available(watchOS, introduced: 7.0, deprecated: 10.0)
    @available(visionOS, unavailable)
    public func onChange<E: Equatable>(
        of value: E,
        initial: Bool = false,
        _ action: @escaping () -> Void
    ) -> some View {
        modifier(
            OnChangeModifier(
                value: value,
                initial: initial,
                action: .init(action)
            )
        )
    }
}

@available(iOS, introduced: 14.0, deprecated: 17.0)
@available(macOS, introduced: 11.0, deprecated: 14.0)
@available(tvOS, introduced: 14.0, deprecated: 17.0)
@available(watchOS, introduced: 7.0, deprecated: 10.0)
@available(visionOS, unavailable)
struct OnChangeModifier<E: Equatable>: ViewModifier {
    var value: E
    var initial: Bool
    
    struct ActionPack {
        var actionWithValues: ((E, E) -> Void)?
        var simpleAction: (() -> Void)?
        
        func callAsFunction(before: E, after: E) {
            if let actionWithValues {
                actionWithValues(before, after)
            } else if let simpleAction {
                simpleAction()
            }
        }
        
        init(_ action: @escaping (E, E) -> Void) {
            self.actionWithValues = action
            self.simpleAction = nil
        }
        
        init(_ action: @escaping () -> Void) {
            self.simpleAction = action
            self.actionWithValues = nil
        }
    }
    var action: ActionPack
    
    func body(content: Content) -> some View {
        if #available(macOS 14, iOS 17, tvOS 17, watchOS 10, *) {
            content
                .onChange(
                    of: value,
                    initial: initial,
                    action.callAsFunction(before:after:)
                )
        } else {
            content
                .onAppear(perform: initialAction)
                .onChange(of: value) { [value] newValue in
                    Task { @MainActor in
                        action(before: value, after: newValue)
                    }
                }
        }
    }
    
    private func initialAction() {
        guard initial else { return }
        action(before: value, after: value)
    }
}
