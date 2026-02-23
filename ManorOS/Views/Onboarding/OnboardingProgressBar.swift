import SwiftUI

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if currentStep > 0 {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                }
            } else {
                Color.clear.frame(width: 32, height: 32)
            }

            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= currentStep ? Constants.accentColor : Color.white.opacity(0.15))
                        .frame(height: 4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}
