import SwiftUI

extension View {
    @ViewBuilder
    func `if`(_ condition: @autoclosure @escaping () -> Bool, @ViewBuilder content: @escaping (_ content: Self) -> some View) -> some View {
        if condition() {
            content(self)
        } else {
            self
        }
    }
}
