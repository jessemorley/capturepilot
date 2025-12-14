import SwiftUI

struct ControlBarView: View {
    @EnvironmentObject var viewerVM: ImageViewerViewModel
    @EnvironmentObject var galleryVM: GalleryViewModel
    @EnvironmentObject var preferencesVM: PreferencesViewModel

    var body: some View {
        HStack(spacing: 20) {
            // EXIF Info
            if let variant = viewerVM.currentVariant, !variant.exifSummary.isEmpty {
                Text(variant.exifSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Auto-update toggle
            Toggle(isOn: $preferencesVM.autoNavigateToNewImages) {
                HStack(spacing: 4) {
                    Image(systemName: preferencesVM.autoNavigateToNewImages ? "arrow.triangle.2.circlepath" : "pause.circle")
                        .font(.caption)
                    Text("Auto")
                        .font(.caption)
                }
            }
            .toggleStyle(.button)
            .buttonStyle(.plain)
            .foregroundColor(preferencesVM.autoNavigateToNewImages ? .blue : .secondary)
            .help(preferencesVM.autoNavigateToNewImages ? "Auto-navigate to new images (ON)" : "Auto-navigate to new images (OFF)")

            Divider()
                .frame(height: 20)

            // Rating control
            if let variant = viewerVM.currentVariant {
                RatingControlView(
                    currentRating: variant.rating,
                    isEnabled: galleryVM.canSetRating
                ) { rating in
                    viewerVM.setRating(rating)
                }
            }

            Divider()
                .frame(height: 20)

            // Color tag control
            if let variant = viewerVM.currentVariant {
                ColorTagControlView(
                    currentTag: variant.colorTag,
                    isEnabled: galleryVM.canSetColorTag
                ) { tag in
                    viewerVM.setColorTag(tag)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.7))
    }
}

#Preview {
    ControlBarView()
        .environmentObject(ImageViewerViewModel(client: CapturePilotClient(), imageCache: ImageCacheService()))
        .environmentObject(GalleryViewModel(client: CapturePilotClient(), imageCache: ImageCacheService()))
        .environmentObject(PreferencesViewModel())
        .frame(width: 800)
        .background(Color.black)
}
