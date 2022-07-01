import SwiftUI
//import SwiftUIX
import StoreKit


public struct StoreButton:View{
    @State private var showingPurchase = false
    
    private var externals:[ExternalProduct]
    public init(externalProducts:[ExternalProduct]){ externals = externalProducts }
    
    public var body: some View {
        Button(action: { showingPurchase = true }, label: {Image(systemName: "cart")}).font(.title2).padding().sheet(isPresented: $showingPurchase){
            NavigationView{ StoreView(externalProducts: externals) }
        }
    }
}
