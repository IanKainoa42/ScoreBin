import SwiftData
import SwiftUI

// Detail view for viewing a specific scoresheet

struct ScoreSheetDetailView: View {
    let scoresheet: Scoresheet
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    headerSection
                        .padding(.horizontal)

                    // Score Summary
                    scoreSummarySection
                        .padding(.horizontal)

                    // Categories
                    VStack(spacing: 16) {
                        ScoreSectionView(
                            title: "Building",
                            icon: "person.3.fill",
                            color: .blue,  // Using standard blue if scoreBin colors aren't globally available here, can adjust
                            items: buildingItems
                        )

                        ScoreSectionView(
                            title: "Tumbling",
                            icon: "figure.gymnastics",
                            color: .green,
                            items: tumblingItems
                        )

                        ScoreSectionView(
                            title: "Overall",
                            icon: "star.fill",
                            color: .purple,
                            items: overallItems
                        )
                    }
                    .padding(.horizontal)

                    // Deductions
                    if scoresheet.totalDeductions > 0 {
                        deductionsSection
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.scoreBinBackground)
            .navigationTitle(scoresheet.round)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(scoresheet.team?.name ?? "Unknown Team")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            if let gymName = scoresheet.team?.gym?.name {
                Text(gymName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Text(scoresheet.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.scoreBinBackground.opacity(0.5))  // Assuming this matches card style
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var scoreSummarySection: some View {
        HStack(spacing: 0) {
            ScoreSummaryItem(
                title: "Raw Score",
                value: scoresheet.rawScore.rounded2.formatted()
            )

            Divider().background(Color.gray.opacity(0.3))

            ScoreSummaryItem(
                title: "Deductions",
                value: scoresheet.totalDeductions.rounded2.formatted(),
                color: scoresheet.totalDeductions > 0 ? .red : .gray
            )

            Divider().background(Color.gray.opacity(0.3))

            ScoreSummaryItem(
                title: "Final Score",
                value: scoresheet.finalScore.rounded2.formatted(),
                color: .scoreBinEmerald
            )
        }
        .padding()
        .background(Color.scoreBinBackground.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var deductionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deductions")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 8) {
                if scoresheet.athleteFalls > 0 {
                    DeductionRow(
                        name: "Athlete Fall", count: scoresheet.athleteFalls,
                        value: ScoringRules.Deductions.athleteFall)
                }
                if scoresheet.majorAthleteFalls > 0 {
                    DeductionRow(
                        name: "Major Athlete Fall", count: scoresheet.majorAthleteFalls,
                        value: ScoringRules.Deductions.majorAthleteFall)
                }
                if scoresheet.buildingBobbles > 0 {
                    DeductionRow(
                        name: "Building Bobble", count: scoresheet.buildingBobbles,
                        value: ScoringRules.Deductions.buildingBobble)
                }
                if scoresheet.buildingFalls > 0 {
                    DeductionRow(
                        name: "Building Fall", count: scoresheet.buildingFalls,
                        value: ScoringRules.Deductions.buildingFall)
                }
                if scoresheet.majorBuildingFalls > 0 {
                    DeductionRow(
                        name: "Major Building Fall", count: scoresheet.majorBuildingFalls,
                        value: ScoringRules.Deductions.majorBuildingFall)
                }
                if scoresheet.boundaryViolations > 0 {
                    DeductionRow(
                        name: "Boundary Violation", count: scoresheet.boundaryViolations,
                        value: ScoringRules.Deductions.boundaryViolation)
                }
                if scoresheet.timeLimitViolations > 0 {
                    DeductionRow(
                        name: "Time Limit", count: scoresheet.timeLimitViolations,
                        value: ScoringRules.Deductions.timeLimitViolation)
                }
            }
        }
        .padding()
        .background(Color.scoreBinBackground.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Data Helpers

    private var buildingItems: [ScoreDetailItem] {
        [
            ScoreDetailItem(
                label: "Stunts", value: scoresheet.stuntTotal, max: ScoringRules.Maximums.stuntTotal
            ),
            ScoreDetailItem(
                label: "Pyramids", value: scoresheet.pyramidTotal,
                max: ScoringRules.Maximums.pyramidTotal),
            ScoreDetailItem(
                label: "Tosses", value: scoresheet.tossTotal, max: ScoringRules.Maximums.tossTotal),
            ScoreDetailItem(
                label: "Creativity", value: scoresheet.buildingCreativity,
                max: ScoringRules.Maximums.creativity),
            ScoreDetailItem(
                label: "Showmanship", value: scoresheet.buildingShowmanship,
                max: ScoringRules.Maximums.showmanship),
        ]
    }

    private var tumblingItems: [ScoreDetailItem] {
        [
            ScoreDetailItem(
                label: "Standing", value: scoresheet.standingTotal,
                max: ScoringRules.Maximums.standingTotal),
            ScoreDetailItem(
                label: "Running", value: scoresheet.runningTotal,
                max: ScoringRules.Maximums.runningTotal),
            ScoreDetailItem(
                label: "Jumps", value: scoresheet.jumpsTotal, max: ScoringRules.Maximums.jumpsTotal),
            ScoreDetailItem(
                label: "Creativity", value: scoresheet.tumblingCreativity,
                max: ScoringRules.Maximums.creativity),
            ScoreDetailItem(
                label: "Showmanship", value: scoresheet.tumblingShowmanship,
                max: ScoringRules.Maximums.showmanship),
        ]
    }

    private var overallItems: [ScoreDetailItem] {
        [
            ScoreDetailItem(
                label: "Dance", value: scoresheet.danceTotal, max: ScoringRules.Maximums.danceTotal),
            ScoreDetailItem(
                label: "Formations", value: scoresheet.formations,
                max: ScoringRules.Maximums.formations),
            ScoreDetailItem(
                label: "Creativity", value: scoresheet.overallCreativity,
                max: ScoringRules.Maximums.creativity),
            ScoreDetailItem(
                label: "Showmanship", value: scoresheet.overallShowmanship,
                max: ScoringRules.Maximums.showmanship),
        ]
    }
}

// MARK: - Subviews

struct ScoreSummaryItem: View {
    let title: String
    let value: String
    var color: Color = .white

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ScoreSectionView: View {
    let title: String
    let icon: String
    let color: Color
    let items: [ScoreDetailItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                ForEach(items) { item in
                    HStack {
                        Text(item.label)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Spacer()

                        Text("\(item.value.rounded2.formatted())")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text("/ \(item.max.rounded2.formatted())")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.7))
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color.scoreBinBackground.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)  // Reusing card look
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct DeductionRow: View {
    let name: String
    let count: Int
    let value: Double

    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            Text("\(count)x")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.1))
                .cornerRadius(4)

            Text("-\((Double(count) * value).rounded2.formatted())")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.red)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

struct ScoreDetailItem: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let max: Double
}

#Preview {
    ScoreSheetDetailView(scoresheet: Scoresheet())
        .preferredColorScheme(.dark)
}
