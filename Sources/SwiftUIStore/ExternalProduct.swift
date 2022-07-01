//
//  File.swift
//  
//
//  Created by Bobbie Markwick on 30/06/22.
//

import SwiftUI

public struct ExternalProduct<Content:View>: Identifiable {
    public var identifier:Int
    public var label:()->Content
    
    init(identifier:Int, label:@escaping ()->Content){
        self.identifier = identifier
        self.label = label
    }
    public var id:Int{ identifier }
}

#if os(iOS)
import SwiftUIX
import StoreKit

struct ProductButton<Content:View>: View {
    
    init(product:StoreProduct<Content>){
        self.label = product.label
        page = ProductPage(identifier: product.identifier)
    }

    private var page:ProductPage!
    private var label:()->Content

    var body: some View{  Button(action: { page.present() }, label: label) }
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
