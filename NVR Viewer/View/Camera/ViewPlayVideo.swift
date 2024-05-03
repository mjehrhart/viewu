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
    
    var body: some View {
         
        PlayerViewController(videoURL: URL(string: urlString), player: player)
            .frame(width: UIScreen.screenWidth-30, height: (UIScreen.screenWidth * 9/16))
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                player.pause()
            }
            .onDisappear {
                player.pause()
            }
        
//        VideoPlayer(player: player)
//            .frame(width: UIScreen.screenWidth-30, height: (UIScreen.screenWidth * 9/16))
//            .edgesIgnoringSafeArea(.all)
//            .onAppear {
//                let url = URL(string: urlString)!
//                print("ViewPlayVideo", url)
//                player = AVPlayer(url: url)
//                player.pause()
//                
//            }
//            .onDisappear {
//                player.pause()
//            }
    }
}

struct PlayerViewController: UIViewControllerRepresentable {
    var videoURL: URL?
    @State var player: AVPlayer
    
//    private var player: AVPlayer {
//        return AVPlayer(url: videoURL!)
//    }
    
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
