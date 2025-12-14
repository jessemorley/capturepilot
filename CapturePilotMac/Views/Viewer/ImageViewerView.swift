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

    // Determine grid layout based on image count
    private var columns: [GridItem] {
        let count = variants.count
        if count <= 1 {
            return [GridItem(.flexible())]
        } else if count <= 4 {
            return Array(repeating: GridItem(.flexible()), count: 2)
        } else if count <= 9 {
            return Array(repeating: GridItem(.flexible()), count: 3)
        } else {
            return Array(repeating: GridItem(.flexible()), count: 4)
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(variants) { variant in
                    SingleGridItemView(variant: variant)
                }
            }
            .padding(5)
        }
    }
}

// MARK: - Single Grid Item View
struct SingleGridItemView: View {
    let variant: Variant
    @EnvironmentObject var galleryVM: GalleryViewModel
    @EnvironmentObject var viewerVM: ImageViewerViewModel
    @State private var image: NSImage?

    var body: some View {
        ZStack {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .layoutPriority(-1)
            } else {
                Rectangle()
                    .fill(Color(white: 0.1))
                    .overlay(ProgressView())
            }
        }
        .clipped()
        .aspectRatio(1, contentMode: .fit) // Square grid item
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
