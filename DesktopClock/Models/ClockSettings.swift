import SwiftUI
import Combine

class ClockSettings: ObservableObject {
    static let shared = ClockSettings()

    // Display
    @AppStorage("selectedDisplayID") var selectedDisplayID: String = ""

    // Position and Size
    @AppStorage("clockX") var clockX: Double = 100
    @AppStorage("clockY") var clockY: Double = 100
    @AppStorage("clockWidth") var clockWidth: Double = 400
    @AppStorage("clockHeight") var clockHeight: Double = 150

    // Colors (stored as hex strings)
    @AppStorage("foregroundColorHex") var foregroundColorHex: String = "#FFFFFF"
    @AppStorage("backgroundColorHex") var backgroundColorHex: String = "#000000"
    @AppStorage("borderColorHex") var borderColorHex: String = "#FFFFFF"

    // Border
    @AppStorage("showBorder") var showBorder: Bool = false
    @AppStorage("borderWidth") var borderWidth: Double = 2
    @AppStorage("cornerRadius") var cornerRadius: Double = 12
    @AppStorage("showShadow") var showShadow: Bool = false

    // Font
    @AppStorage("fontName") var fontName: String = "Menlo"
    @AppStorage("fontSize") var fontSize: Double = 72

    // Opacity
    @AppStorage("windowOpacity") var windowOpacity: Double = 0.9

    // Format
    @AppStorage("use24Hour") var use24Hour: Bool = false
    @AppStorage("showSeconds") var showSeconds: Bool = true
    @AppStorage("showAMPM") var showAMPM: Bool = true
    @AppStorage("uppercaseAMPM") var uppercaseAMPM: Bool = true
    @AppStorage("showDate") var showDate: Bool = false
    @AppStorage("dateFormat") var dateFormat: String = "EEEE, MMMM d"

    // Animation
    @AppStorage("animationEnabled") var animationEnabled: Bool = false

    // Computed color properties
    var foregroundColor: Color {
        get { Color(hex: foregroundColorHex) ?? .white }
        set { foregroundColorHex = newValue.toHex() ?? "#FFFFFF" }
    }

    var backgroundColor: Color {
        get { Color(hex: backgroundColorHex) ?? .black }
        set { backgroundColorHex = newValue.toHex() ?? "#000000" }
    }

    var borderColor: Color {
        get { Color(hex: borderColorHex) ?? .white }
        set { borderColorHex = newValue.toHex() ?? "#FFFFFF" }
    }

    private init() {}
}

// Color extension for hex conversion
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        if length == 6 {
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        } else if length == 8 {
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
    }

    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components else { return nil }

        let r: CGFloat = components.count > 0 ? components[0] : 0
        let g: CGFloat = components.count > 1 ? components[1] : 0
        let b: CGFloat = components.count > 2 ? components[2] : 0

        return String(format: "#%02X%02X%02X",
                      Int(r * 255),
                      Int(g * 255),
                      Int(b * 255))
    }
}
