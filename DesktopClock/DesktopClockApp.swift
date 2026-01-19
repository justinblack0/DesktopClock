import SwiftUI
import AppKit

@main
struct DesktopClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var clockWindow: SnappingWindow?
    let settings = ClockSettings.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        createClockWindow()
    }

    func createClockWindow() {
        // Create the SwiftUI view
        let clockView = ClockView()

        // Create the hosting view
        let hostingView = NSHostingView(rootView: clockView)

        // Create the snapping window
        let window = SnappingWindow(
            contentRect: NSRect(
                x: settings.clockX,
                y: settings.clockY,
                width: settings.clockWidth,
                height: settings.clockHeight
            ),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Desktop Clock"
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 50, height: 30) // Very small minimum
        window.hasShadow = settings.showShadow

        // Make the window visible
        window.makeKeyAndOrderFront(nil)

        // Store reference
        clockWindow = window

        // Move to saved display if specified
        if !settings.selectedDisplayID.isEmpty {
            DisplayManager.shared.moveWindow(window, toDisplay: settings.selectedDisplayID)
        }

        // Observe window frame changes to save position/size
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.saveWindowFrame()
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.saveWindowFrame()
        }

        // Observe shadow setting changes
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clockWindow?.hasShadow = self?.settings.showShadow ?? false
        }
    }

    func saveWindowFrame() {
        guard let window = clockWindow else { return }
        let frame = window.frame
        settings.clockX = frame.origin.x
        settings.clockY = frame.origin.y
        settings.clockWidth = frame.width
        settings.clockHeight = frame.height
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// Custom window with snap-to-center functionality
class SnappingWindow: NSWindow {
    private let snapThreshold: CGFloat = 15.0

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        snapToCenter()
    }

    private func snapToCenter() {
        guard let screen = self.screen ?? NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let windowFrame = self.frame

        let screenCenterX = screenFrame.origin.x + screenFrame.width / 2
        let screenCenterY = screenFrame.origin.y + screenFrame.height / 2
        let windowCenterX = windowFrame.origin.x + windowFrame.width / 2
        let windowCenterY = windowFrame.origin.y + windowFrame.height / 2

        var snappedX = windowFrame.origin.x
        var snappedY = windowFrame.origin.y

        if abs(windowCenterX - screenCenterX) < snapThreshold {
            snappedX = screenCenterX - windowFrame.width / 2
        }
        if abs(windowCenterY - screenCenterY) < snapThreshold {
            snappedY = screenCenterY - windowFrame.height / 2
        }

        if snappedX != windowFrame.origin.x || snappedY != windowFrame.origin.y {
            self.setFrameOrigin(NSPoint(x: snappedX, y: snappedY))
        }
    }
}
