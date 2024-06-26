//
//  ViewLive.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/28/24.
//

import SwiftUI
import AVKit

struct ViewLive: View {
    
    let text: String
    let container: EndpointOptions
    
    @State private var player = AVPlayer()
    @State private var path = NavigationPath()
    
    //
    @EnvironmentObject private var notificationManager2: NotificationManager
    @State var selection: Int = 0
    
    init(text: String, container: EndpointOptions, player: AVPlayer = AVPlayer(), path: NavigationPath = NavigationPath(), showButton: Bool) {
        self.text = text
        self.container = container
        self.player = player
        self.path = path
    }
    
    var body: some View {
        VStack(alignment: .leading){
            ScrollView {
 
                ViewLiveLandscape(urlString: container.snapshot!, cameraName: container.cameraName! ,zoomIn: false)
                    .padding([.top], 147)
                
//                if let _ = container.snapshot{
//                    
//                    HStack{
//                        Button{
//                            UIPasteboard.general.string = container.snapshot!
//                        } label: {
//                            Image(systemName: "doc.on.doc")
//                        }
//                        .frame(width: 340, alignment: .trailing)
//                        
//                        ShareLink(item: container.snapshot!, preview: SharePreview("NVR Image", image: container.snapshot!)){
//                            Image(systemName: "square.and.arrow.up")
//                        }
//                        .frame(alignment: .trailing)
//                    }
//                }
                 
            }
        } 
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                
                Label("Timeline", systemImage: "chevron.left")
                    .labelStyle(HorizontalLabelStyle())
                    .foregroundStyle(.blue)
                    .onTapGesture(perform: {
                        self.selection = 0
                        notificationManager2.newPage = 0
                    })
            }
        }
        .navigationBarTitle(text, displayMode: .inline)
    }
}
 

//#Preview {
//    ViewLive(text: convertDateTime(time: 1710541384.496615), container: EndpointOptions(), showButton: true)
//}
 
