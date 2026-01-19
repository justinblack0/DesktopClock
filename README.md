# Desktop Clock

A lightweight macOS app that displays a customizable floating digital clock on your desktop.

## Features

- **Floating window** - Borderless, transparent, always-on-top clock display
- **Multi-display support** - Move clock to any connected display
- **Draggable & resizable** - Position and size the clock anywhere
- **Snap-to-center** - Automatically snaps to screen center when dragging near it
- **Customizable appearance**:
  - Text and background colors
  - Optional border with adjustable color, width, and corner radius
  - Window opacity control
  - Any installed system font
- **Flexible time format**:
  - 12-hour or 24-hour display
  - Show/hide seconds
  - Show/hide AM/PM indicator (with case control)
  - Optional date display with custom format
- **Pulse animation** - Optional subtle animation on each second tick
- **Persistent settings** - All preferences saved automatically via UserDefaults
- **Right-click context menu** - Access settings, display switching, and quit

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for building)

## Building

1. Open `DesktopClock.xcodeproj` in Xcode
2. Select your development team (or leave unsigned for local use)
3. Build and run (⌘R)

The app runs as an agent (no Dock icon) and displays the clock immediately on launch.

## Usage

- **Move**: Click and drag the clock window
- **Resize**: Drag the window edges/corners
- **Settings**: Right-click the clock → "Settings..."
- **Change display**: Right-click → "Move to Display" → select display
- **Quit**: Right-click → "Quit"

## Architecture

```
DesktopClock/
├── DesktopClockApp.swift      # App entry, window setup, AppDelegate
├── Models/
│   └── ClockSettings.swift    # Settings model with @AppStorage persistence
├── Views/
│   ├── ClockView.swift        # Main clock display and timer logic
│   └── SettingsView.swift     # Settings panel UI
├── Utilities/
│   └── DisplayManager.swift   # Multi-display enumeration and management
└── Assets.xcassets/           # App icon
```

### Key Components

#### DesktopClockApp.swift

- **`DesktopClockApp`**: App entry point using SwiftUI App protocol
- **`AppDelegate`**: Creates and configures the clock window, handles frame persistence
- **`SnappingWindow`**: Custom NSWindow subclass that snaps to screen center when dragged within 15pt threshold

#### ClockSettings.swift

Singleton settings model using `@AppStorage` for automatic UserDefaults persistence.

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `selectedDisplayID` | String | "" | Target display identifier |
| `clockX`, `clockY` | Double | 100 | Window position |
| `clockWidth`, `clockHeight` | Double | 400, 150 | Window size |
| `foregroundColorHex` | String | "#FFFFFF" | Text color |
| `backgroundColorHex` | String | "#000000" | Background color |
| `borderColorHex` | String | "#FFFFFF" | Border color |
| `showBorder` | Bool | false | Show border |
| `borderWidth` | Double | 2 | Border thickness |
| `cornerRadius` | Double | 12 | Corner radius |
| `showShadow` | Bool | false | Window shadow |
| `fontName` | String | "Menlo" | Font family |
| `windowOpacity` | Double | 0.9 | Background opacity |
| `use24Hour` | Bool | false | 24-hour format |
| `showSeconds` | Bool | true | Display seconds |
| `showAMPM` | Bool | true | Show AM/PM |
| `uppercaseAMPM` | Bool | true | Uppercase AM/PM |
| `showDate` | Bool | false | Show date |
| `dateFormat` | String | "EEEE, MMMM d" | Date format string |
| `animationEnabled` | Bool | false | Pulse animation |

Includes `Color` extension for hex string conversion.

#### ClockView.swift

Main clock display view with:

- **`CachedFormatters`**: Singleton that caches DateFormatter instances to avoid recreation on every tick
- **Timer management**: Updates every 1 second when showing seconds, every 60 seconds otherwise
- **Auto-scaling font**: Calculates optimal font size based on window dimensions
- **Context menu**: Right-click menu for settings, display switching, quit
- **`SettingsWindowController`**: Manages settings window lifecycle, positions above clock window

#### DisplayManager.swift

Handles multi-display support:

- **`DisplayInfo`**: Struct representing a connected display
- **`DisplayManager`**: Singleton that enumerates displays, monitors connect/disconnect events
- **`moveWindow(_:toDisplay:)`**: Centers window on specified display

### Window Configuration

The clock window is configured as:

```swift
styleMask: [.borderless, .resizable]
level: .floating                    // Always on top
collectionBehavior: [.canJoinAllSpaces, .stationary]  // Visible on all spaces
isMovableByWindowBackground: true   // Draggable anywhere
isOpaque: false                     // Transparent background
```

### Performance Optimizations

- **Cached DateFormatters**: Avoids expensive formatter creation on each tick
- **Adaptive timer interval**: 1s with seconds shown, 60s without
- **Minimal view updates**: Only redraws on timer fire or setting change

## Customization

### Adding New Settings

1. Add `@AppStorage` property to `ClockSettings.swift`
2. Add UI control in `SettingsView.swift`
3. Use setting in `ClockView.swift`

### Changing Default Values

Edit the default values in `ClockSettings.swift` `@AppStorage` declarations.

### Custom Fonts

The settings panel includes common fonts plus a custom font field. Enter any installed font family name (e.g., "SF Pro", "Fira Code").

## License

MIT License
