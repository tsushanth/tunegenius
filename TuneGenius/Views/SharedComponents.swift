//
//  SharedComponents.swift
//  TuneGenius
//
//  Reusable UI primitives used across views
//

import SwiftUI

// MARK: - Gradient Background
struct TGGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.07, green: 0.07, blue: 0.12),
                Color(red: 0.10, green: 0.06, blue: 0.18),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Step Button (± increment)
struct StepButton: View {
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.bold())
                .foregroundColor(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Labeled Slider Row
struct LabeledSliderRow: View {
    let label: String
    let valueLabel: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label).font(.subheadline.bold()).foregroundColor(.white)
                Spacer()
                Text(valueLabel).font(.caption.bold()).foregroundColor(tint).monospacedDigit()
            }
            Slider(value: $value, in: range).tint(tint)
        }
    }
}

// MARK: - Card View Modifier
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
extension View {
    func card() -> some View { modifier(CardModifier()) }
}
