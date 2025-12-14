import SwiftUI

struct ColorTagControlView: View {
    let currentTag: ColorTag
    let isEnabled: Bool
    let onTagChanged: (ColorTag) -> Void

    @State private var isExpanded = false

    var body: some View {
        HStack(spacing: 4) {
            // Current tag button (toggles expansion)
            tagCircle(for: currentTag, isActive: true)
                .onTapGesture {
                    if isEnabled {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }
                }

            // Expanded options
            if isExpanded {
                ForEach(ColorTag.allCases.filter { $0 != currentTag }) { tag in
                    tagCircle(for: tag, isActive: false)
                        .onTapGesture {
                            onTagChanged(tag)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .opacity(isEnabled ? 1.0 : 0.4)
    }

    @ViewBuilder
    private func tagCircle(for tag: ColorTag, isActive: Bool) -> some View {
        ZStack {
            if tag == .none {
                Circle()
                    .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3]))
                    .frame(width: 24, height: 24)
            } else {
                Circle()
                    .fill(tag.color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(isActive ? 0.8 : 0.3), lineWidth: 1)
                    )
            }
        }
        .help(tag.name + (tag.keyboardShortcut.map { " (\($0))" } ?? ""))
    }
}

#Preview {
    VStack(spacing: 20) {
        ColorTagControlView(currentTag: .none, isEnabled: true) { tag in
            print("Tag: \(tag)")
        }

        ColorTagControlView(currentTag: .green, isEnabled: true) { tag in
            print("Tag: \(tag)")
        }

        ColorTagControlView(currentTag: .red, isEnabled: false) { tag in
            print("Tag: \(tag)")
        }
    }
    .padding()
    .background(Color.black)
}
