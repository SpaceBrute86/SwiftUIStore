//
//  File.swift
//  
//
//  Created by Bobbie Markwick on 30/06/22.
//

import SwiftUI
import StoreKit


public struct MonetizedWindowGroup<Content:View>:Scene {
    public init(configuration:[String:Any],content:@escaping ()->Content){
        Store.configure(configuration)
        self.content = content
    }

    @StateObject private var store: Store = Store.shared
    private var content: ()->Content
    
    @SceneBuilder public var body: some Scene{
        WindowGroup { content().environmentObject(store) }
    }
}
