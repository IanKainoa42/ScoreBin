import SwiftUI

// MARK: - Color Extensions
extension Color {
    // App Theme Colors
    static let scoreBinBackground = Color(red: 0.07, green: 0.09, blue: 0.11)
    static let scoreBinCardBackground = Color(red: 0.12, green: 0.14, blue: 0.18)
    static let scoreBinBorder = Color(red: 0.25, green: 0.27, blue: 0.31)

    // Judge Panel Colors
    static let buildingRed = Color(red: 0.94, green: 0.27, blue: 0.27)
    static let buildingRedLight = Color(red: 0.94, green: 0.27, blue: 0.27).opacity(0.2)

    static let tumblingTeal = Color(red: 0.13, green: 0.78, blue: 0.71)
    static let tumblingTealLight = Color(red: 0.13, green: 0.78, blue: 0.71).opacity(0.2)

    static let overallYellow = Color(red: 0.92, green: 0.73, blue: 0.23)
    static let overallYellowLight = Color(red: 0.92, green: 0.73, blue: 0.23).opacity(0.2)

    // Accent Colors
    static let scoreBinCyan = Color(red: 0.13, green: 0.83, blue: 0.93)
    static let scoreBinEmerald = Color(red: 0.20, green: 0.83, blue: 0.60)
    static let scoreBinPurple = Color(red: 0.65, green: 0.45, blue: 0.95)

    // Gradient
    static var scoreBinGradient: LinearGradient {
        LinearGradient(
            colors: [.scoreBinCyan, .scoreBinEmerald],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - View Extensions
extension View {
    /// Apply card styling with optional border color
    func cardStyle(borderColor: Color = .scoreBinBorder) -> some View {
        self
            .background(Color.scoreBinCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor.opacity(0.3), lineWidth: 1)
            )
    }

    /// Apply judge panel header styling
    func judgeHeaderStyle(color: Color) -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.2))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(color.opacity(0.3)),
                alignment: .bottom
            )
    }
}

// MARK: - Number Formatting
extension Double {
    /// Format score for display (2 decimal places)
    var scoreFormatted: String {
        String(format: "%.2f", self)
    }

    /// Format score with sign for deductions
    var deductionFormatted: String {
        String(format: "-%.2f", self)
    }
}

// MARK: - Date Extensions
extension Date {
    private static let competitionFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter
    }()

    /// Format date for competition display
    var competitionFormatted: String {
        Self.competitionFormatter.string(from: self)
    }

    /// Format date for short display
    var shortFormatted: String {
        Self.shortFormatter.string(from: self)
    }
}

// MARK: - String Extensions
extension String {
    private static let snakeCaseRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "([a-z0-9])([A-Z])", options: [])
    }()

    /// Convert camelCase to snake_case
    var snakeCase: String {
        guard let regex = Self.snakeCaseRegex else { return self.lowercased() }
        let range = NSRange(location: 0, length: self.count)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased()
    }
}
