//
//  ViewLiveLandscape.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 5/10/24.
//

import SwiftUI

struct ViewLiveLandscape: View {
    
    let cNVR = APIRequester()
    let urlString: String
    let cameraName: String
    @State var data: Data?
    @State var zoomIn: Bool = false
    
    var body: some View {
        
        if let data = data, let uiimage = UIImage(data: data){
            
            Image(uiImage: uiimage)
                .resizable()
                .rotationEffect(.degrees(90))
                .aspectRatio(16/9, contentMode: .fit)
                .frame(width: UIScreen.screenHeight, height: UIScreen.screenWidth)
                .edgesIgnoringSafeArea(.all)
                .overlay(CameraOverlay(name: cameraName), alignment: .bottomTrailing)
            
        } else {
            //Dummy Space
            Text("")
                .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                .frame(width: 250,height: 150)
                .onAppear{
                    
                    cNVR.fetchImage(urlString: urlString){ (data, error) in
                        
                        if let error = error {
                            
                            Log.shared().print(page: "ViewLiveLandscape", fn: "onAppear", type: "ERROR", text: "\(error)")
                            
                            //if Event Snapshot is empty, show this instead
                            cNVR.fetchImage(urlString: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQoBAeYwmKevvqaidagwfKDT6UXrei3kiWYlw&usqp=CAU"){ (data, error) in
                                
//                                if let error = error {
//                                } else {
                                    self.data = data
//                                }
                            }
                            
                        } else {
                            self.data = data
                        }
                    }
                } 
        }
    }
    
    struct CameraOverlay: View {
        
        let name: String
        @State var flagMute = false
        @State var showCameras = false;
        
        var body: some View {
             
            HStack{
                
                VStack{
 
                    HStack{
                        Button(name){ 
                            print("button1")
                        }
                        .foregroundColor(.white)
                        .font(.title)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.bottom, 10)
                        .padding([.trailing], 95)
 
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                 
            }
            .onTapGesture{
            }
            .background(Color(.init(white: 10, alpha: 0)))
            .rotationEffect(.degrees(90))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
             
        }
    }
    
}
