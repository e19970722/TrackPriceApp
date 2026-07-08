import SwiftUI

extension View {
    /// Standard chrome for a Ripe modal-flow screen: app background + inline
    /// nav title + a leading action button. Host inside a NavigationStack.
    func ripeFlowScreen(
        title: String,
        leadingTitle: String,
        leadingDisabled: Bool = false,
        onLeading: @escaping () -> Void
    ) -> some View {
        modifier(RipeFlowScreen(
            title: title,
            leadingTitle: leadingTitle,
            leadingDisabled: leadingDisabled,
            onLeading: onLeading
        ))
    }
}

private struct RipeFlowScreen: ViewModifier {
    let title: String
    let leadingTitle: String
    let leadingDisabled: Bool
    let onLeading: () -> Void

    func body(content: Content) -> some View {
        content
            .background(Color(.ripeBg).ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(leadingTitle, action: onLeading)
                        .disabled(leadingDisabled)
                }
            }
    }
}
