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
    
    //Color.orange.opacity(0.6)
    //Color.gray.opacity(0.125)
    //Color(red: 0.45, green: 0.45, blue: 0.45)
    let menuBGColor = Color.orange.opacity(0.6)
    let menuTextColor = Color.white
    
    var body: some View {
        
        VStack{
            
            HStack{
                
                ZStack{
                    LinearGradient(
                        colors: [.clear, Color(red: 0.80, green: 0.80, blue: 0.80), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    VStack{
                        Webview(url: urlString + "/api/\(cameraName)?h=720") 
                            //.modifier(CardBackground2())
                            //.frame(width: UIScreen.screenWidth-20, height: (UIScreen.screenWidth * 9/16)-20)
                            .aspectRatio(16/9, contentMode: .fill)
                            //.frame(width: UIScreen.screenWidth)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .edgesIgnoringSafeArea(.all)
                            .background(Color.gray.opacity(0.125))
                            //.overlay(CameraOverlay(name: cameraName, urlString: urlString), alignment: .bottomTrailing)
                    }
                    .background(Color.gray.opacity(0.125))
                }
            }
            
            HStack(alignment: .firstTextBaseline){
                
                Text(cameraName)
                    .labelStyle(VerticalLabelStyle(show: false))
                    .foregroundStyle(menuTextColor)
                    .fontWeight(.bold)
                    .onTapGesture(perform: {
                        
                    })
                    .frame(maxWidth: .infinity)
                    .padding(.bottom,5)
                    .frame(alignment: .leading)
                
                HStack(alignment: .lastTextBaseline){
                    Spacer()
                     
                    Label("", systemImage: "arrow.down.left.and.arrow.up.right.rectangle")
                        .foregroundStyle(menuTextColor)
                        .font(.system(size: 24))
                        .onTapGesture(perform: {
                            flagFull.toggle()
                        })
                        .padding(.trailing,20)
                }
                Spacer()
            }
            .padding(.top, 3)
            .padding(.bottom, 8)
        }
        .background(menuBGColor)
        .modifier( CardBackground2() )
        .padding(.leading,10)
        .padding(.trailing,10)
        .padding(.bottom,15)
        .navigationDestination(isPresented: $flagFull){
            ViewCameraHLSFullScreen(urlString: urlString, cameraName: cameraName)
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
                    ViewCameraHLSFullScreen(urlString: urlString, cameraName: name)
                }
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
