import SwiftUI

struct ThumbnailStripView: View {
    @EnvironmentObject var galleryVM: GalleryViewModel
    @EnvironmentObject var viewerVM: ImageViewerViewModel
    @EnvironmentObject var preferencesVM: PreferencesViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 4) {
                    ForEach(galleryVM.variants) { variant in
                        ThumbnailItemView(
                            variant: variant,
                            thumbnail: galleryVM.thumbnails[variant.id],
                            isSelected: viewerVM.currentVariant?.id == variant.id,
                            height: preferencesVM.thumbnailHeight
                        )
                        .environmentObject(galleryVM)
                        .id(variant.id)
                        .onTapGesture {
                            viewerVM.selectVariant(variant)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .frame(height: preferencesVM.thumbnailHeight + 16)
            .background(Color.black.opacity(0.85))
            .onChange(of: viewerVM.currentVariant?.id) { _, newID in
                if let id = newID {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }
}

struct ThumbnailItemView: View {
    let variant: Variant
    let thumbnail: NSImage?
    let isSelected: Bool
    let height: Double

    @State private var isHovered = false
    @EnvironmentObject var galleryVM: GalleryViewModel

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Thumbnail image
            Group {
                if let thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(Color(white: 0.15))
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                }
            }
            .frame(height: height)

            // Rating dots
            if variant.rating > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<variant.rating, id: \.self) { _ in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(4)
            }

            // Color tag indicator (top right)
            VStack {
                HStack {
                    Spacer()
                    if variant.colorTag != .none {
                        Circle()
                            .fill(variant.colorTag.color)
                            .frame(width: 8, height: 8)
                            .padding(4)
                    }
                }
                Spacer()
            }
        }
        // Square corners (0px radius) per mockup
        .clipShape(Rectangle())
        .overlay(
            Rectangle()
                .stroke(
                    isSelected ? Color.white : (isHovered ? Color.white.opacity(0.5) : Color.clear),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .opacity(isSelected ? 1.0 : (isHovered ? 0.9 : 0.7))
        .animation(.easeInOut(duration: 0.1), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            // Lazy load thumbnail when it appears
            galleryVM.loadThumbnail(for: variant)
        }
    }
}

#Preview {
    ThumbnailStripView()
        .environmentObject(GalleryViewModel(client: CapturePilotClient(), imageCache: ImageCacheService()))
        .environmentObject(ImageViewerViewModel(client: CapturePilotClient(), imageCache: ImageCacheService()))
        .environmentObject(PreferencesViewModel())
        .frame(width: 800, height: 100)
        .background(Color.black)
}
