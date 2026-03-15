//
//  PaywallView.swift
//  TuneGenius
//
//  Premium subscription paywall
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreKitManager.self) private var store

    @State private var selectedProduct: Product?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let features: [(String, String)] = [
        ("waveform", "High-quality pitch shifting"),
        ("speedometer", "Full tempo range (25%–400%)"),
        ("slider.horizontal.3", "3-Band EQ"),
        ("sparkles", "Reverb, Echo & Effects"),
        ("square.and.arrow.up", "Lossless WAV & 256 kbps export"),
        ("repeat", "Unlimited loop markers"),
        ("arrow.counterclockwise", "Undo history"),
        ("icloud.and.arrow.up", "iCloud library sync"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                TGGradientBackground()
                ScrollView {
                    VStack(spacing: 28) {
                        headerSection
                        featuresSection
                        if store.isLoading { ProgressView().tint(.purple) }
                        else               { productsSection }
                        legalSection
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundColor(.secondary)
                    }
                }
            }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMessage ?? "") }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 52))
                .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))

            Text("TuneGenius Pro")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Unlock the full studio experience")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Features
    private var featuresSection: some View {
        VStack(spacing: 10) {
            ForEach(features, id: \.0) { (icon, text) in
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(.purple)
                        .frame(width: 28)
                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Products
    private var productsSection: some View {
        VStack(spacing: 12) {
            ForEach(store.products) { product in
                ProductRow(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    action: { selectedProduct = product }
                )
            }

            // CTA
            Button {
                guard let p = selectedProduct ?? store.products.first else { return }
                Task { await purchase(p) }
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Continue")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isLoading)
        }
        .onAppear {
            if selectedProduct == nil { selectedProduct = store.products.first }
        }
    }

    // MARK: - Legal
    private var legalSection: some View {
        VStack(spacing: 8) {
            Button("Restore Purchases") {
                Task { await store.restorePurchases() }
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            Text("Subscriptions auto-renew. Cancel anytime in App Store settings.\nBy continuing you agree to our Terms & Privacy Policy.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Purchase
    private func purchase(_ product: Product) async {
        isLoading = true
        do {
            try await store.purchase(product)
            dismiss()
        } catch TGStoreError.userCancelled {
            // silent
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - ProductRow
struct ProductRow: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    if let period = product.subscription?.subscriptionPeriod {
                        Text(period.debugDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .purple)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .purple : .secondary)
            }
            .padding()
            .background(isSelected ? Color.purple.opacity(0.25) : Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
