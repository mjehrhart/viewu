//
//  ViewLog.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/3/24.
//

import SwiftUI

struct User: Identifiable {
    let id: Int
    var name: String
    var score: Int
    var page: String
}

struct ViewLog: View {
    
    var list: [LogItem] = []
    
    @State private var users = [
        User(id: 1, name: "Taylor Swift", score: 95, page: "MQTTSTATE"),
        User(id: 2, name: "Justin Bieber", score: 80, page: "ContentView"),
        User(id: 3, name: "Adele Adkins", score: 85, page: "EventStorage")
    ]
    
    init() {
        self.list = Log.shared().getList()
    }
    var body: some View {
 
        VStack{
            ScrollView{
                ForEach(list, id: \.self) { row in
                    
                    HStack{
                        Text(row.type)
                            .font(.caption)
                            .frame(width: 50, alignment: .topLeading)
                        Divider().frame(width: 1)
                        Text(row.page)
                            .font(.caption)
                            .frame(width: 100, alignment: .topLeading)
                        Divider().frame(width: 1)
                        Text(row.fn)
                            .font(.caption)
                            .frame( maxWidth: .infinity, alignment: .topLeading) //changed from width
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .topLeading)
                    
                    Text(row.text)
                        .font(.callout)
                        .frame(width: UIScreen.screenWidth, alignment: .topLeading)
                        .textSelection(.enabled)
                    
                    Divider()
                }
            }
            .frame(width: UIScreen.screenWidth, alignment: .topLeading)
        }
        .padding([.leading, .trailing], 5)
        .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight - 140, alignment: .topLeading) 
    }
}

#Preview {
    ViewLog()
}
