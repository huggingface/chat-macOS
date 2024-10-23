//
//  StyleSheet.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/29/24.
//

import SwiftUI
import AppKit

struct Margin {
    static let _2: CGFloat = 2
    static let _4: CGFloat = 4
    static let _6: CGFloat = 6
    static let _8: CGFloat = 8
    static let _10: CGFloat = 10
    static let _12: CGFloat = 12
    static let _14: CGFloat = 14
    static let _16: CGFloat = 16
    static let _20: CGFloat = 20
    static let _22: CGFloat = 22
    static let _24: CGFloat = 24
    static let _26: CGFloat = 26
    static let _28: CGFloat = 28
    static let _32: CGFloat = 32
    static let _44: CGFloat = 44
}

struct FontMinimumScaleFactor {
    static let _08: CGFloat = 0.8
}

struct Border {
    static let _1: CGFloat = 1
}

extension NSFont {

    enum Inter {
        enum Bold {
            static let _12 = custom(with: 12)
            static let _14 = custom(with: 14)
            static let _18 = custom(with: 18)
            static let _20 = custom(with: 20)
            static let _30 = custom(with: 30)
            static let _40 = custom(with: 40)
            private static func custom(with size: CGFloat) -> NSFont {
                return NSFont(name: "Inter-Regular_Bold", size: size)!
            }
        }
        
        enum SemiBold {
            static let _12 = custom(with: 12)
            static let _14 = custom(with: 14)
            static let _16 = custom(with: 16)
            static let _18 = custom(with: 18)
            static let _22 = custom(with: 22)

            private static func custom(with size: CGFloat) -> NSFont {
                return NSFont(name: "Inter-Regular_SemiBold", size: size)!
            }
        }

        enum Regular {
            static let _8 = custom(with: 8)
            static let _12 = custom(with: 12)
            static let _14 = custom(with: 14)
            static let _15 = custom(with: 15)
            static let _20 = custom(with: 20)

            private static func custom(with size: CGFloat) -> NSFont {
                return NSFont(name: "Inter-Regular", size: size)!
            }

            private static func customSUI(with size: CGFloat) -> Font {
                return Font.custom("Inter-Regular", size: size)
            }
        }

        enum Light {
            static let _16 = custom(with: 16)
            private static func custom(with size: CGFloat) -> NSFont {
                return NSFont(name: "Inter-Regular_Light", size: size)!
            }
        }
    }
}

extension Font {
    enum Inter {
        enum Bold {
            static let _20 = custom(with: 20)
            static let _30 = custom(with: 30)
            private static func custom(with size: CGFloat) -> Font {
                return Font.custom("Inter-Regular_Bold", size: size)
            }
        }

        enum Regular {
            static let _12 = custom(with: 12)
            static let _14 = custom(with: 14)
            static let _16 = custom(with: 16)
            static let _18 = custom(with: 18)
            static let _20 = custom(with: 20)

            private static func custom(with size: CGFloat) -> Font {
                return Font.custom("Inter-Regular", size: size)
            }
        }

        enum SemiBold {
            static let _12 = custom(with: 12)
            static let _14 = custom(with: 14)
            static let _16 = custom(with: 16)
            static let _18 = custom(with: 18)
            static let _22 = custom(with: 22)

            private static func custom(with size: CGFloat) -> Font {
                return Font.custom("Inter-Regular_SemiBold", size: size)
            }
        }
    }
}

struct CornerRadius {
    static let _4: CGFloat = 4
    static let _6: CGFloat = 6
    static let _8: CGFloat = 8
    static let _12: CGFloat = 12
    static let _16: CGFloat = 16
    static let _22: CGFloat = 22
}

extension Color {
    enum HF {
        static let black = Color("hf_black")
        static let white = Color("hf_white")
        static let yellow = Color("hf_yellow")
        static let darkYellow = Color("hf_darkYellow")

        static let blue = Color("hf_blue")
        static let purple = Color("hf_purple")
        static let red = Color("hf_red")

        static let gray50 = Color("gray50")
        static let gray100 = Color("gray100")
        static let gray200 = Color("gray200")
        static let gray300 = Color("gray300")
        static let gray350 = Color("gray350")  // unofficial tailwind color
        static let gray400 = Color("gray400")
        static let gray500 = Color("gray500")
        static let gray600 = Color("gray600")
        static let gray650 = Color("gray650")  // unofficial tailwind color
        static let gray700 = Color("gray700")
        static let gray800 = Color("gray800")
        static let gray900 = Color("gray900")

        static let yellowGradient: [Color] = [
            yellow.opacity(0.4), yellow.opacity(0.1), yellow.opacity(0),
        ]
        static let avatarGradient: [Color] = [red, purple, blue]
        fileprivate static let grayBGGradient: [Color] = [white, gray50]
    }
}

extension NSColor {
    enum HF {
        static let black = NSColor(named: "hf_black")!
        static let white = NSColor(named: "hf_white")!
        static let yellow = NSColor(named: "hf_yellow")!
        static let darkYellow = NSColor(named: "hf_darkYellow")!
        static let activeBlue = NSColor(named: "hf_activeBlue")!

        static let gray50 = NSColor(named: "gray50")!
        static let gray100 = NSColor(named: "gray100")!
        static let gray200 = NSColor(named: "gray200")!
        static let gray300 = NSColor(named: "gray300")!
        static let gray350 = NSColor(named: "gray350")!  // unofficial tailwind color
        static let gray400 = NSColor(named: "gray400")!
        static let gray500 = NSColor(named: "gray500")!
        static let gray600 = NSColor(named: "gray600")!
        static let gray650 = NSColor(named: "gray650")!  // unofficial tailwind color
        static let gray700 = NSColor(named: "gray700")!
        static let gray800 = NSColor(named: "gray800")!
        static let gray900 = NSColor(named: "gray900")!
    }
}

extension LinearGradient {
    enum HF {
        static let grayBGGradient: LinearGradient = LinearGradient(colors: Color.HF.grayBGGradient, startPoint: UnitPoint(x: 0.5, y: 0.0), endPoint: UnitPoint(x: 0.5, y: 1.0))
    }
}

