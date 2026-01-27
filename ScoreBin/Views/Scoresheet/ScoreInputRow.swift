import SwiftUI

struct ScoreInputRow: View {
    let label: String
    @Binding var value: Double
    let range: ScoringRules.ScoreRange

    @State private var showingPad = false
    @State private var inputText = ""

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    if value > range.min {
                        value = max(range.min, value - range.step)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)

                Button {
                    inputText = ""
                    showingPad = true
                } label: {
                    Text(value.scoreFormatted)
                        .font(.system(.body, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .padding(.vertical, 6)
                        .background(Color.scoreBinBackground)
                        .cornerRadius(6)
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button {
                    if value < range.max {
                        value = min(range.max, value + range.step)
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.scoreBinCyan)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingPad) {
            DecimalPadView(
                inputText: $inputText,
                value: $value,
                range: range,
                isPresented: $showingPad
            )
            .presentationDetents([.height(550)])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Custom Decimal Pad

struct DecimalPadView: View {
    @Binding var inputText: String
    @Binding var value: Double
    let range: ScoringRules.ScoreRange
    @Binding var isPresented: Bool

    private let buttons: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"],
    ]

    var displayText: String {
        inputText.isEmpty ? value.scoreFormatted : inputText
    }

    var body: some View {
        VStack(spacing: 16) {
            // Display
            Text(displayText)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.scoreBinBackground)
                .cornerRadius(12)

            // Range indicator
            Text("Range: \(range.min.scoreFormatted) - \(range.max.scoreFormatted)")
                .font(.caption)
                .foregroundColor(.gray)

            // Keypad
            VStack(spacing: 12) {
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { button in
                            DecimalPadButton(title: button) {
                                handleButtonPress(button)
                            }
                        }
                    }
                }
            }

            // Done button
            Button {
                applyValue()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.scoreBinCyan)
                    .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color.scoreBinCardBackground)
    }

    private func handleButtonPress(_ button: String) {
        switch button {
        case "⌫":
            if !inputText.isEmpty {
                inputText.removeLast()
            }
        case ".":
            // Only add decimal if not already present and within length limit
            if !inputText.contains(".") && inputText.count < 4 {
                if inputText.isEmpty {
                    inputText = "0."
                } else {
                    inputText += "."
                }
            }
        default:
            // Limit to 5 characters (00.00 format)
            if inputText.count < 5 {
                // Don't allow more than 2 decimal places
                if let dotIndex = inputText.firstIndex(of: ".") {
                    let decimalPlaces =
                        inputText.distance(from: dotIndex, to: inputText.endIndex) - 1
                    if decimalPlaces >= 2 {
                        return
                    }
                }
                inputText += button
            }
        }
    }

    private func applyValue() {
        if let newValue = Double(inputText) {
            // Clamp to range
            value = min(range.max, max(range.min, newValue))
        }
        isPresented = false
    }
}

struct DecimalPadButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(title == "⌫" ? .gray : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.scoreBinBackground)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct SectionTotalRow: View {
    let label: String
    let value: Double
    let maxValue: Double
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.gray)

            Spacer()

            HStack(spacing: 4) {
                Text(value.scoreFormatted)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text("/ \(maxValue.scoreFormatted)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.scoreBinBackground.opacity(0.5))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 20) {
        ScoreInputRow(
            label: "Difficulty",
            value: .constant(3.5),
            range: ScoringRules.stuntDifficultyRange
        )

        SectionTotalRow(
            label: "Stunt Total",
            value: 8.5,
            maxValue: 10.0,
            color: .scoreBinCyan
        )
    }
    .padding()
    .background(Color.scoreBinCardBackground)
}
