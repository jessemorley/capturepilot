# CapturePilot Mac - Project Guide

## Overview

CapturePilot is a macOS companion app for Capture One that displays images from a connected Capture One session. It provides a full-screen image viewer with thumbnail navigation, rating, and color tagging capabilities.

## Tech Stack

- **Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Target**: macOS 14.0+
- **Window Style**: Hidden title bar (custom frameless window)
- **Theme**: Dark mode only

## Project Structure

```
CapturePilotMac/
├── CapturePilotMacApp.swift          # App entry point
├── Models/
│   ├── Variant.swift                  # Image/variant data model
│   ├── ColorTag.swift                 # Color tag enum (8 colors)
│   ├── ConnectionState.swift          # Connection state enum
│   ├── ServerResponse.swift           # API response models
│   └── CollectionProperties.swift     # Folder/permissions model
├── ViewModels/
│   ├── AppViewModel.swift             # Root state container
│   ├── ConnectionViewModel.swift      # Server discovery/auth
│   ├── GalleryViewModel.swift         # Image list + thumbnails + multi-select state
│   ├── ImageViewerViewModel.swift     # Current image state (syncs with active variant)
│   └── PreferencesViewModel.swift     # User settings
├── Views/
│   ├── MainView.swift                 # Root view (state-based switching)
│   ├── PreferencesView.swift          # Settings window
│   ├── Connection/
│   │   └── ServerDiscoveryView.swift  # Server list/connection UI
│   ├── Gallery/
│   │   ├── GalleryView.swift          # Main gallery container
│   │   │   ├── TopBarView             # Top bar with settings/selects/toggles
│   │   │   ├── SelectsButton          # Selects filter button
│   │   │   ├── NextCaptureToggle      # Auto-navigate toggle
│   │   │   └── SettingsModalView      # Settings modal
│   │   ├── ThumbnailStripView.swift   # Thumbnail item component
│   │   └── VerticalThumbnailStripView.swift  # Sidebar (right edge)
│   │       ├── SidebarView            # 180px sidebar container
│   │       ├── SidebarHeaderView      # FOLDER header with count
│   │       └── SidebarThumbnailView   # Thumbnail with filename label
│   ├── Viewer/
│   │   └── ImageViewerView.swift      # Single/multi image display
│   │       ├── MultiImageView         # Grid/flex layout for multi-select
│   │       └── MultiImageItemView     # Individual grid item
│   └── Controls/
│       ├── RatingControlView.swift    # 5-star rating control
│       ├── ColorTagControlView.swift  # Color tag picker
│       └── RatingColorHUDView.swift   # Compact HUD with RATE/TAG labels
│           ├── HUDRatingView          # Compact star rating
│           ├── ColorTagDotView        # Color dot with popover
│           └── ColorTagPopoverView    # Color picker popover
├── Networking/
│   ├── CapturePilotClient.swift       # API client for Capture One
│   ├── ServerDiscoveryService.swift   # Bonjour service discovery
│   ├── LongPollingService.swift       # Real-time updates
│   └── ImageCacheService.swift        # Image caching
├── Services/
│   └── SHA1Hasher.swift               # Password hashing
└── Extensions/
    └── NSImage+Base64.swift           # Image encoding
```

## Key Views & Layout

### Main Gallery Layout

```
┌────────────────────────────────────────────────────────────┐
│  [TopBarView - 64px height, #000000 background]            │
│  Settings | Capture Folder | Selects | Next Capture | ☰   │
├────────────────────────────────────┬───────────────────────┤
│                                    │ [SidebarView]         │
│                                    │ 180px, #050505        │
│                                    │ ┌─────────────────┐   │
│                                    │ │ FOLDER      [4] │   │
│         [ImageViewerView]          │ ├─────────────────┤   │
│         Full-screen image          │ │ □ Thumbnail     │   │
│         or Multi-image grid        │ │   filename.RAW  │   │
│                                    │ │ □ Thumbnail     │   │
│     ┌─────────────────────┐        │ │   filename.RAW  │   │
│     │ [RatingColorHUDView]│        │ │ ■ Active        │   │
│     │ RATE ★★★ TAG ● EXIF│        │ │   filename.RAW  │   │
│     └─────────────────────┘        │ └─────────────────┘   │
└────────────────────────────────────┴───────────────────────┘
```

### View Hierarchy

```
MainView (state-based switching)
├── .disconnected → ServerDiscoveryView
├── .connecting → ConnectionProgressView
├── .connected → GalleryView
│   ├── VStack
│   │   ├── TopBarView (64px height)
│   │   │   ├── Settings gear (left)
│   │   │   ├── Folder name (center)
│   │   │   └── Selects | Next Capture | Sidebar toggle (right)
│   │   └── HStack
│   │       ├── ZStack (main viewport)
│   │       │   ├── ImageViewerView
│   │       │   │   ├── Single image view
│   │       │   │   └── MultiImageView (2-3 flex, 4+ grid)
│   │       │   └── VStack
│   │       │       └── RatingColorHUDView (bottom center)
│   │       └── SidebarView (right edge, 180px)
│   │           ├── SidebarHeaderView (FOLDER + count)
│   │           └── ScrollView of thumbnails with labels
└── .error → ConnectionErrorView
```

## Data Flow

```
App Launch
    ↓
AppViewModel creates child ViewModels
    ↓
User connects to Capture One server
    ↓
GalleryViewModel.startPolling()
    └── LongPollingService fetches updates
    └── Publishes variants (image metadata)
    └── Lazy-loads thumbnails on demand
    ↓
User clicks thumbnail (or Cmd+Click for multi-select)
    ↓
GalleryViewModel.selectVariant(variant, isCommandPressed)
    ├── Single click: Sets selectedVariantIDs = [variant.id]
    └── Cmd+Click: Toggles variant in selectedVariantIDs
    ↓
ImageViewerViewModel observes activeVariantID changes
    ├── If multi-select (>1 selected): Shows MultiImageView grid
    └── If single select: Fetches full resolution image
```

## Key Data Models

### Variant
```swift
struct Variant: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    var rating: Int              // 0-5
    var colorTag: ColorTag       // enum
    var aperture: String
    var shutterSpeed: String
    var iso: String
    var focalLength: String
    var exifSummary: String      // Computed
    var displayName: String      // Computed
}
```

### ColorTag
```swift
enum ColorTag: Int, CaseIterable, Identifiable {
    case none = 0
    case red = 1
    case orange = 2
    case yellow = 3
    case green = 4
    case blue = 5
    case pink = 6
    case purple = 7
}
```

### CollectionProperties
```swift
struct CollectionProperties {
    var selectedFolder: String    // Current folder name
    var canSetRating: Bool        // Server permission
    var canSetColorTag: Bool      // Server permission
}
```

### GalleryViewModel Selection State
```swift
@Published var selectedVariantIDs: Set<UUID> = []  // All selected images
@Published var activeVariantID: UUID?              // Active image for editing

var displayedVariants: [Variant]  // Filtered by Selects if enabled
var selectsCount: Int             // Count of 3+ star images
var showSelectsOnly: Bool         // Filter to show only 3+ stars
```

## Multi-Select Functionality

- **Click** - Selects a single image (clears previous selection)
- **Cmd+Click** - Toggles image in multi-select (add/remove from selection)
- **Active vs Selected**: One image is always "active" (white border) for editing ratings/tags
- **Multi-image display**:
  - 1 image: Full viewport, object-fit contain
  - 2-3 images: Horizontal flex layout, fills height
  - 4+ images: Grid layout (2×2, 3×3, or 4×4), non-scrollable
- **Click image in grid**: Makes it the active image

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| ← / → | Previous / Next image (exits multi-select) |
| Home / End | First / Last image (exits multi-select) |
| Space | Next image (exits multi-select) |
| 0-5 | Set rating on active image (0 = clear) |
| S | Toggle "Selects" filter (3+ stars only) |
| - | Red color tag on active image |
| + / = | Green color tag on active image |
| * | Yellow color tag on active image |

## UI Behaviors & Design

- **Always-visible controls**: No auto-hide behavior
- **Lazy thumbnail loading**: Thumbnails load when scrolled into view
- **Scroll to active**: Sidebar auto-scrolls to active thumbnail
- **Square edges**: All images and thumbnails have 0px border radius
- **Dark theme**:
  - Main background: `#000000`
  - Sidebar background: `#050505`
  - Button background: `#1A1A1A`
  - Button hover: `#262626`
  - Borders: `rgba(255,255,255,0.1)` or `0.15`
- **Sidebar**: Fixed 180px width on right side with header and filename labels
- **HUD**: Compact bar with "RATE" and "TAG" labels, semi-transparent background
- **Visual feedback**:
  - Active thumbnail: White 2px border, full opacity
  - Selected thumbnail: White 50% opacity border
  - Hovered thumbnail: 95% opacity
  - Default thumbnail: 80% opacity

### Color Constants (GalleryView.swift)
```swift
extension Color {
    static let galleryBackground = Color(red: 0, green: 0, blue: 0)           // #000000
    static let sidebarBackground = Color(red: 5/255, green: 5/255, blue: 5/255) // #050505
    static let buttonBackground = Color(red: 26/255, green: 26/255, blue: 26/255) // #1A1A1A
    static let buttonHover = Color(red: 38/255, green: 38/255, blue: 38/255) // #262626
    static let borderSubtle = Color.white.opacity(0.1)
    static let borderLight = Color.white.opacity(0.15)
}
```

## API Integration

The app communicates with Capture One via HTTP:

- **Discovery**: Bonjour/mDNS service discovery
- **Authentication**: SHA1-based password hashing
- **Polling**: Long-polling for real-time updates
- **Endpoints**:
  - `/getProperty` - Fetch image/collection data
  - `/setProperty` - Update rating/color tag
  - `/getImage` - Fetch thumbnail/full image

## Preferences

Stored via `@AppStorage`:
- `thumbnailHeight` (Double, default: 80) - Thumbnail size
- `autoNavigateToNewImages` (Bool) - Auto-select new captures

## Adding New Files to Xcode Project

When creating new Swift files, they must be added to the Xcode project. The project file is at `CapturePilotMac.xcodeproj/project.pbxproj`. Files need:
1. A PBXFileReference entry
2. A PBXBuildFile entry
3. Addition to the appropriate group's children array
4. Addition to the Sources build phase
