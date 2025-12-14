import SwiftUI

struct RatingControlView: View {
    let currentRating: Int
    let isEnabled: Bool
    let onRatingChanged: (Int) -> Void

    @State private var hoveredRating: Int?

    var body: some View {
        HStack(spacing: 4) {
            // Clear rating button
            Button {
                if isEnabled {
                    onRatingChanged(0)
                }
            } label: {
                Circle()
                    .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3]))
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)
            .opacity(currentRating == 0 ? 1.0 : 0.5)
            .help("Clear rating (0)")

            // Star buttons (1-5)
            ForEach(1...5, id: \.self) { rating in
                starButton(for: rating)
            }
        }
        .opacity(isEnabled ? 1.0 : 0.4)
    }

    @ViewBuilder
    private func starButton(for rating: Int) -> some View {
        let isFilled = rating <= (hoveredRating ?? currentRating)

        Button {
            if isEnabled {
                onRatingChanged(rating)
            }
        } label: {
            Image(systemName: isFilled ? "star.fill" : "star")
                .font(.system(size: 18))
                .foregroundColor(isFilled ? .yellow : .gray)
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            if isEnabled {
                hoveredRating = isHovering ? rating : nil
            }
        }
        .help("Rate \(rating) star\(rating == 1 ? "" : "s") (\(rating))")
    }
}

#Preview {
    VStack(spacing: 20) {
        RatingControlView(currentRating: 0, isEnabled: true) { rating in
            print("Rating: \(rating)")
        }

        RatingControlView(currentRating: 3, isEnabled: true) { rating in
            print("Rating: \(rating)")
        }

        RatingControlView(currentRating: 5, isEnabled: false) { rating in
            print("Rating: \(rating)")
        }
    }
    .padding()
    .background(Color.black)
}
