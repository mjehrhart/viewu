//
//  ViewPlayVideo.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import SwiftUI
import AVKit

struct ViewPlayVideo: View {
    
    let urlString: String
    @State private var player = AVPlayer()
    
    @State var orientation = UIDevice.current.orientation
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    @State private var showingAlert = false
    let cBlue = Color(red: 0.153, green: 0.69, blue: 1)
    let menuTextColor = Color.white
    
    //TODO Overlays
    var body: some View {
        
        GeometryReader { geometry in
            
            //iPad
            if idiom == .pad {
                if orientation.isLandscape {
                    VStack( spacing: 0){
                        PlayerViewController(videoURL: URL(string: urlString), player: player)
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: geometry.size.width, height: 740,  alignment: .leading)
                            .onAppear {
                                player.pause()
                            }
                            .onDisappear {
                                player.pause()
                            }
                        HStack(alignment: .lastTextBaseline){
                            Label("", systemImage: "")
                                .font(.system(size: 24))
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
                                .frame(width: geometry.size.width, height: 50, alignment: .trailing)
                                .background(cBlue.opacity(0.6))
                        }
                    }
                    .modifier(CardBackground2())
                    .overlay(CameraOverlayVideoClip2(toCopy: urlString ), alignment: .bottomTrailing)
                }
                else {
                    
                    VStack( spacing: 0){
                        PlayerViewController(videoURL: URL(string: urlString), player: player)
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: geometry.size.width, height: 550, alignment: .leading)
                            .onAppear {
                                player.pause()
                            }
                            .onDisappear {
                                player.pause()
                            }
                        HStack(alignment: .lastTextBaseline){
                            Label("", systemImage: "")
                                .font(.system(size: 24))
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
                                .frame(width: geometry.size.width, height: 50, alignment: .trailing)
                                .background(cBlue.opacity(0.6))
                        }
                    }
                    .modifier(CardBackground2())
                    .overlay(CameraOverlayVideoClip2(toCopy: urlString ), alignment: .bottomTrailing)
                }
            }
            //iPhone
            else {
                if orientation.isLandscape {
                    
                    VStack( spacing: 0){
                        PlayerViewController(videoURL: URL(string: urlString), player: player)
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: geometry.size.width, alignment: .leading)
                            .onAppear {
                                player.pause()
                            }
                            .onDisappear {
                                player.pause()
                            }
                        
                        HStack(alignment: .lastTextBaseline){
                            Label("", systemImage: "")
                                .font(.system(size: 24))
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
                                .frame(width: geometry.size.width, height: 50, alignment: .trailing)
                                .background(cBlue.opacity(0.6))
                        }
                    }
                    .modifier(CardBackground2())
                    .overlay(CameraOverlayVideoClip2(toCopy: urlString ), alignment: .bottomTrailing)
                }
                else {
                    VStack( spacing: 0){
                        PlayerViewController(videoURL: URL(string: urlString), player: player)
                            .aspectRatio( 16/9, contentMode: .fill)
                            .frame(width: geometry.size.width, height: 250, alignment: .leading)
                            .onAppear {
                                player.pause()
                            }
                            .onDisappear {
                                player.pause()
                            }
                        
                        HStack(alignment: .lastTextBaseline){
                            Label("", systemImage: "")
                                .font(.system(size: 24))
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
                                .frame(width: geometry.size.width, height: 50, alignment: .trailing)
                                .background(cBlue.opacity(0.6))
                        }
                    }
                    .modifier(CardBackground2())
                    .overlay(CameraOverlayVideoClip2(toCopy: urlString ), alignment: .bottomTrailing)
                    
                }
            }
        }
    }
    
    struct CardBackground2: ViewModifier {
        func body(content: Content) -> some View {
            content
                .cornerRadius(25)
                .shadow(color: Color.black.opacity(0.2), radius: 4)
        }
    }
    
    struct CardBackground3: ViewModifier {
        func body(content: Content) -> some View {
            content 
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 15, bottomTrailingRadius: 15))
                .shadow(color: Color.black.opacity(0.2), radius: 4)
        }
    }
}



struct PlayerViewController: UIViewControllerRepresentable {
    var videoURL: URL?
    @State var player: AVPlayer
    
    init(videoURL: URL?, player: AVPlayer){
        self.player = AVPlayer(url: videoURL!)
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.modalPresentationStyle = .fullScreen
        controller.player = player
        //controller.player?.play()
        
        return controller
    }
    
    func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {}
}

struct CameraOverlayVideoClip2: View {
    
    let toCopy: String
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    @State var orientation = UIDevice.current.orientation
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    var body: some View {
        
        if idiom == .pad{
            
            if orientation.isLandscape {
                HStack{
                    
                    ShareLink(item: toCopy, preview: SharePreview("Viewu Video", image: toCopy)){
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundStyle(.white)
                    .font(.system(size: 24))
                }
                .padding(EdgeInsets(top: 700, leading: 0, bottom: 20, trailing: 40))
                .frame(maxWidth: .infinity, maxHeight: 730, alignment: .trailing)
            }
            else {
                
                HStack{
                    
                    ShareLink(item: toCopy, preview: SharePreview("Viewu Video", image: toCopy)){
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundStyle(.white)
                    .font(.system(size: 24))
                }
                .padding(EdgeInsets(top: 470, leading: 0, bottom: 0, trailing: 40))
                .frame(maxWidth: .infinity, maxHeight: 530, alignment: .trailing)
            }
        }
        else {
            
            if orientation.isLandscape {
                HStack{
                    
                    ShareLink(item: toCopy, preview: SharePreview("Viewu Video", image: toCopy)){
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundStyle(.white)
                    .font(.system(size: 24))
                    .frame(maxWidth: .infinity, maxHeight: 300, alignment: .trailing)
                }
                //TODO check if this is effecting the ShareLink
                .padding(EdgeInsets(top: 250, leading: 0, bottom: 0, trailing: 45))
                .frame(maxWidth: .infinity, maxHeight: 300, alignment: .trailing)
            }
            else {
                
                HStack{
                    
                    ShareLink(item: toCopy, preview: SharePreview("Viewu Video", image: toCopy)){
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundStyle(.white)
                    .font(.system(size: 24))
                    .frame(maxWidth: .infinity, maxHeight: 300, alignment: .trailing)
                }
                .padding(EdgeInsets(top: 250, leading: 0, bottom: 0, trailing: 45))
                .frame(maxWidth: .infinity, maxHeight: 300, alignment: .trailing)
                
            }
        }
    }
}
