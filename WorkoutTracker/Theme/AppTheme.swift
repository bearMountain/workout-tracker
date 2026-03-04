import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let cardBorder = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    static let accent = Color(red: 0.46, green: 0.82, blue: 0.46)
    static let accentSecondary = Color(red: 0.4, green: 0.7, blue: 0.9)
    
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.6, green: 0.6, blue: 0.6)
    static let textMuted = Color(red: 0.4, green: 0.4, blue: 0.4)
    
    static let success = Color(red: 0.3, green: 0.8, blue: 0.4)
    static let warning = Color(red: 0.95, green: 0.7, blue: 0.3)
    static let danger = Color(red: 0.9, green: 0.3, blue: 0.3)
    
    static let cornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let spacing: CGFloat = 12
    static let spacingLarge: CGFloat = 24
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.cardPadding)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.background)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.accent)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.accent, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
