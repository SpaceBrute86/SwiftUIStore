//
//  Store.swift
//  Copyright © 2022 Bobbie Markwick. All rights reserved.
//

import Foundation
import StoreKit


public typealias Transaction = StoreKit.Transaction
public enum StoreError: Error { case failedVerification }





public class Store: ObservableObject {

    @Published public private(set) var items: [Product] = []
    @Published public private(set) var purchases: [Product] = []
    @Published public private(set) var consumables: [Product] = []
    @Published public private(set) var subscriptions: [Product] = []
    @Published public private(set) var purchasedSubscriptions: [Product] = []
    

    private static var _shared:Store?
    public static var shared:Store { if _shared == nil {_shared = Store()}; return _shared! }
    
    //MARK: Configuration
    public struct Configuration{
        public static let NoAdsIdentifier = "NO_ADS"
        public static let ProductIdentifiers = "IDS"
        public static let SubscriptionGroupNames = "GROUPS"
    }
    public var productIDs:[String] = []
    public var groupNames:[String:String] = [:]
    public static func configure(_ config:[String:Any]){
        _shared = Store()
        //Start a transaction listener as close to app launch as possible so you don't miss any transactions.
        _shared?.updateListenerTask = _shared?.listenForTransactions()
        Task {
            if let str = config[Configuration.NoAdsIdentifier] as? String { _shared?.noAdsIdentifier = str }
            if let ids = config[Configuration.ProductIdentifiers] as? [String] { _shared?.productIDs = ids }
            if let groups = config[Configuration.SubscriptionGroupNames] as? [String:String] { _shared?.groupNames = groups }
            
            try? await _shared?.checkPurchaseVersion()

            await _shared?.requestProducts() //During store initialization, request products from the App Store.
            await _shared?.updateCustomerProductStatus()//Deliver products that the customer purchases.
            
        }
    }
    

    //MARK: Ad removal
    public var noAdsIdentifier = ""
    public var hasAdsRemoved:Bool { purchases.contains{$0.id == noAdsIdentifier} }
    
    
    //MARK: Listener
    var updateListenerTask: Task<Void, Error>? = nil
    deinit {  updateListenerTask?.cancel() }
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            //Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    //Deliver products to the user.
                    await self.updateCustomerProductStatus()
                    //Always finish a transaction.
                    await transaction.finish()
                } catch {
                    //StoreKit has a transaction that fails verification. Don't deliver content to the user.
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    //MARK: Load
    @MainActor
    func requestProducts() async {
        do {
            let storeProducts = try await Product.products(for: [noAdsIdentifier] + productIDs)
            //Sort each product category by price, lowest to highest, to update the store.
            items = storeProducts.filter{  $0.type == .nonConsumable }.sortedByPrice()
            consumables = storeProducts.filter {  $0.type == .consumable }.sortedByPrice()
            subscriptions = storeProducts.filter {  $0.type == .autoRenewable }.sortedByPrice()
        } catch {   print("Failed product request from the App Store server: \(error)") }
    }
    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedItems: [Product] = []
        var purchasedSubscriptions: [Product] = []

        //Iterate through all of the user's purchased products.
        for await result in Transaction.currentEntitlements {
            do {
                //Check whether the transaction is verified. If it isn’t, catch `failedVerification` error.
                let transaction = try checkVerified(result)
                //Check the `productType` of the transaction and get the corresponding product from the store.
                if transaction.productType == .nonConsumable, let item = items.first(where: { $0.id == transaction.productID }) {
                    purchasedItems.append(item)
                } else  if transaction.productType == .autoRenewable, let sub = subscriptions.first(where: { $0.id == transaction.productID }) {
                    purchasedSubscriptions.append(sub)
                }
            } catch { print() }
        }

        //Update the store information with the purchased products.
        self.purchases = purchasedItems
        self.purchasedSubscriptions = purchasedSubscriptions
    }

    //MARK: Make purchase
    public func purchase(_ product: Product) async throws -> Transaction? {
        //Begin purchasing the `Product` the user selects.
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            //Check whether the transaction is verified. If it isn't,
            //this function rethrows the verification error.
            let transaction = try checkVerified(verification)
            //The transaction is verified. Deliver content to the user.
            await updateCustomerProductStatus()
            //Always finish a transaction.
            await transaction.finish()
            return transaction
        case .userCancelled, .pending: return nil
        default: return nil
        }
    }

    public func isPurchased(_ product: Product) async throws -> Bool {
        switch product.type {
        case .nonConsumable: return purchases.contains(product)
        case .autoRenewable: return purchasedSubscriptions.contains(product)
        default: return false
        }
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified: throw StoreError.failedVerification
            //StoreKit parses the JWS, but it fails verification.
        case .verified(let safe): return safe
            //The result is verified. Return the unwrapped value.
        }
    }
    
    
    //MARK: App Version
    //Useful for changing Business model
    
    public private(set) var originalAppMajorVersion:Int?
    public private(set) var originalAppMinorVersion:Int?

    
    func checkPurchaseVersion() async throws {
        guard #available(iOS 16.0, *) else { return }
        let shared = try await AppTransaction.shared
        if case .verified(let appTransaction) = shared {
            let versionComponents = appTransaction.originalAppVersion.split(separator: ".")
            originalAppMajorVersion = Int(versionComponents[0])
            originalAppMinorVersion = Int(versionComponents[1])
        }
    
    }
    
}


public extension [Product] {
    func sortedByPrice() -> [Product] {
        self.sorted(by: { return $0.price < $1.price })
    }
}
