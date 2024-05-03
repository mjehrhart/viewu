//
//  ViewEventDetail.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//
//  Depreciated

import SwiftUI
import AVKit
import SwiftData

struct ViewEventDetail: View {
    
    let text: String
    let container: EndpointOptions
    
    @State private var player = AVPlayer()
    @State private var path = NavigationPath()
    
    //
    @EnvironmentObject private var notificationManager2: NotificationManager
    @State var selection: Int = 0
    @State var showButton: Bool
    
    init(text: String, container: EndpointOptions, player: AVPlayer = AVPlayer(), path: NavigationPath = NavigationPath(), showButton: Bool) {
        self.text = text
        self.container = container
        self.player = player
        self.path = path
        self.showButton = showButton
    }
    
    var body: some View {
        VStack(alignment: .trailing){
             
            ScrollView {
                HStack{
                    
                    if showButton {
                        Button {
                            self.selection = 0
                            notificationManager2.newPage = 0
                        } label: {
                            Label("Timeline", systemImage: "chevron.left")
                                //.font(.title3)
                        }
                        .frame(width: 90, alignment: .leading)
                        .padding(20)
                    }
                     
                    Label("Camera \(container.cameraName!.capitalized)", systemImage: "web.camera")
                        .frame( alignment: .leading)
                        .padding()
                        //.background(.blue, in: RoundedRectangle(cornerRadius: 5))
                    Label("\(container.label!.capitalized)", systemImage: "figure.walk.motion")
                        .frame(alignment: .trailing)
                        .padding()
                        //.background(.blue, in: RoundedRectangle(cornerRadius: 5))
                }
                //.padding(.bottom, 10)
                .padding(.top, 0)
                 
                
                HStack{
                    Text("Video Clip")
                        .frame(width:UIScreen.screenWidth/2 - 18, alignment: .leading)
                        .padding(10)
                    
                    Label("", systemImage: "speaker")
                        .padding(10)
                        .frame(width:UIScreen.screenWidth/2 - 18, alignment: .trailing)
                }
                //.background(.blue, in: RoundedRectangle(cornerRadius: 5) )
                 
                ViewPlayVideo(urlString: container.m3u8!)
                    .modifier(CardBackground())
                    .padding(0)
                 
                if let _ = container.m3u8{
                    HStack{
                        Button{
                            UIPasteboard.general.string = container.m3u8!
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .frame(width: 340, alignment: .trailing)
                        
                        ShareLink(item: container.m3u8!, preview: SharePreview("NVR Video Clip", image: container.m3u8!)){
                            Image(systemName: "square.and.arrow.up")
                        }
                        .frame(alignment: .trailing)
                    }
                }
                Spacer().frame(height:20)
                
                Text("Snapshot")
                    .frame(width: UIScreen.screenWidth-30, alignment: .leading)
                    .padding(10)
                    //.background(.blue, in: RoundedRectangle(cornerRadius: 5))
                
                ViewUIImageFull(urlString: container.snapshot!)
                    .modifier(CardBackground())
                    .padding(0)
                
                if let _ = container.snapshot{
                    HStack{
                        Button{
                            UIPasteboard.general.string = container.snapshot!
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .frame(width: 340, alignment: .trailing)
                        
                        ShareLink(item: container.snapshot!, preview: SharePreview("NVR Video Clip", image: container.snapshot!)){
                            Image(systemName: "square.and.arrow.up")
                        }
                        .frame(alignment: .trailing)
                    }
                }
                
                ViewEventSlideShow(eventId: container.id!)
                
                //This is a comment in misc
                //new comment
                
                Spacer()
            }
        }
        .navigationTitle(text)
    }
}


//#Preview {
//    ViewEventDetail(frameTime: 1710541384.496615)
//        .modelContainer(for: ImageContainer.self)
//}
