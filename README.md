# Capture Pilot Mac

A native macOS app for remote image viewing and rating with Capture One Pro.

## Features

- **Bonjour Discovery** - Automatically discovers Capture One servers on your network
- **Real-time Updates** - See new captures instantly via long-polling
- **Multi-Select** - Select multiple images with Cmd+Click for comparison
- **Image Navigation** - Arrow keys, Space, Home/End, or click thumbnails
- **Rating System** - Rate 0-5 stars with keyboard (0-5 keys) or UI
- **Color Tags** - Apply all 8 Capture One color tags (-, +, * shortcuts)
- **Selects Filter** - Toggle view of 3+ star images only (S key)
- **Auto-Update Toggle** - Auto-navigate to new images (default ON)
- **Sidebar Thumbnails** - Vertical thumbnail strip with filenames
- **Always-Visible HUD** - Compact rating, color tag, and EXIF display
- **Dark Mode** - Native dark theme throughout

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Capture One Pro with Capture Pilot enabled

## Building

1. Open the project in Xcode:
   ```bash
   open CapturePilotMac.xcodeproj
   ```

2. Update the bundle identifier in project settings (replace `com.example.CapturePilotMac`)

3. Configure signing in the Signing & Capabilities tab

4. Build and run (⌘R)

## Usage

### Connecting

1. Launch the app
2. It will auto-discover Capture One servers via Bonjour
3. Click a discovered server to connect
4. Or use "Enter address manually" for manual connection

### Keyboard Shortcuts

#### Navigation
- `←` / `→` - Previous/Next image (exits multi-select)
- `Space` - Next image (exits multi-select)
- `Home` / `End` - First/Last image (exits multi-select)

#### Rating
- `0` - Clear rating
- `1-5` - Set rating (1-5 stars)

#### Color Tags
- `-` - Red tag
- `+` / `=` - Green tag
- `*` - Yellow tag

#### Filters
- `S` - Toggle "Selects" filter (3+ stars only)

### UI Controls

- **Selects Button** - Filter to show only 3+ star images
- **Auto Toggle** - Enable/disable auto-navigation to new images
- **Sidebar Toggle** - Show/hide thumbnail sidebar (☰ button)
- **Rating Stars** - Click to rate 0-5 stars
- **Color Tag Dot** - Click to expand color tag picker
- **Thumbnails** - Click to view, Cmd+Click to multi-select
- **Multi-Image Grid** - Click any image to make it active for rating/tagging

## Architecture

### SwiftUI + MVVM

```
Models/           # Data types (Variant, ColorTag, ServerResponse)
ViewModels/       # Observable view models (App, Connection, Gallery, Viewer)
Views/            # SwiftUI views (Connection, Gallery, Viewer, Controls)
Networking/       # HTTP client, Bonjour discovery, long-polling, caching
Services/         # SHA1 hashing
Extensions/       # NSImage base64 decoding
```

### Protocol

The app uses Capture One's HTTP-based Capture Pilot protocol:

- **Connection**: POST to `connectToService?protocolVersion=2.4`
- **Long-polling**: GET `getServerChanges` for real-time updates
- **Images**: GET `getImage` returns base64 JPEG
- **Metadata**: GET `setProperty` for rating/color tag updates

## Troubleshooting

### Can't find servers

1. Ensure Capture One is running
2. Enable Capture Pilot in Capture One → Preferences → Capture
3. Check firewall settings (allow incoming connections)
4. Try manual connection with IP address and port (default 52505)

### Authentication failed

Enter the password configured in Capture One's Capture Pilot preferences.

### Images not loading

- Check network connection
- Verify Capture One session is active
- Try disconnecting and reconnecting

## License

This is an unofficial client for Capture One Pro. Capture One and Capture Pilot are trademarks of Capture One A/S.
