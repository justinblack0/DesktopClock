import AppKit
import Combine

struct DisplayInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let frame: NSRect
    let isBuiltIn: Bool

    var displayName: String {
        if isBuiltIn {
            return "Built-in Display"
        }
        return name.isEmpty ? "External Display" : name
    }
}

class DisplayManager: ObservableObject {
    static let shared = DisplayManager()

    @Published var displays: [DisplayInfo] = []

    private var displayReconfigurationObserver: Any?

    private init() {
        updateDisplays()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    func updateDisplays() {
        displays = NSScreen.screens.enumerated().map { index, screen in
            let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            let isBuiltIn = CGDisplayIsBuiltin(screenNumber) != 0

            var name = ""
            if let displayName = screen.localizedName as String? {
                name = displayName
            }

            return DisplayInfo(
                id: "\(screenNumber)",
                name: name,
                frame: screen.frame,
                isBuiltIn: isBuiltIn
            )
        }
    }

    func getDisplay(byID id: String) -> DisplayInfo? {
        return displays.first { $0.id == id }
    }

    func getScreen(byID id: String) -> NSScreen? {
        for screen in NSScreen.screens {
            let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            if "\(screenNumber)" == id {
                return screen
            }
        }
        return nil
    }

    func moveWindow(_ window: NSWindow, toDisplay displayID: String) {
        guard let screen = getScreen(byID: displayID) else { return }

        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame

        // Center the window on the target display
        let newX = screenFrame.origin.x + (screenFrame.width - windowFrame.width) / 2
        let newY = screenFrame.origin.y + (screenFrame.height - windowFrame.height) / 2

        window.setFrameOrigin(NSPoint(x: newX, y: newY))
    }

    private func startMonitoring() {
        // Monitor for display configuration changes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateDisplays()
        }
    }

    private func stopMonitoring() {
        NotificationCenter.default.removeObserver(self)
    }
}
