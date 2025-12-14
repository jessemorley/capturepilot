import SwiftUI

// MARK: - Color Constants
extension Color {
    static let galleryBackground = Color(red: 0, green: 0, blue: 0) // #000000
    static let sidebarBackground = Color(red: 5/255, green: 5/255, blue: 5/255) // #050505
    static let buttonBackground = Color(red: 26/255, green: 26/255, blue: 26/255) // #1A1A1A
    static let buttonHover = Color(red: 38/255, green: 38/255, blue: 38/255) // #262626
    static let borderSubtle = Color.white.opacity(0.1)
    static let borderLight = Color.white.opacity(0.15)
}

struct GalleryView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var galleryVM: GalleryViewModel
    @EnvironmentObject var viewerVM: ImageViewerViewModel
    @EnvironmentObject var preferencesVM: PreferencesViewModel

    @State private var showSidebar = true
    @State private var showSettings = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            TopBarView(
                showSidebar: $showSidebar,
                showSettings: $showSettings
            )
            .environmentObject(appVM)
            .environmentObject(galleryVM)
            .environmentObject(viewerVM)
            .environmentObject(preferencesVM)

            // Main content area
            HStack(spacing: 0) {
                // Main viewport (LEFT)
                ZStack {
                    Color.galleryBackground

                    if galleryVM.isEmpty {
                        EmptyCollectionView()
                    } else {
                        // Image viewer
                        ImageViewerView()
                            .environmentObject(viewerVM)
                            .environmentObject(galleryVM)

                        // HUD at bottom center
                        VStack {
                            Spacer()
                            RatingColorHUDView()
                                .environmentObject(viewerVM)
                                .environmentObject(galleryVM)
                                .padding(.bottom, 20)
                        }
                    }
                }

                // Sidebar (RIGHT)
                if showSidebar {
                    SidebarView()
                        .environmentObject(galleryVM)
                        .environmentObject(viewerVM)
                }
            }
        }
        .background(Color.galleryBackground)
        .focusable()
        .focused($isFocused)
        .onAppear {
            isFocused = true
        }
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
        }
        .sheet(isPresented: $showSettings) {
            SettingsModalView()
                .environmentObject(preferencesVM)
        }
    }

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        // Navigation
        switch keyPress.key {
        case .leftArrow:
            viewerVM.navigateToPrevious()
            return .handled
        case .rightArrow:
            viewerVM.navigateToNext()
            return .handled
        case .home:
            viewerVM.navigateToFirst()
            return .handled
        case .end:
            viewerVM.navigateToLast()
            return .handled
        case .space:
            viewerVM.navigateToNext()
            return .handled
        default:
            break
        }

        // Rating (0-5 keys)
        if let char = keyPress.characters.first {
            if let rating = Int(String(char)), rating >= 0 && rating <= 5 {
                viewerVM.setRating(rating)
                return .handled
            }

            // Color tag shortcuts
            switch char {
            case "-":
                viewerVM.setColorTag(.red)
                return .handled
            case "+", "=":
                viewerVM.setColorTag(.green)
                return .handled
            case "*":
                viewerVM.setColorTag(.yellow)
                return .handled
            case "s", "S":
                // Toggle Selects filter
                galleryVM.toggleSelectsFilter()
                return .handled
            default:
                break
            }
        }

        return .ignored
    }
}

struct EmptyCollectionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("No Images")
                .font(.title2)
                .foregroundColor(.gray)

            Text("Waiting for images from Capture One...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Top Bar View
struct TopBarView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var galleryVM: GalleryViewModel
    @EnvironmentObject var viewerVM: ImageViewerViewModel
    @EnvironmentObject var preferencesVM: PreferencesViewModel

    @Binding var showSidebar: Bool
    @Binding var showSettings: Bool

    var body: some View {
        HStack {
            // Left: Traffic lights spacer + Settings
            HStack {
                Spacer().frame(width: 70) // Spacer for traffic lights
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 120, alignment: .leading)

            Spacer()

            // Center: Title
            Text("Capture Folder")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            // Right: Controls
            HStack(spacing: 16) {
                SelectsButton(
                    isActive: galleryVM.showSelectsOnly,
                    selectsCount: galleryVM.selectsCount
                ) {
                    galleryVM.toggleSelectsFilter()
                }

                NextCaptureToggle(isOn: $preferencesVM.autoNavigateToNewImages)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSidebar.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.right")
                        .foregroundColor(showSidebar ? .white : .gray)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 220, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color.black)
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(Color.borderSubtle),
            alignment: .bottom
        )
    }
}

// MARK: - Selects Button
struct SelectsButton: View {
    let isActive: Bool
    let selectsCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "star")
                Text("Selects")
                Text("S")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .buttonStyle(PillButtonStyle(isActive: isActive))
    }
}

// MARK: - Next Capture Toggle
struct NextCaptureToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "camera")
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
        }
    }
}

// MARK: - Pill Button Style
struct PillButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundColor(isActive ? .black : .white)
            .background(
                Capsule().fill(isActive ? .white : Color.buttonBackground)
            )
            .overlay(
                Capsule().stroke(Color.borderSubtle, lineWidth: 1)
            )
    }
}

// MARK: - Settings Modal View
struct SettingsModalView: View {
    @EnvironmentObject var preferencesVM: PreferencesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(white: 0.1))

            // Content
            Form {
                Section("Display") {
                    Picker("Thumbnail Size", selection: $preferencesVM.thumbnailHeight) {
                        Text("Small").tag(60.0)
                        Text("Medium").tag(80.0)
                        Text("Large").tag(100.0)
                    }

                    Toggle("Auto-navigate to new images", isOn: $preferencesVM.autoNavigateToNewImages)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .frame(width: 350, height: 250)
        .background(Color(white: 0.15))
    }
}

#Preview {
    GalleryView()
        .environmentObject(AppViewModel())
        .environmentObject(GalleryViewModel(client: CapturePilotClient(), imageCache: ImageCacheService()))
        .environmentObject(ImageViewerViewModel(client: CapturePilotClient(), imageCache: ImageCacheService()))
        .environmentObject(PreferencesViewModel())
        .frame(width: 1200, height: 800)
}
