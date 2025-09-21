
import SwiftUI

struct LoadingOverlay: View {
    let isVisible: Bool
    var body: some View {
        Group {
            if isVisible {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    ProgressView()
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isVisible)
    }
}

#Preview { LoadingOverlay(isVisible: true) }
