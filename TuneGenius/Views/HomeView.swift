//
//  HomeView.swift
//  TuneGenius
//
//  Hero screen shown after onboarding – quick-action landing pad
//

import SwiftUI

struct HomeView: View {
    @Environment(StoreKitManager.self) private var store
    @Binding var selectedTab: AppTab

    var body: some View {
        NavigationStack {
            ZStack {
                TGGradientBackground()
                ScrollView {
                    VStack(spacing: 28) {
                        headerSection
                        quickActionsGrid
                        if !store.isPremium { premiumBanner }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading) {
                    Text("TuneGenius")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing)
                        )
                    Text("Vocal Pro Studio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if store.isPremium {
                    Label("PRO", systemImage: "crown.fill")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Quick Actions
    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            QuickActionCard(icon: "music.note.list", title: "My Library", subtitle: "Browse tracks", color: .purple) {
                selectedTab = .library
            }
            QuickActionCard(icon: "waveform", title: "Pitch & Tempo", subtitle: "Edit audio", color: .cyan) {
                selectedTab = .library
            }
            QuickActionCard(icon: "slider.horizontal.3", title: "EQ & Effects", subtitle: "Shape your sound", color: .orange) {
                selectedTab = .library
            }
            QuickActionCard(icon: "square.and.arrow.up", title: "Export", subtitle: "Save your edit", color: .green) {
                selectedTab = .library
            }
        }
    }

    // MARK: - Premium Banner
    private var premiumBanner: some View {
        NavigationLink(destination: PaywallView()) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                VStack(alignment: .leading) {
                    Text("Unlock TuneGenius Pro")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("High-quality export, all effects & more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.yellow.opacity(0.4), lineWidth: 1))
        }
    }
}

// MARK: - QuickActionCard
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.bold()).foregroundColor(.white)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
