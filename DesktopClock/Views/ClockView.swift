import SwiftUI

// Cached formatters to avoid recreating on every tick
private final class CachedFormatters {
    static let shared = CachedFormatters()

    private var timeFormatter: DateFormatter?
    private var lastTimeFormatKey: String = ""

    private var dateFormatter: DateFormatter?
    private var lastDateFormat: String = ""

    func timeFormatter(use24Hour: Bool, showSeconds: Bool, showAMPM: Bool, uppercaseAMPM: Bool) -> DateFormatter {
        // Build format string
        var format: String
        if use24Hour {
            format = showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            format = showSeconds ? "h:mm:ss" : "h:mm"
            if showAMPM {
                format += " a"
            }
        }

        // Create cache key
        let cacheKey = "\(format)_\(uppercaseAMPM)"

        if cacheKey != lastTimeFormatKey || timeFormatter == nil {
            let f = DateFormatter()
            f.dateFormat = format

            // Set AM/PM symbols for case control
            if !use24Hour && showAMPM {
                if uppercaseAMPM {
                    f.amSymbol = "AM"
                    f.pmSymbol = "PM"
                } else {
                    f.amSymbol = "am"
                    f.pmSymbol = "pm"
                }
            }

            timeFormatter = f
            lastTimeFormatKey = cacheKey
        }

        return timeFormatter!
    }

    func dateFormatter(format: String) -> DateFormatter {
        if format != lastDateFormat || dateFormatter == nil {
            let f = DateFormatter()
            f.dateFormat = format
            dateFormatter = f
            lastDateFormat = format
        }
        return dateFormatter!
    }

    private init() {}
}

struct ClockView: View {
    @ObservedObject var settings = ClockSettings.shared
    @ObservedObject var displayManager = DisplayManager.shared
    @State private var currentTime = Date()
    @State private var animationScale: CGFloat = 1.0
    @State private var timeString: String = ""
    @State private var dateString: String = ""
    @State private var timer: Timer?
    @State private var lastMinute: Int = -1

    // Calculate font size based on window dimensions
    func calculateFontSize(for size: CGSize, charCount: Int) -> CGFloat {
        let verticalFactor: CGFloat = settings.showDate ? 0.55 : 0.7
        let heightBasedSize = size.height * verticalFactor
        let widthBasedSize = (size.width * 0.9) / (CGFloat(charCount) * 0.6)
        return min(heightBasedSize, widthBasedSize)
    }

    private func updateTimeStrings() {
        let formatters = CachedFormatters.shared
        let formatter = formatters.timeFormatter(
            use24Hour: settings.use24Hour,
            showSeconds: settings.showSeconds,
            showAMPM: settings.showAMPM,
            uppercaseAMPM: settings.uppercaseAMPM
        )
        timeString = formatter.string(from: currentTime)

        if settings.showDate {
            let dateFormatter = formatters.dateFormatter(format: settings.dateFormat)
            dateString = dateFormatter.string(from: currentTime)
        }
    }

    private func startTimer() {
        timer?.invalidate()

        // Update every second if showing seconds, otherwise every minute
        let interval: TimeInterval = settings.showSeconds ? 1.0 : 60.0

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            timerFired()
        }

        // Also fire immediately to sync up
        timerFired()
    }

    private func timerFired() {
        currentTime = Date()
        updateTimeStrings()

        // Pulse animation (only when showing seconds)
        if settings.animationEnabled && settings.showSeconds {
            withAnimation(.easeInOut(duration: 0.15)) {
                animationScale = 1.02
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    animationScale = 1.0
                }
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let fontSize = calculateFontSize(for: geometry.size, charCount: timeString.count)

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: settings.cornerRadius, style: .continuous)
                    .fill(settings.backgroundColor)
                    .opacity(settings.windowOpacity)

                // Border (drawn separately for cleaner rendering)
                if settings.showBorder {
                    RoundedRectangle(cornerRadius: settings.cornerRadius, style: .continuous)
                        .strokeBorder(settings.borderColor, lineWidth: settings.borderWidth)
                }

                VStack(spacing: fontSize * 0.05) {
                    // Time display
                    Text(timeString)
                        .font(.custom(settings.fontName, size: fontSize))
                        .foregroundColor(settings.foregroundColor)
                        .scaleEffect(animationScale)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)

                    // Date display (optional)
                    if settings.showDate {
                        Text(dateString)
                            .font(.custom(settings.fontName, size: fontSize * 0.3))
                            .foregroundColor(settings.foregroundColor.opacity(0.8))
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: settings.showSeconds) { _ in
            startTimer()  // Restart timer with new interval
        }
        .onChange(of: settings.use24Hour) { _ in
            updateTimeStrings()
        }
        .onChange(of: settings.showAMPM) { _ in
            updateTimeStrings()
        }
        .onChange(of: settings.uppercaseAMPM) { _ in
            updateTimeStrings()
        }
        .onChange(of: settings.showDate) { _ in
            updateTimeStrings()
        }
        .onChange(of: settings.dateFormat) { _ in
            updateTimeStrings()
        }
        .contextMenu {
            Button("Settings...") {
                SettingsWindowController.shared.showSettings()
            }

            Divider()

            Menu("Move to Display") {
                ForEach(displayManager.displays) { display in
                    Button(display.displayName) {
                        settings.selectedDisplayID = display.id
                        if let window = NSApplication.shared.windows.first(where: { $0.title == "Desktop Clock" }) {
                            displayManager.moveWindow(window, toDisplay: display.id)
                        }
                    }
                }
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

// Separate window controller for settings
class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var settingsWindow: NSWindow?

    private init() {}

    func showSettings() {
        // If window already exists, just bring it to front
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        // Create settings view
        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 580),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Clock Settings"
        window.contentView = hostingView
        window.center()

        // Set window level ABOVE the clock (floating + 1)
        window.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)

        // Make it movable
        window.isMovableByWindowBackground = false
        window.isMovable = true

        // Show window
        window.makeKeyAndOrderFront(nil)

        settingsWindow = window
    }

    func closeSettings() {
        settingsWindow?.close()
        settingsWindow = nil
    }
}

#Preview {
    ClockView()
        .frame(width: 400, height: 150)
}
