import SwiftUI

struct RatingColorHUDView: View {
    @EnvironmentObject var viewerVM: ImageViewerViewModel
    @EnvironmentObject var galleryVM: GalleryViewModel
    @EnvironmentObject var preferencesVM: PreferencesViewModel

    var body: some View {
        // Don't show HUD if all options are disabled
        if !preferencesVM.showRatingInHUD && !preferencesVM.showColorTagInHUD && !preferencesVM.showExifInHUD {
            return AnyView(EmptyView())
        }

        if let variant = viewerVM.currentVariant {
            return AnyView(
                HStack(spacing: 16) {
                    // RATE section
                    if preferencesVM.showRatingInHUD {
                        HStack(spacing: 8) {
                            Text("RATE")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(white: 0.7))
                                .tracking(0.5)

                            // Rating stars (compact)
                            HUDRatingView(
                                currentRating: variant.rating,
                                isEnabled: galleryVM.canSetRating
                            ) { rating in
                                viewerVM.setRating(rating)
                            }
                        }
                    }

                    // TAG section
                    if preferencesVM.showColorTagInHUD {
                        HStack(spacing: 8) {
                            Text("TAG")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(white: 0.7))
                                .tracking(0.5)

                            // Color tag dot
                            ColorTagDotView(
                                currentTag: variant.colorTag,
                                isEnabled: galleryVM.canSetColorTag
                            ) { tag in
                                viewerVM.setColorTag(tag)
                            }
                        }
                    }

                    // EXIF info
                    if preferencesVM.showExifInHUD && !variant.exifSummary.isEmpty {
                        Text(variant.exifSummary)
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.7))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.bar)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            )
        } else {
            return AnyView(EmptyView())
        }
    }
}

// MARK: - Compact HUD Rating View
struct HUDRatingView: View {
    let currentRating: Int
    let isEnabled: Bool
    let onRatingChanged: (Int) -> Void

    @State private var hoveredRating: Int?

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { rating in
                Button {
                    if isEnabled {
                        // Toggle: if clicking current rating, clear it
                        if rating == currentRating {
                            onRatingChanged(0)
                        } else {
                            onRatingChanged(rating)
                        }
                    }
                } label: {
                    Image(systemName: rating <= (hoveredRating ?? currentRating) ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundColor(rating <= (hoveredRating ?? currentRating) ? .yellow : Color(white: 0.4))
                }
                .buttonStyle(.plain)
                .onHover { isHovering in
                    if isEnabled {
                        hoveredRating = isHovering ? rating : nil
                    }
                }
            }
        }
        .opacity(isEnabled ? 1.0 : 0.4)
    }
}

// MARK: - Color Tag Dot View (shows current tag, opens popover on click)
struct ColorTagDotView: View {
    let currentTag: ColorTag
    let isEnabled: Bool
    let onTagChanged: (ColorTag) -> Void

    @State private var showPopover = false

    var body: some View {
        Button {
            if isEnabled {
                showPopover.toggle()
            }
        } label: {
            ZStack {
                if currentTag == .none {
                    Circle()
                        .stroke(Color(white: 0.4), lineWidth: 1)
                        .frame(width: 16, height: 16)
                } else {
                    Circle()
                        .fill(currentTag.color)
                        .frame(width: 16, height: 16)
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1.0 : 0.4)
        .popover(isPresented: $showPopover, arrowEdge: .top) {
            ColorTagPopoverView(
                currentTag: currentTag,
                onTagSelected: { tag in
                    onTagChanged(tag)
                    showPopover = false
                }
            )
        }
        .help("Color tag")
    }
}

// MARK: - Color Tag Popover View
struct ColorTagPopoverView: View {
    let currentTag: ColorTag
    let onTagSelected: (ColorTag) -> Void

    private let colors: [ColorTag] = [.red, .orange, .yellow, .green, .blue, .purple, .none]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(colors) { tag in
                Button {
                    onTagSelected(tag)
                } label: {
                    ZStack {
                        if tag == .none {
                            Circle()
                                .stroke(Color(white: 0.4), lineWidth: 1)
                                .frame(width: 20, height: 20)
                            if currentTag == .none {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        } else {
                            Circle()
                                .fill(tag.color)
                                .frame(width: 20, height: 20)
                            if currentTag == tag {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(white: 0.15))
    }
}


#Preview {
    RatingColorHUDView()
        .environmentObject(ImageViewerViewModel(client: CapturePilotClient(), imageCache: ImageCacheService()))
        .environmentObject(GalleryViewModel(client: CapturePilotClient(), imageCache: ImageCacheService()))
        .padding()
        .background(Color.black)
}
