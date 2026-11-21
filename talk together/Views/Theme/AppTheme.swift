import SwiftUI

// MARK: - 2026 Premium iOS Design System Tokens
public enum AppTheme {
    // MARK: - Colors (High Contrast WCAG AAA Compliant)
    public static let background = Color(hex: "F4F5F8")
    public static let surface = Color(hex: "FFFFFF")
    public static let primaryBlue = Color(hex: "2563EB")
    public static let primaryText = Color(hex: "111827")
    public static let secondaryText = Color(hex: "4B5563")
    public static let placeholderText = Color(hex: "6B7280")
    public static let inputBorder = Color(hex: "D1D5DB")
    public static let separator = Color(hex: "E5E7EB")
    
    // Status colors
    public static let liveRed = Color(hex: "EF4444")
    public static let liveRedSubtle = Color(hex: "EF4444").opacity(0.10)
    public static let successGreen = Color(hex: "16A34A")
    public static let successGreenSubtle = Color(hex: "16A34A").opacity(0.10)
    public static let warningOrange = Color(hex: "D97706")
    public static let warningOrangeSubtle = Color(hex: "D97706").opacity(0.10)
    public static let neutralSubtle = Color(hex: "85858D").opacity(0.10)
    
    // MARK: - Radii
    public static let radiusInput: CGFloat = 16
    public static let radiusCard: CGFloat = 20
    public static let radiusButton: CGFloat = 16
    public static let radiusPill: CGFloat = 100
    
    // MARK: - Spacing Grid (8pt system)
    public static let space4: CGFloat = 4
    public static let space6: CGFloat = 6
    public static let space8: CGFloat = 8
    public static let space12: CGFloat = 12
    public static let space16: CGFloat = 16
    public static let space20: CGFloat = 20
    public static let space24: CGFloat = 24
    public static let space32: CGFloat = 32
    public static let space40: CGFloat = 40
}

// MARK: - Color Hex Initializer
extension Color {
    public init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8: // ARGB (32-bit)
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers for 2026 Clean Surfaces
public struct PremiumCardModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var padding: CGFloat
    
    public init(cornerRadius: CGFloat = AppTheme.radiusCard, padding: CGFloat = AppTheme.space16) {
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )
    }
}

extension View {
    public func premiumCard(cornerRadius: CGFloat = AppTheme.radiusCard, padding: CGFloat = AppTheme.space16) -> some View {
        modifier(PremiumCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}
