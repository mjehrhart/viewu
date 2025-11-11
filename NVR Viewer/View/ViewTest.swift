//
//  ViewTest.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/5/24.
//

import SwiftUI

struct ViewTest: View {
    
    let title: String
    let fontSize: CGFloat = 25
    let dateSpacer: CGFloat = (UIScreen.screenWidth-0)/4
    //let buttonWidth = UIScreen.screenWidth/4
    init(title: String){
        self.title = title
    }
    
    var body: some View {
        ScrollView(.horizontal){
            HStack(alignment: .center, spacing: 2) {
                Text("11/2")
                    .font(.system(size: fontSize))
                    .fontWeight(.light)
                    .foregroundColor(.gray)
                    .frame(width: dateSpacer, height: 20)
                Text("11/3")
                    .font(.system(size: fontSize))
                    .fontWeight(.light)
                    .foregroundColor(.gray)
                    .frame(width: dateSpacer, height: 20)
                Text("11/4")
                    .font(.system(size: fontSize))
                    .fontWeight(.light)
                    .foregroundColor(.gray)
                    .frame(width: dateSpacer, height: 20)
                Text("11/5")
                    .font(.system(size: fontSize))
                    .fontWeight(.light)
                    .foregroundColor(.gray)
                    .frame(width: dateSpacer, height: 20)
                Text("11/6")
                    .font(.system(size: fontSize))
                    .fontWeight(.light)
                    .foregroundColor(.gray)
                    .frame(width: dateSpacer, height: 20)
                Text("11/7")
                    .font(.system(size: fontSize))
                    .fontWeight(.light)
                    .foregroundColor(.gray)
                    .frame(width: dateSpacer, height: 20)
                Text("11/8")
                    .font(.system(size: fontSize))
                    .fontWeight(.light)
                    .foregroundColor(.gray)
                    .frame(width: dateSpacer, height: 20)
                Text("11/9")
                    .font(.system(size: fontSize))
                    .fontWeight(.light)
                    .foregroundColor(.gray)
                    .frame(width: dateSpacer, height: 20)
                Text("11/10")
                    .font(.system(size: fontSize))
                    .fontWeight(.light)
                    .foregroundColor(.gray)
                    .frame(width: dateSpacer, height: 20) 
                
                //            Button{
                //                UIPasteboard.general.string = "Hello world"
                //            } label: {
                //                Image(systemName: "doc.on.doc")
                //            }
            }
            .frame(width: .infinity, height: 40)
        }
        .defaultScrollAnchor(.trailing)
        //.navigationBarTitle(title, displayMode: .inline)
    }
}

//#Preview {
//    ViewTest()
//}
