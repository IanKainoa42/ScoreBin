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
    private static let scoreFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Format score for display (2 decimal places)
    var scoreFormatted: String {
        Self.scoreFormatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }

    /// Format score with sign for deductions
    var deductionFormatted: String {
        "-\(scoreFormatted)"
    }

    /// Round to 2 decimal places
    var rounded2: Double {
        (self * 100).rounded() / 100
    }
}

// MARK: - Date Formatter Extensions
extension ISO8601DateFormatter {
    public static let shared = ISO8601DateFormatter()
}

extension DateFormatter {
    public static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

// MARK: - String Extensions
extension String {
    /// Returns true if the string is empty or contains only whitespaces and newlines
    var isBlank: Bool {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

    private static let abbreviatedDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    /// Format date for competition display
    var competitionFormatted: String {
        return Self.competitionFormatter.string(from: self)
    }

    /// Format date for short display
    var shortFormatted: String {
        return Self.shortFormatter.string(from: self)
    }

    /// Format date and time for abbreviated display
    var abbreviatedDateTimeFormatted: String {
        return Self.abbreviatedDateTimeFormatter.string(from: self)
    }
}
