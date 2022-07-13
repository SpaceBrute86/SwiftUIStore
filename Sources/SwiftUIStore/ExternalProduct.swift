//
//  File.swift
//  
//
//  Created by Bobbie Markwick on 30/06/22.
//

import SwiftUI
import StoreKit

public struct ExternalProduct: Identifiable {
    public var identifier:Int
    public var name:String
    public var icon:String
    
    public init(identifier:Int, name:String, icon:String){
        self.identifier = identifier
        self.name = name; self.icon = icon
    }
    public var id:Int{ identifier }
}

#if os(iOS)

public struct ProductButton: View {
    
    init(product:ExternalProduct){
        self.name = product.name; self.icon = product.icon
        page = ProductPage(identifier: product.identifier)
    }

    private var page:ProductPage!
    private var name:String
    private var icon:String

    var body: some View{
        Button(action: { page.present() }){
            HStack{
                Text(name)
                Spacer()
                Image(icon).resizable().scaledToFit().frame(height: 50)
            }
        }
    }
}

final private class ProductPage:NSObject, SKStoreProductViewControllerDelegate {
    var identifier:Int = 0
    private var viewController = UIViewController()
    private var storeVC = SKStoreProductViewController()
    init(identifier:Int ) { self.identifier = identifier }
    
    func present(){
        let params = [  SKStoreProductParameterITunesItemIdentifier:self.identifier ] as [String : Any]
        storeVC.delegate = self
        storeVC.loadProduct(withParameters: params) {
            guard $0 else { print($1?.localizedDescription ?? ""); return }
            guard var vc = (UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene)?.windows.first?.rootViewController  else { print ("no vc"); return }
            while let pvc = vc.presentedViewController { vc = pvc }
            vc.present(self.storeVC, animated: true)
        }
    }
}

#endif
