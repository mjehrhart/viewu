//
//  RTSPPlayer2.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/30/24.
//

import Foundation
import MobileVLCKit
import SwiftUI

struct VlcPlayeyRTSP2: UIViewRepresentable{
    
    let urlString: String
    let mediaPlayer : VLCMediaPlayer
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VlcPlayeyRTSP2>) {
    }
    
    func makeUIView(context: Context) -> UIView {
        
        return PlayerUIView2(frame: .zero, urlString: urlString, mediaPlayer: mediaPlayer)
    }
}

class PlayerUIView2: UIView, VLCMediaPlayerDelegate, ObservableObject{
    
    //override
    init(frame: CGRect, urlString: String, mediaPlayer : VLCMediaPlayer) {
        
        super.init(frame: CGRect(x:0,y:0, width:350, height: 250))
        
        //DispatchQueue.main.async {
        DispatchQueue.global(qos: .userInteractive).async{
            
            //super.init(frame: UIScreen.screens[0].bounds)
            //super.init(frame: self.view.window?.windowScene?.screen.bounds.size)
            //super.init(frame: CGRect(x:0,y:0, width:350, height: 250))
            
            let url = URL(string: urlString)!
            let media = VLCMedia(url: url)
            
            //https://wiki.videolan.org/VLC_command-line_help
            media.addOption("--codec=avcodec")
            media.addOption("--avcodec-hw=any")
            media.addOption("--avcodec-fast=true")
            media.addOption("--glconv-glconv_cvpx")
            //        media.addOption("--avcodec-threads=0")
            media.addOption("--network-caching=100")
            media.addOption(":rtsp-caching=150")
            //        media.addOption("--rtsp-frame-buffer-size=200")
            media.addOption("--vout=ios")
            //        media.addOption("--glconv=glconv_cvpx")
            //        media.addOption("--rtsp-caching=100")
            //        media.addOption("--rtsp-tcp")
            //        media.addOption("--tcp-caching=150")
            //        media.addOption("--realrtsp-caching=150")
            //        media.addOption("--mms-timeout=6000")
            //        media.addOption("--h264-fps=15.0")
            //        media.addOption("--vcodec=h264")
            
            
            //        media.addOptions(
            //            [
            //                //"--rtsp-tcp": true,
            //                "codec":"avcodec",
            //                "avcodec-hw":"any", // none
            //                "avcodec-fast" : true,
            //                "avcodec-threads" : 0, // "1" 0=auto
            //                "network-caching": 300, //300, 500
            //                "rtsp-frame-buffer-size":100, //100, 500
            //                "vout": "ios",
            //                "glconv" : "glconv_cvpx",
            //                "rtsp-caching": 150, //rtsp-caching=
            //                "tcp-caching": 150, //tcp-caching=
            //                "realrtsp-caching": 150, //150, realrtsp-caching=
            //                //"--h264-fps": 20.0, //20.0
            //                "mms-timeout": 6000, //60000
            //            ]
            //        )
            
            mediaPlayer.media = media
            mediaPlayer.delegate = self
            mediaPlayer.drawable = self
            mediaPlayer.audio?.isMuted = true
            mediaPlayer.videoAspectRatio = UnsafeMutablePointer<Int8>(mutating: ("16:9" as NSString).utf8String)
            
            //Logging
            let logger = VLCConsoleLogger()
            logger.level = .info
            //mediaPlayer.libraryInstance.loggers = [logger]
            //mediaPlayer.play()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

struct StreamRTSP2: View {
    
    let urlString: String
    let cameraName: String
    
    @State var mediaPlayer : VLCMediaPlayer = VLCMediaPlayer()
    @State var flagMute = true
    @State var flagFull = false
    @State var isLoading = true
    
    //Color.orange.opacity(0.6)
    //Color.gray.opacity(0.125)
    //Color(red: 0.45, green: 0.45, blue: 0.45)
    let menuBGColor = Color.orange.opacity(0.6)
    let menuTextColor = Color.white
    let cBlue = Color(red: 0.153, green: 0.69, blue: 1)
    
    var body: some View {
        return
        
        VStack{
            
            ZStack{
                
                if isLoading{
                    
                    LinearGradient(
                        colors: [.clear, cBlue, .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
                
                Text("Loading: \(urlString)")
                    .labelStyle(VerticalLabelStyle(show: false))
                    .foregroundStyle(menuTextColor)
                
                VStack{
                    VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
                        .padding(0)
                        .aspectRatio(16/9, contentMode: .fit)
                    //.modifier( CardBackground2() )
                    //.frame(width: UIScreen.screenWidth, height: (UIScreen.screenWidth * 9/16)-5)
                        .onAppear(){
                            //isLoading = false
                            mediaPlayer.audio?.isMuted = flagMute
                            mediaPlayer.play()
                        }
                        .onDisappear(){
                            mediaPlayer.stop()
                        }
                    //.overlay(CameraOverlay(name: cameraName, urlString: urlString, mediaPlayer: mediaPlayer), alignment: .bottomTrailing)
                    
                }
                .background(Color.gray.opacity(0.125))
                
            }
            .padding(0)
            
            HStack(alignment: .firstTextBaseline){
                
                HStack(alignment: .lastTextBaseline){
                    
                    //Text(cameraName)
                    Label("\(cameraName)", systemImage: "")
                        .foregroundStyle(menuTextColor)
                        .font(.system(size: 22))
                        .onTapGesture(perform: {
                            
                        })
                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 00, trailing: 0))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Label("", systemImage: flagMute ? "speaker.slash" : "speaker")
                    //.labelStyle(VerticalLabelStyle(show: false))
                        .foregroundStyle(menuTextColor)
                        .font(.system(size: 24))
                        .onTapGesture(perform: {
                            flagMute.toggle()
                            mediaPlayer.audio?.isMuted = flagMute
                        })
                        .padding(.trailing,20)
                    
                    Label("", systemImage: "arrow.down.left.and.arrow.up.right.rectangle")
                    //.labelStyle(VerticalLabelStyle(show: false))
                        .foregroundStyle(menuTextColor)
                        .font(.system(size: 24))
                        .onTapGesture(perform: {
                            flagFull.toggle()
                        })
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 20))
                }
                .padding(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
                //.background(.yellow)
                
                Spacer()
            }
        }
        .background(menuBGColor)
        .modifier( CardBackground2() )
        .padding(.leading,10)
        .padding(.trailing,10)
        .padding(.bottom,10)
        .navigationDestination(isPresented: $flagFull){
            ViewCameraFullScreen(urlString: urlString, cameraName: cameraName)
        }
    }
    
    struct CardBackground2: ViewModifier {
        func body(content: Content) -> some View {
            content
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.2), radius: 4)
        }
    }
    
    struct CameraOverlay: View {
        let name: String
        let urlString: String
        
        @State var flagMute = true
        @State var mediaPlayer : VLCMediaPlayer
        
        @State var flagFull = false
        
        var body: some View {
            
            Text(name)
                .padding([.top, .trailing], 10)
                .padding(.leading, 10)
                .padding(.bottom, 5)
                .foregroundColor(.white)
                .fontWeight(.bold)
                .onTapGesture {
                    flagFull.toggle()
                }
            //Moved to here because was having issues otherwise
                .navigationDestination(isPresented: $flagFull){
                    ViewCameraFullScreen(urlString: urlString, cameraName: name)
                }
        }
    }
    
}


