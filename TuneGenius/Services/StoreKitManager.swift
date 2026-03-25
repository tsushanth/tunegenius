//
//  StoreKitManager.swift
//  TuneGenius
//
//  StoreKit 2 subscription manager
//

import Foundation
import StoreKit

// MARK: - Product Identifiers
enum TGProductID: String, CaseIterable {
    case monthly  = "com.appfactory.tunegenius.subscription.monthly"
    case yearly   = "com.appfactory.tunegenius.subscription.yearly"
    case lifetime = "com.appfactory.tunegenius.lifetime"

    var displayName: String {
        switch self {
        case .monthly:  return "Monthly"
        case .yearly:   return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    static var allIDs: [String] { allCases.map(\.rawValue) }
}

// MARK: - Purchase State
enum PurchaseState: Equatable {
    case idle, loading, purchasing, purchased
    case failed(String)
    case pending, cancelled
}

// MARK: - StoreKit Error
enum TGStoreError: LocalizedError {
    case productNotFound, verificationFailed, userCancelled, pending, unknown
    case purchaseFailed(Error)

    var errorDescription: String? {
        switch self {
        case .productNotFound:    return "Product not found."
        case .verificationFailed: return "Purchase verification failed."
        case .userCancelled:      return "Purchase cancelled."
        case .pending:            return "Purchase pending approval."
        case .unknown:            return "Unknown error."
        case .purchaseFailed(let e): return e.localizedDescription
        }
    }
}

// MARK: - Manager
@MainActor
@Observable
final class StoreKitManager {

    private(set) var products: [Product] = []
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var purchasedIDs: Set<String> = []

    private var updateTask: Task<Void, Error>?

    var isPremium: Bool { !purchasedIDs.isEmpty }

    init() {
        updateTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    func loadProducts() async {
        isLoading = true
        do {
            let fetched = try await Product.products(for: TGProductID.allIDs)
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func purchase(_ product: Product) async throws {
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let v):
                let tx = try verified(v)
                await refreshEntitlements()
                await tx.finish()
                purchaseState = .purchased
            case .userCancelled:
                purchaseState = .cancelled
                throw TGStoreError.userCancelled
            case .pending:
                purchaseState = .pending
                throw TGStoreError.pending
            @unknown default:
                throw TGStoreError.unknown
            }
        } catch TGStoreError.userCancelled { throw TGStoreError.userCancelled
        } catch TGStoreError.pending       { throw TGStoreError.pending
        } catch {
            purchaseState = .failed(error.localizedDescription)
            throw TGStoreError.purchaseFailed(error)
        }
    }

    func restorePurchases() async {
        purchaseState = .loading
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            purchaseState = isPremium ? .purchased : .idle
        } catch {
            errorMessage = error.localizedDescription
            purchaseState = .failed(errorMessage ?? "")
        }
    }

    func refreshEntitlements() async {
        var ids: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let tx = try? verified(result), tx.revocationDate == nil {
                ids.insert(tx.productID)
            }
        }
        purchasedIDs = ids
    }

    nonisolated private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw TGStoreError.verificationFailed
        case .verified(let v): return v
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let tx = try? self?.verified(result) {
                    await self?.refreshEntitlements()
                    await tx.finish()
                }
            }
        }
    }
}
