import SwiftUI

// MARK: - Sidebar View (Right sidebar with thumbnails)
struct SidebarView: View {
    @EnvironmentObject var galleryVM: GalleryViewModel
    @EnvironmentObject var viewerVM: ImageViewerViewModel

    // Wider sidebar to accommodate labels
    private let sidebarWidth: CGFloat = 180

    var body: some View {
        VStack(spacing: 0) {
            // Header: "FOLDER" with count badge
            SidebarHeaderView(
                folderName: "FOLDER",
                imageCount: galleryVM.displayedVariants.count
            )

            // Thumbnails scroll area
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(galleryVM.displayedVariants) { variant in
                            SidebarThumbnailView(
                                variant: variant,
                                thumbnail: galleryVM.thumbnails[variant.id]
                            )
                            .environmentObject(galleryVM)
                            .id(variant.id)
                            .onTapGesture {
                                // Check if Command key is pressed
                                let isCommandPressed = NSEvent.modifierFlags.contains(.command)
                                galleryVM.selectVariant(variant, isCommandPressed: isCommandPressed)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onChange(of: galleryVM.activeVariantID) { _, newID in
                    if let id = newID {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(width: sidebarWidth)
        .background(Color.sidebarBackground)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.borderLight)
                .frame(width: 1)
        }
    }
}

// MARK: - Sidebar Header View
struct SidebarHeaderView: View {
    let folderName: String
    let imageCount: Int

    var body: some View {
        HStack {
            Text(folderName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(white: 0.5))
                .tracking(0.5)

            Spacer()

            // Count badge
            Text("\(imageCount)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(white: 0.5))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 1)
        }
    }
}

// MARK: - Sidebar Thumbnail View (with filename label)
struct SidebarThumbnailView: View {
    let variant: Variant
    let thumbnail: NSImage?
    
    @EnvironmentObject var galleryVM: GalleryViewModel
    @State private var isHovered = false

    // Computed properties for selection state
    private var isSelected: Bool {
        galleryVM.selectedVariantIDs.contains(variant.id)
    }
    
    private var isActive: Bool {
        galleryVM.activeVariantID == variant.id
    }

    // 2:3 portrait aspect ratio
    private let aspectRatio: CGFloat = 2.0 / 3.0

    var body: some View {
        VStack(spacing: 6) {
            // Thumbnail image
            ZStack(alignment: .topTrailing) {
                // Thumbnail image with 2:3 aspect ratio
                Group {
                    if let thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color(white: 0.15))
                            .overlay {
                                ProgressView()
                                    .scaleEffect(0.5)
                            }
                    }
                }
                .aspectRatio(aspectRatio, contentMode: .fit)
                .clipped()

                // Color tag indicator (top right)
                if variant.colorTag != .none {
                    Circle()
                        .fill(variant.colorTag.color)
                        .frame(width: 8, height: 8)
                        .padding(6)
                }

                // Rating indicator (bottom left)
                if variant.rating > 0 {
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 1) {
                                ForEach(0..<variant.rating, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 4, height: 4)
                                }
                            }
                            .padding(4)
                            Spacer()
                        }
                    }
                }
            }
            // Square corners (0px radius) per mockup
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(
                        isActive ? Color.white : (isSelected ? Color.white.opacity(0.5) : Color.clear),
                        lineWidth: isActive ? 2 : 1
                    )
            )

            // Filename label
            Text(variant.displayName)
                .font(.system(size: 10))
                .foregroundColor(isSelected ? .white : Color(white: 0.6))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .opacity(isSelected ? 1.0 : (isHovered ? 0.95 : 0.8))
        .animation(.easeInOut(duration: 0.1), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            galleryVM.loadThumbnail(for: variant)
        }
    }
}

// MARK: - Keep old name for compatibility during transition
struct VerticalThumbnailStripView: View {
    @EnvironmentObject var galleryVM: GalleryViewModel
    @EnvironmentObject var viewerVM: ImageViewerViewModel
    @EnvironmentObject var preferencesVM: PreferencesViewModel

    var body: some View {
        SidebarView()
            .environmentObject(galleryVM)
            .environmentObject(viewerVM)
    }
}

#Preview {
    SidebarView()
        .environmentObject(GalleryViewModel(client: CapturePilotClient(), imageCache: ImageCacheService()))
        .environmentObject(ImageViewerViewModel(client: CapturePilotClient(), imageCache: ImageCacheService()))
        .frame(height: 600)
        .background(Color.black)
}
