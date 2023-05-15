//
//  File.swift
//  
//
//  Created by Bobbie Markwick on 16/04/23.
//

import SwiftUI
import StoreKit


typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState


    

struct SubscriptionsView: View {
    @EnvironmentObject var store: Store

    @State var currentSubscriptions: [(Product, Product.SubscriptionInfo.Status)] = []

    var availableSubscriptions: [(String,String, [Product])] {
        var groups:[(String,String,[Product])] = []
        let inactiveSubs = store.subscriptions.filter{ product in !currentSubscriptions.map{$0.0.id}.contains(where: {$0 == product.id}) }
        for (groupID, displayName) in store.groupNames {
            let products = inactiveSubs.filter { $0.subscription?.subscriptionGroupID == groupID }
           // guard products.isEmpty else {continue}
            groups += [(displayName.0,displayName.1, products)]
        }
        return groups
    }

    var body: some View {
        Group{
            if !currentSubscriptions.isEmpty {
                Section("My Subscriptions"){
                    ForEach(currentSubscriptions, id: \.0){ product in
                        ActiveSubscriptionCellView(product: product.0, status: product.1)
                    }
                }.listStyle(GroupedListStyle())
                ForEach(currentSubscriptions, id: \.1){ product in
                    SubscriptionStatusInfoView(product: product.0, status: product.1)
                }
            }
            ForEach(availableSubscriptions, id: \.2){ group in
                Section(group.0){
                    if group.2.isEmpty {
                        Text("Error Loading Products")
                    } else {
                        ForEach(group.2){ product in
                            ListCellView(product: product)
                        }
                    }
                }
                Text(group.1)
            }
        }
        .onAppear{Task{await updateSubscriptionStatus()}}
       // .onChange(of: store.purchasedSubscriptions){Task{await updateSubscriptionStatus()}}
    }

    @MainActor
    func updateSubscriptionStatus() async {
        for (groupID,_) in store.groupNames {
            let product = store.subscriptions.first(where: {$0.subscription?.subscriptionGroupID == groupID})
            guard let statuses = try? await product?.subscription?.status else {  continue }
            var highestProduct: Product? = nil
            
            //Iterate through `statuses` for this subscription group and find
            //the `Status` with the highest level of service that isn't
            //in an expired or revoked state. For example, a customer may be subscribed to the
            //same product with different levels of service through Family Sharing.
            for status in statuses where status.state != .expired && status.state != .revoked {
                guard let renewalInfo = try? store.checkVerified(status.renewalInfo) else { continue }
                //Find the first subscription product that matches the subscription status renewal info by comparing the product IDs.
                guard let newSubscription = store.subscriptions.first(where: { $0.id == renewalInfo.currentProductID }) else { continue }
                guard let currentProduct = highestProduct else { highestProduct = newSubscription; continue }
                if newSubscription.price > currentProduct.price {  highestProduct = newSubscription }
            }
        }
    }
}






struct ActiveSubscriptionCellView: View {
    @EnvironmentObject var store: Store
    
    let product: Product
    let status: Product.SubscriptionInfo.Status?
    @State var renewalDate:Date?

    init(product: Product, status: Product.SubscriptionInfo.Status?) {
        self.product = product
        self.status = status
        guard case .verified(let renewal) = status?.renewalInfo,
              case .verified(let transaction) = status?.transaction else { return }
        renewalDate = renewal.willAutoRenew ? transaction.expirationDate : nil
    }
    
    var body: some View {
        HStack {
            Text(product.displayName).frame(alignment: .leading)
            if let date = renewalDate?.formatted() {
                Spacer()
                Text("Renews \(date)").font(.caption)
            }
        }
    }
}

struct SubscriptionStatusInfoView: View {
    @EnvironmentObject var store: Store

    let product: Product
    let status: Product.SubscriptionInfo.Status

    var body: some View {
        let description = statusDescription()
        if description.isEmpty{ EmptyView()  }
        else { Text(description).multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .center) }
    }

    //Build a string description of the subscription status to display to the user.
    fileprivate func statusDescription() -> String {
        guard case .verified(let renewalInfo) = status.renewalInfo,
              case .verified(let transaction) = status.transaction else {
            return "The App Store could not verify your subscription status for \(product.displayName)."
        }

        var description = ""

        switch status.state {
        case .expired:
            if let expirationDate = transaction.expirationDate, let expirationReason = renewalInfo.expirationReason {
                description = expirationDescription(expirationReason, expirationDate: expirationDate)
            }
        case .revoked:
            if let revokedDate = transaction.revocationDate?.formatted() {
                description = "The App Store refunded your subscription to \(product.displayName) on \(revokedDate)."
            }
        case .inGracePeriod:  description = gracePeriodDescription(renewalInfo)
        case .inBillingRetryPeriod: description = billingRetryDescription()
        default:
            break
        }

        if let expirationDate = transaction.expirationDate,  let newProductID = renewalInfo.autoRenewPreference {
            if let newProduct = store.subscriptions.first(where: { $0.id == newProductID }) {
                description += "\nYour subscription to \(newProduct.displayName)  will begin when your subscription to \(product.displayName) expires on \(expirationDate.formatted())."
            }
        }
        return description
    }

    fileprivate func billingRetryDescription() -> String {
        var description = "The App Store could not confirm your billing information for \(product.displayName)."
        description += " Please verify your billing information to resume service."
        return description
    }

    fileprivate func gracePeriodDescription(_ renewalInfo: RenewalInfo) -> String {
        var description = "The App Store could not confirm your billing information for \(product.displayName)."
        if let untilDate = renewalInfo.gracePeriodExpirationDate?.formatted() {
            description += " Please verify your billing information to continue service after \(untilDate)"
        }

        return description
    }
    
    fileprivate func renewalDescription(_ renewalInfo: RenewalInfo, _ expirationDate: Date) -> String {
        var description = ""

        if let newProductID = renewalInfo.autoRenewPreference {
            if let newProduct = store.subscriptions.first(where: { $0.id == newProductID }) {
                description += "\nYour subscription to \(newProduct.displayName)"
                description += " will begin when your current subscription expires on \(expirationDate.formatted())."
            }
        }
        return description
    }

    //Build a string description of the `expirationReason` to display to the user.
    fileprivate func expirationDescription(_ expirationReason: RenewalInfo.ExpirationReason, expirationDate: Date) -> String {
        var description = "Your subscription to \(product.displayName) was not renewed"

        switch expirationReason {
        case .autoRenewDisabled:
            if expirationDate > Date() {
                description = "Your subscription to \(product.displayName) will expire on \(expirationDate.formatted())."
            } else {
                description = "Your subscription to \(product.displayName) expired on \(expirationDate.formatted())."
            }
        case .billingError:  description += " due to a billing error."
        case .didNotConsentToPriceIncrease: description = " due to a price increase that you disapproved."
        case .productUnavailable: description += " because the product is no longer available."
        default: break
        }

        return description
    }
}

