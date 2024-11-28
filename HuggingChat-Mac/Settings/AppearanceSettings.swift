//
//  AppearanceSettings.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/2/24.
//

import SwiftUI
import Highlightr
import MarkdownView

enum Appearance: String {
    case light, dark, auto
    
    var iconName: String {
        switch self {
        case .light:
            return "ThemeIconLight"
        case .dark:
            return "ThemeIconDark"
        case .auto:
            return "ThemeIconAuto"
        }
    }
}

enum AccentColorOption: String, CaseIterable {
    case blue, purple, pink, red, orange, yellow, green, gray
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .gray: return .gray
        }
    }
}

struct AppearanceSettings: View {
    
    @Environment(ModelManager.self) private var modelManager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appearance") private var appearance: Appearance = .auto
    @AppStorage("inlineCodeHiglight") private var inlineCodeHiglight: AccentColorOption = .blue
    @AppStorage("lightCodeBlockTheme") private var lightCodeBlockTheme: String = "xcode"
    @AppStorage("darkCodeBlockTheme") private var darkCodeBlockTheme: String = "monokai-sublime"
    
    // Themes
    @AppStorage("isPixelPalsUnlocked") var isPixelPalsUnlocked: Bool = false
    @AppStorage("isChromeDinoUnlocked") var isChromeDinoUnlocked: Bool = false
    @AppStorage("isAppleClassicUnlocked") var isAppleClassicUnlocked: Bool = false
    var sortedThemes: [ThemeNames] {
        ThemeNames.allCases.sorted { firstTheme, secondTheme in
            if isThemeUnlocked(firstTheme) == isThemeUnlocked(secondTheme) {
                return firstTheme.rawValue < secondTheme.rawValue // Alphabetical order if unlock status is the same
            }
            return isThemeUnlocked(firstTheme) && !isThemeUnlocked(secondTheme)
        }
    }
    
    // Code theme
    @State private var isPreviewExpanded: Bool = false
    @State var codeSample: String = """
Here's an `inline code sample`, followed by a code block: 
```python
# This is a comment
def function():
    return "Here's a string"

squares = [x**2 for x in range(5)]
```
"""
    var lightThemes = [
        "a11y-light",
        "arduino-light", "ascetic", "atelier-cave-light",
        "atelier-dune-light",
        "atelier-estuary-light","atelier-forest-light",
        "atelier-heath-light",
        "atelier-lakeside-light","atelier-plateau-light",
        "atelier-savanna-light",
        "atelier-seaside-light",  "atelier-sulphurpool-light", "atom-one-light", "brown-paper", "color-brewer", "default",
        "docco", "foundation", "github-gist", "github",
        "googlecode", "grayscale", "gruvbox-light",
        "idea", "isbl-editor-light", "kimbie.light", "lightfair", "mono-blue",
        "paraiso-light", "purebasic", "qtcreator_light", "routeros", "school-book",
        "solarized-light",
        "tomorrow", "vs", "xcode"
    ]
    
    
    var darkThemes = [
        "agate", "an-old-hope", "androidstudio",
        "arta", "atelier-cave-dark",
        "atelier-dune-dark", "atelier-estuary-dark",
        "atelier-forest-dark",
        "atelier-heath-dark", "atelier-lakeside-dark",
        "atelier-plateau-dark",
        "atelier-savanna-dark", "atelier-seaside-dark", "atelier-sulphurpool-dark",
        "atom-one-dark-reasonable", "atom-one-dark",
        "codepen-embed", "darcula", "dark", "darkula",
        "docco", "dracula", "far", "gml",
        "gruvbox-dark", "hopscotch",
        "hybrid", "ir-black", "isbl-editor-dark",
        "kimbie.dark", "magula",
        "monokai-sublime", "monokai", "nord", "obsidian", "ocean", "paraiso-dark",
        "pojoaque", "qtcreator_dark",
        "railscasts", "rainbow", "shades-of-purple",
        "solarized-dark", "sunburst", "tomorrow-night-blue",
        "tomorrow-night-bright", "tomorrow-night-eighties", "tomorrow-night",
        "vs2015", "xcode-dark", "xt256", "zenburn"
    ]
    
    let columns = [GridItem(.adaptive(minimum: 80))]
    
    var body: some View {
        Form {
            Section(content: {
                LabeledContent("Appearance:", content: {
                    HStack(spacing: 12) {
                        AppearanceButton(title: "Light", isSelected: appearance == .light, icon: Appearance.light.iconName) {
                            appearance = .light
                        }
                        AppearanceButton(title: "Dark", isSelected: appearance == .dark, icon: Appearance.dark.iconName) {
                            appearance = .dark
                        }
                        AppearanceButton(title: "Auto", isSelected: appearance == .auto, icon: Appearance.auto.iconName) {
                            appearance = .auto
                        }
                    }
                    
                })
            }, header: {
                Text("General")
            })
            
            Section(content: {
                // Code Accent color
                LabeledContent("Inline Highlight:") {
                    HStack(spacing: 8) {
                        ForEach(AccentColorOption.allCases, id: \.self) { option in
                            ColorButton(color: option.color, isSelected: inlineCodeHiglight == option) {
                                inlineCodeHiglight = option
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                LabeledContent("Syntax Highlight Theme") {
                    if colorScheme == .light {
                        Picker("", selection: $lightCodeBlockTheme) {
                            ForEach(lightThemes, id: \.self) { theme in
                                Text(formatTheme(themeName: theme))
                                    .tag(theme)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                        
                    } else if colorScheme == .dark {
                        Picker("", selection: $darkCodeBlockTheme) {
                            ForEach(darkThemes, id: \.self) { theme in
                                Text(formatTheme(themeName: theme))
                                    .tag(theme)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                    }
                }
                
                DisclosureGroup(isExpanded: $isPreviewExpanded) {
                    
                    MarkdownView(text: $codeSample)
                        .font(.system(.body).monospaced().weight(.medium), for: .codeBlock)
                        .tint(inlineCodeHiglight.color, for: .inlineCodeBlock)
                        .codeHighlighterTheme(CodeHighlighterTheme(lightModeThemeName: lightCodeBlockTheme, darkModeThemeName: darkCodeBlockTheme))
                        .padding(.top, 10)
                } label: {
                    Text("Markdown Preview")
                        .fontWeight(.medium)
                }
                
            }, header: {
                Text("Code")
            })
            
            
            Section(content: {
                ScrollView {
                    HStack(alignment: .top) {
                        ForEach(sortedThemes, id: \.self) { themeName in
                            let theme = ThemingEngine.theme(for: themeName)
                            let isUnlocked = isThemeUnlocked(themeName)
                            ThemeThumbnailView(theme: theme, isSelected: ThemingEngine.shared.currentTheme.name == themeName, isUnlocked: isUnlocked)
                                .frame(width: 80)
                                .onTapGesture {
                                    if isUnlocked {
                                        ThemingEngine.shared.setTheme(themeName)
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }, header: {
                Text("Theme")
            })
        }.formStyle(.grouped)
        
    }
    
    private func formatTheme(themeName: String) -> String {
        return  themeName
            .replacingOccurrences(of: "[^a-zA-Z0-9]", with: " ", options: .regularExpression)
            .split(separator: " ")
            .map { $0.lowercased() }
            .joined(separator: " ")
            .capitalized
    }
    
    private func isThemeUnlocked(_ themeName: ThemeNames) -> Bool {
        switch themeName {
        case .pixelPals:
            return isPixelPalsUnlocked
        case .chromeDino:
            return isChromeDinoUnlocked
        case .appleClassic:
            return isAppleClassicUnlocked
        default:
            return true
        }
    }
}

struct AppearanceButton: View {
    let title: String
    let isSelected: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(icon)
                    .mask {
                        RoundedRectangle(cornerRadius: 7)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(isSelected ? .blue: .clear, lineWidth: 3)
                    )
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
        }
        
        .buttonStyle(.borderless)
    }
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
                .overlay(
                    
                    Circle()
                        .fill(isSelected ? .white:.clear)
                        .frame(width: 7, height: 10)
                    
                )
        }
        .buttonStyle(.borderless)
        .help(color.description.capitalized)
    }
}

struct ThemeThumbnailView: View {
    let theme: Theme
    let isSelected: Bool
    var isUnlocked: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            ZStack {
                Image(theme.previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .shadow(color: .primary.opacity(0.2), radius: 5)
                    .cornerRadius(10)
                if !isUnlocked {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.black.gradient.opacity(0.8))
                        .frame(width: 50, height: 50)
                    Image(systemName: "lock.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            
            Text(theme.name.rawValue)
                .font(.caption)
                .foregroundColor(isSelected ? .primary : .secondary)
                .multilineTextAlignment(.center)
            //                .lineLimit(1)
        }
    }
}

#Preview {
    AppearanceSettings()
    //        .frame(width: 500, height: 500)
        .environment(ModelManager())
}
