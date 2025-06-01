import SwiftUI
import StoreKit


public struct StoreButton:View{
    @State private var showingPurchase = false
    
    @State private var titleString:String
    @State private var imageName:String

    
    private var externals:[ExternalProduct]
    public init(externalProducts:[ExternalProduct], title:String = "", systemImage:String = "cart"){
        externals = externalProducts;
        titleString = title
        imageName = systemImage
    }
    
    public var body: some View {
        Button(action: { showingPurchase = true }, label: {
            if !titleString.isEmpty {  Text(titleString) } else { Image(systemName: imageName) }
        }).font(.title2).padding().sheet(isPresented: $showingPurchase){
            #if os(iOS)
            navView.toolbar{ ToolbarItemGroup(placement: .navigationBarLeading){
                Button(action: {showingPurchase = false}, label: {Image(systemName: "chevron.backward")})
            }}
            #elseif os(macOS)
            navView.toolbar{ ToolbarItemGroup(placement: .navigation){
                Button(action: {showingPurchase = false}, label: {Image(systemName: "chevron.backward")})
            }}.frame(minHeight: 300)
            #endif
        }
    }
    @ViewBuilder var navView: some View {
        if #available(iOS 16.0, macOS 13.0, watchOS 9.0, *) {
            NavigationStack{ StoreView(externalProducts: externals) }
        } else {
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
