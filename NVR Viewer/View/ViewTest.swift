//
//  ViewTest.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/5/24.
//

import SwiftUI

struct ViewTest: View {
    
    let title: String
    init(title: String){
        self.title = title
    }
    
    var body: some View {
        VStack { 
            Text(title)
            Button{
                UIPasteboard.general.string = "Hello world"
            } label: {
                Image(systemName: "doc.on.doc")
            } 
        }
        //.isDetailLink(false)
         
        .navigationBarTitle(title, displayMode: .inline)
    }
}

//#Preview {
//    ViewTest()
//}
