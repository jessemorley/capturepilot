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
│   ├── GalleryViewModel.swift         # Image list + thumbnails
│   ├── ImageViewerViewModel.swift     # Current image state
│   └── PreferencesViewModel.swift     # User settings
├── Views/
│   ├── MainView.swift                 # Root view (state-based switching)
│   ├── PreferencesView.swift          # Settings window
│   ├── Connection/
│   │   └── ServerDiscoveryView.swift  # Server list/connection UI
│   ├── Gallery/
│   │   ├── GalleryView.swift          # Main gallery container
│   │   ├── ThumbnailStripView.swift   # Thumbnail item component
│   │   └── VerticalThumbnailStripView.swift  # Vertical film strip
│   ├── Viewer/
│   │   ├── ImageViewerView.swift      # Full-screen image display
│   │   └── ImageNavigationView.swift  # Left/right edge hotspots
│   └── Controls/
│       ├── RatingControlView.swift    # 5-star rating control
│       ├── ColorTagControlView.swift  # Color tag picker
│       └── RatingColorHUDView.swift   # Floating HUD overlay
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
┌────────────────────────────────────┬──────────┐
│  [Title Bar - ultraThinMaterial]   │ Folder   │
│  disconnect | name | position      │ N images │
│                                    ├──────────┤
│                                    │ Vertical │
│         [ImageViewerView]          │ Thumbnail│
│         Full-screen image          │ Strip    │
│                                    │          │
│     [ImageNavigationView]          │ (ultra   │
│     Left/right edge hotspots       │  Thin    │
│                                    │ Material)│
│     ┌─────────────────────┐        │          │
│     │ [RatingColorHUDView]│        │          │
│     │ EXIF|Auto|★★★|Colors│        │          │
│     └─────────────────────┘        │          │
└────────────────────────────────────┴──────────┘
```

### View Hierarchy

```
MainView (state-based switching)
├── .disconnected → ServerDiscoveryView
├── .connecting → ConnectionProgressView
├── .connected → GalleryView
│   ├── HStack
│   │   ├── ZStack (main content)
│   │   │   ├── ImageViewerView
│   │   │   └── ImageNavigationView
│   │   └── VerticalThumbnailStripView (right edge)
│   └── VStack (overlays)
│       ├── TitleBarView (top)
│       └── RatingColorHUDView (bottom center)
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
User clicks thumbnail / navigates
    ↓
ImageViewerViewModel.selectVariant(variant)
    └── Fetches full resolution image
    └── Updates currentImage & currentVariant
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

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| ← / → | Previous / Next image |
| Home / End | First / Last image |
| Space | Next image |
| 0-5 | Set rating (0 = clear) |
| - | Red color tag |
| + / = | Green color tag |
| * | Yellow color tag |

## UI Behaviors

- **Auto-hide controls**: Controls fade out after 3 seconds of inactivity
- **Hover to show**: Mouse movement shows controls
- **Lazy thumbnail loading**: Thumbnails load when scrolled into view
- **Scroll to selected**: Thumbnail strip auto-scrolls to current image
- **Material backgrounds**: Uses macOS vibrancy materials (`.ultraThinMaterial`, `.regularMaterial`)

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
