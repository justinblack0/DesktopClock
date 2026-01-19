import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settings = ClockSettings.shared
    @ObservedObject var displayManager = DisplayManager.shared

    @State private var foregroundColor: Color = .white
    @State private var backgroundColor: Color = .black
    @State private var borderColor: Color = .white
    @State private var customFontName: String = ""

    // Curated list of common fonts
    let commonFonts = [
        "Menlo", "Monaco", "SF Mono", "Courier New", "Courier",
        "Helvetica Neue", "Helvetica", "Arial", "SF Pro Display",
        "Avenir Next", "Avenir", "Futura", "Gill Sans", "Optima",
        "Georgia", "Times New Roman", "Verdana", "Trebuchet MS",
        "American Typewriter", "Copperplate", "Didot", "Baskerville"
    ]

    let dateFormats = [
        ("EEEE, MMMM d", "Monday, January 1"),
        ("MMM d, yyyy", "Jan 1, 2024"),
        ("MM/dd/yyyy", "01/01/2024"),
        ("dd/MM/yyyy", "01/01/2024"),
        ("yyyy-MM-dd", "2024-01-01"),
        ("EEEE", "Monday"),
        ("MMMM d", "January 1")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Display Section
                SettingsSection(title: "Display") {
                    Picker("Target Display", selection: $settings.selectedDisplayID) {
                        Text("Current Display").tag("")
                        ForEach(displayManager.displays) { display in
                            Text(display.displayName).tag(display.id)
                        }
                    }
                    .pickerStyle(.menu)

                    Button("Move Clock to Selected Display") {
                        if let window = NSApplication.shared.windows.first(where: { $0.title == "Desktop Clock" }) {
                            if settings.selectedDisplayID.isEmpty {
                                if let firstDisplay = displayManager.displays.first {
                                    displayManager.moveWindow(window, toDisplay: firstDisplay.id)
                                }
                            } else {
                                displayManager.moveWindow(window, toDisplay: settings.selectedDisplayID)
                            }
                        }
                    }
                }

                // Appearance Section
                SettingsSection(title: "Colors") {
                    HStack {
                        Text("Text Color")
                        Spacer()
                        ColorPicker("", selection: $foregroundColor, supportsOpacity: false)
                            .labelsHidden()
                            .onChange(of: foregroundColor) { newValue in
                                settings.foregroundColor = newValue
                            }
                    }

                    HStack {
                        Text("Background Color")
                        Spacer()
                        ColorPicker("", selection: $backgroundColor, supportsOpacity: false)
                            .labelsHidden()
                            .onChange(of: backgroundColor) { newValue in
                                settings.backgroundColor = newValue
                            }
                    }

                    HStack {
                        Text("Opacity")
                        Spacer()
                        Slider(value: $settings.windowOpacity, in: 0.1...1.0, step: 0.05)
                            .frame(width: 150)
                        Text("\(Int(settings.windowOpacity * 100))%")
                            .frame(width: 40)
                    }
                }

                // Border Section
                SettingsSection(title: "Border") {
                    Toggle("Show Border", isOn: $settings.showBorder)

                    if settings.showBorder {
                        HStack {
                            Text("Border Color")
                            Spacer()
                            ColorPicker("", selection: $borderColor, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: borderColor) { newValue in
                                    settings.borderColor = newValue
                                }
                        }

                        HStack {
                            Text("Border Width")
                            Spacer()
                            Slider(value: $settings.borderWidth, in: 1...20, step: 1)
                                .frame(width: 150)
                            Text("\(Int(settings.borderWidth))px")
                                .frame(width: 45)
                        }
                    }

                    HStack {
                        Text("Corner Radius")
                        Spacer()
                        Slider(value: $settings.cornerRadius, in: 0...50, step: 2)
                            .frame(width: 150)
                        Text("\(Int(settings.cornerRadius))px")
                            .frame(width: 45)
                    }

                    Toggle("Show Shadow", isOn: $settings.showShadow)
                }

                // Font Section
                SettingsSection(title: "Font") {
                    Picker("Common Fonts", selection: $settings.fontName) {
                        ForEach(commonFonts, id: \.self) { font in
                            Text(font).tag(font)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack {
                        Text("Custom Font")
                        Spacer()
                        TextField("Font name", text: $customFontName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)
                            .onSubmit {
                                if !customFontName.isEmpty {
                                    settings.fontName = customFontName
                                }
                            }
                    }

                    Text("Type any installed font name and press Enter")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Format Section
                SettingsSection(title: "Time Format") {
                    Toggle("Use 24-Hour Format", isOn: $settings.use24Hour)
                    Toggle("Show Seconds", isOn: $settings.showSeconds)

                    if !settings.use24Hour {
                        Toggle("Show AM/PM", isOn: $settings.showAMPM)

                        if settings.showAMPM {
                            Picker("AM/PM Style", selection: $settings.uppercaseAMPM) {
                                Text("AM / PM").tag(true)
                                Text("am / pm").tag(false)
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    Toggle("Show Date", isOn: $settings.showDate)

                    if settings.showDate {
                        Picker("Date Format", selection: $settings.dateFormat) {
                            ForEach(dateFormats, id: \.0) { format in
                                Text(format.1).tag(format.0)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                // Effects Section
                SettingsSection(title: "Effects") {
                    Toggle("Pulse Animation on Second Change", isOn: $settings.animationEnabled)
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .frame(minWidth: 380, minHeight: 500)
        .onAppear {
            foregroundColor = settings.foregroundColor
            backgroundColor = settings.backgroundColor
            borderColor = settings.borderColor
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

#Preview {
    SettingsView()
}
