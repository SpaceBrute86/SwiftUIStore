import SwiftUI
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

public struct StoreNavigationLink:View{
    @State private var title = "Store"
    
    private var externals:[ExternalProduct]
    public init(title:String, externalProducts:[ExternalProduct]){ self.title = title; externals = externalProducts }
    
    public var body: some View {
        NavigationLink(title){ StoreView(externalProducts: externals) } 
    }
}
