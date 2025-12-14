import SwiftUI

struct ImageViewerView: View {
    @EnvironmentObject var viewerVM: ImageViewerViewModel
    @EnvironmentObject var galleryVM: GalleryViewModel

    private var selectedVariants: [Variant] {
        galleryVM.selectedVariantIDs.compactMap { id in
            galleryVM.variant(for: id)
        }
    }

    private var isMultiSelect: Bool {
        galleryVM.selectedVariantIDs.count > 1
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isMultiSelect {
                    // Multi-image grid view
                    MultiImageView(variants: selectedVariants)
                        .environmentObject(galleryVM)
                } else {
                    // Single image view
                    if let image = viewerVM.currentImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.opacity)
                    } else if viewerVM.isLoadingImage {
                        ProgressView()
                            .scaleEffect(1.5)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .animation(.easeInOut(duration: 0.2), value: viewerVM.currentVariant?.id)
        }
    }
}

// MARK: - Multi-Image View
struct MultiImageView: View {
    let variants: [Variant]
    @EnvironmentObject var galleryVM: GalleryViewModel

    var body: some View {
        GeometryReader { geometry in
            if variants.count <= 3 {
                // 2-3 images: Horizontal flex layout, images fill height
                HStack(spacing: 5) {
                    ForEach(variants) { variant in
                        MultiImageItemView(variant: variant)
                            .frame(maxHeight: .infinity)
                    }
                }
                .padding(5)
            } else {
                // 4+ images: Grid layout that fills the screen
                VStack(spacing: 5) {
                    ForEach(0..<gridRows, id: \.self) { row in
                        HStack(spacing: 5) {
                            ForEach(0..<gridColumns, id: \.self) { col in
                                let index = row * gridColumns + col
                                if index < variants.count {
                                    MultiImageItemView(variant: variants[index])
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else {
                                    // Empty spacer for incomplete last row
                                    Color.clear
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                        }
                    }
                }
                .padding(5)
            }
        }
    }

    // Calculate grid dimensions
    private var gridColumns: Int {
        let count = variants.count
        if count <= 4 { return 2 }
        if count <= 9 { return 3 }
        return 4
    }

    private var gridRows: Int {
        let cols = gridColumns
        return (variants.count + cols - 1) / cols  // Ceiling division
    }
}

// MARK: - Multi Image Item View (used in both flex and grid layouts)
struct MultiImageItemView: View {
    let variant: Variant
    @EnvironmentObject var galleryVM: GalleryViewModel
    @EnvironmentObject var viewerVM: ImageViewerViewModel
    @State private var image: NSImage?

    private var isActive: Bool {
        galleryVM.activeVariantID == variant.id
    }

    var body: some View {
        ZStack {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .fill(Color(white: 0.1))
                    .overlay(ProgressView())
            }
        }
        .clipShape(Rectangle()) // Square corners per mockup
        .overlay(
            Rectangle()
                .stroke(isActive ? Color.white : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            // Make this image the active one (without clearing multi-select)
            galleryVM.activeVariantID = variant.id
        }
        .onAppear {
            Task {
                self.image = await viewerVM.loadImage(for: variant)
            }
        }
    }
}

#Preview {
    let galleryVM = GalleryViewModel(client: CapturePilotClient(), imageCache: ImageCacheService())
    let viewerVM = ImageViewerViewModel(client: CapturePilotClient(), imageCache: ImageCacheService())
    
    // Simulate multi-select
    let variants = galleryVM.variants
    if variants.count > 1 {
        galleryVM.selectedVariantIDs = [variants[0].id, variants[1].id]
    }

    return ImageViewerView()
        .environmentObject(viewerVM)
        .environmentObject(galleryVM)
        .frame(width: 800, height: 600)
        .background(Color.black)
}
