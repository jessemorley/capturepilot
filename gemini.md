# Project Understanding: Capture Pilot (macOS Client)

This document summarizes the Capture Pilot macOS application, its design principles, and the recent modifications implemented.

## 1. Project Overview

Capture Pilot is a native macOS application built with Swift and SwiftUI, serving as a client-facing viewer for monitoring incoming images from a Capture One session over a local network.

**Core Functionalities:**
*   View images in real-time as they are captured.
*   Rate images (1-5 stars).
*   Apply color tags.
*   Filter to show "Selects" (3+ stars).
*   **New:** Multiple image selection.

## 2. Design & UI/UX Requirements (Mockup Style)

The application adheres to an ultra-dark, "Pro" macOS aesthetic, prioritizing a clean, technical, and precise look.

**Key Aesthetic Principles:**
*   **Theme:** Ultra-dark, with deep blacks for main views (`#000000`) and slightly lighter darks for sidebars (`#050505`).
*   **Borders:** Subtle 1px borders (e.g., `rgba(255,255,255,0.1)`).
*   **Geometry:**
    *   **Square Edges:** Images and selection highlights feature 0px border radius.
    *   **Rounded Corners:** UI elements like buttons and the HUD use rounded corners (pill shapes or rounded-xl) for contrast.
*   **Typography:** Native macOS font (SF Pro), generally lighter weights, high contrast text.

**Layout Components:**
*   **Top Bar (h-56):**
    *   Left: Traffic lights (macOS controls), Settings button (gear icon).
    *   Center: "Capture Folder" title.
    *   Right: "Selects" button (pill shape, icon + text + "S" shortcut badge), "Next Capture" toggle (camera icon + switch), Sidebar toggle (sidebar.right icon).
*   **Sidebar (Right, w-180):**
    *   Single column of vertical thumbnails.
    *   Background: `#050505`.
    *   Border Left: 1px solid white/15.
    *   Thumbnails: 2:3 Portrait aspect ratio, square edges.
*   **Main Viewport:**
    *   **Single Image Mode:** Image fills the view, `object-contain`.
    *   **Multi-Image Mode:**
        *   2-3 Images: Flexbox-like layout, 100% height, auto width, centered to maximize size without cropping.
        *   4+ Images: CSS Grid layout (2x2, 3x2, etc.).
    *   Padding: Minimal (5px or 10px).
*   **Heads-Up Display (HUD):**
    *   Floating pill at the bottom center of the Main View.
    *   Row 1: Current Image Filename.
    *   Row 2: Rating (5 Star icons), Color Tag (single dot, opens popover), EXIF (ISO, Shutter, Aperture - ghosted text).

## 3. Interaction Logic

*   **Selection:**
    *   Click: Selects a single image.
    *   Cmd/Ctrl + Click: Adds/removes an image from the selection (multi-select).
    *   **Active vs. Selected:** In multi-view, one image is "Active" (highlighted with a white border) for editing, while others are "Selected" for viewing.
*   **Synchronized View:** Selecting an image in the Main View (or a thumbnail) scrolls the Sidebar to reveal that image.
*   **"Selects" Mode:** Filters the view to show all images with 3 stars or higher in the multi-view grid.
*   **Next Capture Toggle:** When on, incoming images automatically take focus.

## 4. Technical Architecture

*   **Framework:** SwiftUI
*   **Architecture:** MVVM (Model-View-ViewModel)
*   **Key ViewModels:**
    *   `AppViewModel`: Root state container, orchestrates child ViewModels.
    *   `ConnectionViewModel`: Handles server discovery and authentication.
    *   `GalleryViewModel`: Manages the list of image variants, thumbnails, selection state (`selectedVariantIDs`, `activeVariantID`), and communicates with the server for updates.
    *   `ImageViewerViewModel`: Manages the currently viewed image (or images in multi-select).
    *   `PreferencesViewModel`: Manages user settings.
*   **Networking/Services:** `CapturePilotClient`, `ServerDiscoveryService`, `LongPollingService` (for real-time updates), `ImageCacheService`, `SHA1Hasher`.

## 5. Implemented Changes

During this session, the following features and refactorings were implemented to align with the project brief and mockup:

*   **Multi-Image Selection:**
    *   `GalleryViewModel.swift`: Added `@Published var selectedVariantIDs: Set<UUID>` and `@Published var activeVariantID: UUID?` to manage multiple selections. Implemented `func selectVariant(_ variant: Variant, isCommandPressed: Bool)` to handle single and command-click selections.
    *   `VerticalThumbnailStripView.swift`: Modified `SidebarThumbnailView` to visually indicate selected/active states with borders and updated its `onTapGesture` to use the new `galleryVM.selectVariant` method, detecting `Command` key presses.
    *   `ImageViewerView.swift`: Transformed to display images in a grid (`MultiImageView` with `LazyVGrid`) when multiple images are selected. `SingleGridItemView` was introduced to display individual images within this grid, loading them via `ImageViewerViewModel`.
    *   `ImageViewerViewModel.swift`: Added `func loadImage(for variant: Variant) async -> NSImage?` to allow individual image loading for grid items.
    *   `GalleryView.swift`: Updated to pass `galleryVM` to `ImageViewerView` and dynamically switch between single and multi-image display modes.
*   **UI Refactoring (based on Mockup):**
    *   `GalleryView.swift`: Sidebar was correctly positioned on the right as per the mockup. The sidebar toggle animation was removed.
    *   `TopBarView` (within `GalleryView.swift`): Refactored height, background, title, and right-hand controls to match the mockup's dark theme and layout.
    *   `SelectsButton` (within `GalleryView.swift`): Restyled to a pill shape with a white border and the "S" key shortcut badge.
    *   `NextCaptureToggle` (within `GalleryView.swift`): Replaced custom toggle with a standard `Toggle` with a switch style.
    *   `TopBarButtonStyle` was removed, with styles applied directly to buttons.
    *   `RatingColorHUDView.swift`: Refactored to match the floating pill shape and include the filename prominently.
