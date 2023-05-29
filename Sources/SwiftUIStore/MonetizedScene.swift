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

@available(iOS 16.0, macOS 13.0, *)
public struct MonetizedDocumentGroup<Content:View, Document:FileDocument>:Scene {
    public init(configuration:[String:Any], newDocument:@escaping()->Document, editor:@escaping (FileDocumentConfiguration<Document>)->Content){
        Store.configure(configuration)
        self.newDocument = newDocument
        self.editor = editor
    }

    @StateObject private var store: Store = Store.shared
    private var newDocument:()->Document
    private var editor: (FileDocumentConfiguration<Document>)->Content

    @SceneBuilder public var body: some Scene{
        DocumentGroup(newDocument: newDocument(), editor: { editor($0).environmentObject(store) })
    }
}

@available(iOS 16.0, macOS 13.0, *)
public struct MonetizedReferenceDocumentGroup<Content:View, Document:ReferenceFileDocument>:Scene {
    public init(configuration:[String:Any], newDocument:@escaping()->Document, editor:@escaping (ReferenceFileDocumentConfiguration<Document>)->Content){
        Store.configure(configuration)
        self.newDocument = newDocument
        self.editor = editor
    }

    @StateObject private var store: Store = Store.shared
    private var newDocument:()->Document
    private var editor: (ReferenceFileDocumentConfiguration<Document>)->Content

    @SceneBuilder public var body: some Scene{
        DocumentGroup(newDocument: newDocument, editor: { editor($0).environmentObject(store) })
    }
}
