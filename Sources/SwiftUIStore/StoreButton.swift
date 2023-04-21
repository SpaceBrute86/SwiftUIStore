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
