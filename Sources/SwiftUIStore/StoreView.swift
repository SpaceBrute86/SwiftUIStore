//
//  SwiftUIView.swift
//  
//
//  Created by Bobbie Markwick on 30/06/22.
//

import SwiftUI
import StoreKit

struct StoreView: View {
    
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private var externals:[ExternalProduct]
    init(externalProducts:[ExternalProduct]){ externals = externalProducts }

    var body: some View {
        List {
            SubscriptionsView()
            
            if !(store.items.isEmpty && store.consumables.isEmpty){
                Section("In App Purchases") {
                    ForEach(store.items) { item in
                        ListCellView(product: item)
                    }
                    ForEach(store.consumables) { item in
                        ListCellView(product: item)
                    }
                }
            }
            if !(store.subscriptions.isEmpty && store.items.isEmpty){
                Button("Restore Purchases", action: { Task {  try? await AppStore.sync() }  })
            }
            #if os(iOS)
            if !externals.isEmpty {
                Section("More apps"){
                    ForEach(externals){  ProductButton(product: $0) }
                }
            }
            #endif

        }.navigationTitle("Store")
        #if !os(watchOS)
        .toolbar{
            ToolbarItemGroup(placement: .navigationBarLeading){Button(action: {dismiss()}, label: {Image(systemName: "chevron.backward")}) }
        }
        #endif
       
    }
}


struct ListCellView: View {
    @EnvironmentObject var store: Store
    @State var isPurchased: Bool = false
    @State var errorTitle = ""
    @State var isShowingError: Bool = false

    let product: Product
    let purchasingEnabled: Bool

    init(product: Product, purchasingEnabled: Bool = true) {
        self.product = product
        self.purchasingEnabled = purchasingEnabled
    }

    var body: some View {
        HStack {
            Text(product.displayName).frame(alignment: .leading)
            if purchasingEnabled {
                Spacer()
                buyButton.buttonStyle(BuyButtonStyle(isPurchased: isPurchased)).disabled(isPurchased)
            }
        }.alert(errorTitle, isPresented: $isShowingError){}
    }

    var buyButton: some View {
        Button(action: { Task { await buy()} } ){
            if isPurchased { Text(Image(systemName: "checkmark")).bold().foregroundColor(.white) }
            else {  Text(product.displayPrice).foregroundColor(.white).bold() }
        }.onAppear { Task { isPurchased = (try? await store.isPurchased(product)) ?? false } }
    }

    func buy() async {
        do {
            if try await store.purchase(product) != nil { withAnimation { isPurchased = true } }
        } catch StoreError.failedVerification {
            errorTitle = "Your purchase could not be verified by the App Store."
            isShowingError = true
        } catch {
            print("Failed purchase for \(product.id): \(error)")
        }
    }
}
struct BuyButtonStyle: ButtonStyle {
    let isPurchased: Bool
    init(isPurchased: Bool = false) { self.isPurchased = isPurchased }
    func makeBody(configuration: Self.Configuration) -> some View {
        var bgColor: Color = isPurchased ? Color.green : Color.blue
        bgColor = configuration.isPressed ? bgColor.opacity(0.7) : bgColor.opacity(1)

        return configuration.label.padding(10).background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
    }
}

