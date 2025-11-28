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
    
    //TODO Overlays
    var body: some View {
        
        GeometryReader { geometry in
            
            if orientation.isLandscape {
                
                if idiom == .pad {
                    PlayerViewController(videoURL: URL(string: urlString), player: player)
                        .aspectRatio(16/9, contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                        .onAppear {
                            player.pause()
                        }
                        .onDisappear {
                            player.pause()
                        }
                } else {
                    PlayerViewController(videoURL: URL(string: urlString), player: player)
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(width: geometry.size.width, alignment: .leading)
                        .onAppear {
                            player.pause()
                        }
                        .onDisappear {
                            player.pause()
                        }
                }
            } else {
                
                if idiom == .pad { 
                    PlayerViewController(videoURL: URL(string: urlString), player: player)
                        .aspectRatio(16/9, contentMode: .fit) 
                        .frame(maxWidth: geometry.size.width, alignment: .leading)
                        .edgesIgnoringSafeArea(.all) 
                        .onAppear {
                            player.pause()
                        }
                        .onDisappear {
                            player.pause()
                        }
                } else {
                    PlayerViewController(videoURL: URL(string: urlString), player: player)
                        .aspectRatio( 16/9, contentMode: .fit)
                        .frame(width: geometry.size.width, height: 270, alignment: .leading)
                        .ignoresSafeArea(.all)
                        .scaledToFit()
                        .onAppear {
                            player.pause()
                        }
                        .onDisappear {
                            player.pause()
                        }
                }
            }
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
