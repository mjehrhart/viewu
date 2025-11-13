//
//  ViewCameraHLSFullScreen.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 5/31/24.
//

import SwiftUI
import WebKit

struct ViewCameraHLSFullScreen: View {
    
    let urlString: String
    let cameraName: String
    
    var body: some View {
        ZStack{
            
            LinearGradient(
                colors: [.clear, Color(red: 0.80, green: 0.80, blue: 0.80)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Webview(url: urlString + "/api/\(cameraName)?h=480")
                .rotationEffect(.degrees(90))
                .aspectRatio(16/9, contentMode: .fit)
                .frame(width: UIScreen.screenHeight, height: UIScreen.screenWidth)
                .edgesIgnoringSafeArea(.all)
                .overlay(CameraOverlay(name: cameraName ), alignment: .bottomTrailing) 
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    struct CameraOverlay: View {
        let name: String
        @State var flagMute = false
        @State var showCameras = false;
        
        var body: some View {
            
            HStack{
                VStack{
                    Spacer()
                    HStack{
                        Button(name){
                        }
                        .foregroundColor(.white)
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.bottom, 10)
                        .padding([.trailing], 90)
                        
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                
            }
            .background(Color(.init(white: 10, alpha: 0)))
            .rotationEffect(.degrees(90))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }
}

