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
    
    //, player: AVPlayer = AVPlayer()
    init(text: String, container: EndpointOptions, path: NavigationPath = NavigationPath(), showButton: Bool) {
        self.text = text
        self.container = container
//        self.player = player
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
                        }
                        .frame(width: 90, alignment: .leading)
                        .padding(20)
                    }
                     
                    Label("Camera \(container.cameraName!.capitalized)", systemImage: "web.camera")
                        .frame( alignment: .leading)
                        .padding()
                    Label("\(container.label!.capitalized)", systemImage: "figure.walk.motion")
                        .frame(alignment: .trailing)
                        .padding()
                }
                .padding(.top, 0)
                 
                
                HStack{
                    Text("Video Clip")
                        .frame(width:UIScreen.screenWidth - 30, alignment: .leading)
                        .padding(10)
                }
                 
                if( container.m3u8 != nil ){
                    if( container.m3u8! != nil ){
                        ViewPlayVideo(urlString: container.m3u8!)
                            .modifier(CardBackground())
                            .padding(0)
                            .overlay(CameraOverlayVideoClip(toCopy: container.m3u8! ), alignment: .bottomTrailing)
                         
        //                if let _ = container.m3u8{
        //                    HStack{
        //                        Button{
        //                            UIPasteboard.general.string = container.m3u8!
        //                        } label: {
        //                            Image(systemName: "doc.on.doc")
        //                        }
        //                        .frame(width: 340, alignment: .trailing)
        //
        //                        ShareLink(item: container.m3u8!, preview: SharePreview("NVR Video Clip", image: container.m3u8!)){
        //                            Image(systemName: "square.and.arrow.up")
        //                        }
        //                        .frame(alignment: .trailing)
        //                    }
        //                }
                    }
                }
 
                Spacer().frame(height:20)
                
                Text("Snapshot")
                    .frame(width: UIScreen.screenWidth-30, alignment: .leading)
                    .padding(10)
                
                ViewUIImageFull(urlString: container.snapshot!)
                    .modifier(CardBackground())
                    .padding(0)
                    .overlay(CameraOverlaySnapShot(toCopy: container.snapshot! ), alignment: .bottomTrailing)
                 
//                if let _ = container.snapshot{
//                    HStack{
//                        Button{
//                            UIPasteboard.general.string = container.snapshot!
//                        } label: {
//                            Image(systemName: "doc.on.doc")
//                        }
//                        .frame(width: 340, alignment: .trailing)
//                        
//                        ShareLink(item: container.snapshot!, preview: SharePreview("Viewu Clip", image: container.snapshot!)){
//                            Image(systemName: "square.and.arrow.up")
//                        }
//                        .frame(alignment: .trailing)
//                    }
//                }
                
                ViewEventSlideShow(eventId: container.id!)
                
                Spacer()
            }
        }
        .navigationTitle(text)
    }
    
    struct CameraOverlayVideoClip: View {
        
        let toCopy: String
        var body: some View {
             
            HStack{
                ShareLink(item: toCopy, preview: SharePreview("Viewu Video", image: toCopy)){
                    Image(systemName: "square.and.arrow.up")
                }
                .frame(alignment: .trailing)
                .foregroundColor(.white)
            }
            .padding(.trailing, 5)
            .padding(.bottom, 5)
             
        }
    }
    
    struct CameraOverlaySnapShot: View {
        
        let toCopy: String
        
        var body: some View {
             
            HStack{
                Button{
                    UIPasteboard.general.string = toCopy
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .frame(width: 340, alignment: .trailing)
                .foregroundColor(.white)
                
                ShareLink(item: toCopy, preview: SharePreview("Viewu SnapshotE", image: toCopy)){
                    Image(systemName: "square.and.arrow.up")
                }
                .frame(alignment: .trailing)
                .foregroundColor(.white)
            }
            .padding(.trailing, 5)
            .padding(.bottom, 5)
             
        }
    }
    
}


//#Preview {
//    ViewEventDetail(frameTime: 1710541384.496615)
//        .modelContainer(for: ImageContainer.self)
//}
