import SwiftUI

extension AnyTransition {
    static var taskDropIn: AnyTransition { .asymmetric(insertion: .offset(y: -30).combined(with: .opacity), removal: .opacity) }
    static var slideIn: AnyTransition { .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)) }
}

extension View {
    @ViewBuilder func transparentScrolling() -> some View {
        if #available(macOS 13.0, *) { self.scrollContentBackground(.hidden) } else { self.background(Color.clear) }
    }
}
