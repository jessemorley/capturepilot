import SwiftUI

struct ImageNavigationView: View {
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Previous button (left edge)
            NavigationHotspot(
                systemImage: "chevron.left",
                action: onPrevious
            )

            Spacer()

            // Next button (right edge)
            NavigationHotspot(
                systemImage: "chevron.right",
                action: onNext
            )
        }
    }
}

struct NavigationHotspot: View {
    let systemImage: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Hotspot area
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 80)

                // Icon (only visible on hover)
                if isHovered {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 50, height: 50)

                        Image(systemName: systemImage)
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .transition(.opacity)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    ImageNavigationView(
        onPrevious: { print("Previous") },
        onNext: { print("Next") }
    )
    .frame(width: 800, height: 600)
    .background(Color.black)
}
