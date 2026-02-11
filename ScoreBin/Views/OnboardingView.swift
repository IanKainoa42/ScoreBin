import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.scoreBinBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    // Page 1: Welcome
                    onboardingPage(
                        icon: "doc.text.fill",
                        iconColor: .scoreBinCyan,
                        title: "Welcome to ScoreBin",
                        subtitle: "The fastest way to score cheerleading routines using the United Scoring System."
                    )
                    .tag(0)

                    // Page 2: Add Teams
                    onboardingPage(
                        icon: "person.3.fill",
                        iconColor: .scoreBinEmerald,
                        title: "Add Your Teams",
                        subtitle: "Set up teams with their level, division, and athlete count. The quantity chart calculates automatically."
                    )
                    .tag(1)

                    // Page 3: Start Scoring
                    onboardingPage(
                        icon: "checkmark.circle.fill",
                        iconColor: .overallYellow,
                        title: "Start Scoring",
                        subtitle: "Enter scores by judge panel. Building, Tumbling, and Overall scores calculate in real-time."
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom controls
                VStack(spacing: 20) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.scoreBinCyan : Color.scoreBinBorder)
                                .frame(width: 8, height: 8)
                        }
                    }

                    // Action button
                    Button {
                        if currentPage < 2 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            hasCompletedOnboarding = true
                        }
                    } label: {
                        Text(currentPage < 2 ? "Next" : "Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.scoreBinGradient)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)

                    // Skip button
                    if currentPage < 2 {
                        Button("Skip") {
                            hasCompletedOnboarding = true
                        }
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func onboardingPage(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(iconColor)

            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(subtitle)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
