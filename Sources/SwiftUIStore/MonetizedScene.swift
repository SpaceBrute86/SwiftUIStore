//
//  File.swift
//  
//
//  Created by Bobbie Markwick on 30/06/22.
//

import SwiftUI
import StoreKit


public struct MonetizedWindowGroup<Content:View>:Scene {
    public init(@escaping content:()->Content){ self.content = content }

    @StateObject private var store: Store = Store.shared
    private var content: ()->Content
    
    @SceneBuilder public var body: some Scene{
        WindowGroup { content().environmentObject(store) }
    }
}
