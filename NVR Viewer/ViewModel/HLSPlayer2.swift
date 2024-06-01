//
//  HLSPlayer2.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 5/31/24.
//

import SwiftUI
import WebKit

struct HLSPlayer2: View {
    
    let urlString: String
    let cameraName: String
    @State var flagFull = false
    
    var body: some View {
        
        Webview(url: urlString + "/api/\(cameraName)?h=480")
            .modifier(CardBackground())
            .frame(width: UIScreen.screenWidth-20, height: (UIScreen.screenWidth * 9/16)-20)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture{
                flagFull.toggle()
            }
            .overlay(CameraOverlay(name: cameraName), alignment: .bottomTrailing)
            .navigationDestination(isPresented: $flagFull){
                ViewCameraHLSFullScreen(urlString: urlString, cameraName: cameraName) 
            }
    }
    
    struct CameraOverlay: View {
        let name: String
        @State var flagMute = true
        
        var body: some View {
             
            Text(name)
                .padding([.top, .trailing], 10)
                .padding(.leading, 10)
                .padding(.bottom, 5)
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
    }

    
}

struct Webview: UIViewRepresentable {
    
    var url: String
    func makeUIView(context: Context) -> WKWebView {
        
        guard let url = URL(string: self.url) else {
            return WKWebView()
        }
        
        let request = URLRequest(url: url)
        
        let wkWebview = WKWebView()
        wkWebview.load(request)
        return wkWebview
    }
    
    func updateUIView(_ uiView: Webview.UIViewType, context: UIViewRepresentableContext<Webview>) {
    }
}
