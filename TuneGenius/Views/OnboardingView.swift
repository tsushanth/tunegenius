//
//  OnboardingView.swift
//  TuneGenius
//
//  3-page onboarding with permission request
//

import SwiftUI
import MediaPlayer

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "waveform.circle.fill",
            iconColor: .purple,
            title: "Welcome to TuneGenius",
            subtitle: "The professional vocal pitch & speed studio on your iPhone.",
            cta: "Get Started"
        ),
        OnboardingPage(
            icon: "slider.horizontal.3",
            iconColor: .cyan,
            title: "Shape Your Sound",
            subtitle: "Shift pitch by semitones, change tempo without affecting pitch, and polish with studio-grade EQ & effects.",
            cta: "Next"
        ),
        OnboardingPage(
            icon: "crown.fill",
            iconColor: .yellow,
            title: "Go Pro",
            subtitle: "Unlock lossless export, full effects suite, and unlimited loop markers with TuneGenius Pro.",
            cta: "Start Free Trial"
        ),
    ]

    var body: some View {
        ZStack {
            TGGradientBackground()
            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0 ..< pages.count, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i == page ? Color.purple : Color.white.opacity(0.25))
                            .frame(width: i == page ? 24 : 8, height: 4)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.top, 60)

                Spacer()

                // Content
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                        pageContent(p).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                Spacer()

                // CTA
                Button {
                    withAnimation {
                        if page < pages.count - 1 {
                            page += 1
                        } else {
                            finish()
                        }
                    }
                } label: {
                    Text(pages[page].cta)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 32)
                }

                Button("Skip") { finish() }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
            }
        }
    }

    @ViewBuilder
    private func pageContent(_ p: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Image(systemName: p.icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(colors: [p.iconColor, p.iconColor.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: p.iconColor.opacity(0.4), radius: 20)

            VStack(spacing: 12) {
                Text(p.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(p.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding()
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "tg_onboarding_done")
        isPresented = false
    }
}

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let cta: String
}
