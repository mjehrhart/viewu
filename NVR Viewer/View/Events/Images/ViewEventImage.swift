//
//  ViewEventImage.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 11/26/25.
//

import Foundation
import SwiftUI
import SwiftData
import UIKit


struct ViewEventImage: View{
    
    let api = APIRequester()
    
    let urlString: String
    let frameTime: Double
    let frigatePlus: Bool
    
    let widthG: CGFloat
    let heightG: CGFloat
    
    @State var data: Data?
    @State private var zoomIn: Bool = false
    @ObservedObject var epsSuper = EndpointOptionsSuper.shared()
 
    
    var body: some View {
 
        SubView(urlString: urlString, frameTime: frameTime, widthGap: widthG, heightGap: heightG)
            .overlay(ImageOverlay(frigatePlus: frigatePlus), alignment: .bottomTrailing)
    }
    
    struct SubView: View {
        
        let api = APIRequester()
        let nvr = NVRConfig.shared()
        
        let urlString: String
        let frameTime: Double
        let widthGap: CGFloat
        let heightGap: CGFloat
        
        //let frigatePlus: Bool
        
        @State var data: Data?
        @State private var zoomIn: Bool = false
        @ObservedObject var epsSuper = EndpointOptionsSuper.shared()
        @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
        
        private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
//        @State var orientation = UIDevice.current.orientation
//        let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
//            .makeConnectable()
//            .autoconnect()
//        
        @State private var currentScale: CGFloat = 1.0
        @State private var finalScale: CGFloat = 1.0
        
        var body: some View {
            
            if let data = data, let uiimage = UIImage(data: data){
                 
                if idiom == .pad {
                    Image(uiImage: uiimage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: isLandscape ? 485 : 350)
                        .aspectRatio( contentMode: .fill)
                        .clipped()
                        .onRotate { orientation in
                            if orientation.isValidInterfaceOrientation {
                                isLandscape = orientation.isLandscape
                            }
                        }
                        .scaleEffect(currentScale * finalScale)
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in
                                    // Access the magnification property of the value
                                    currentScale = value.magnification
                                }
                                .onEnded { value in
                                    // Combine the final and current scales
                                    finalScale *= value.magnification
                                    currentScale = 1.0 // Reset current scale for the next gesture
                                }
                        )
                }
                else {
                    Image(uiImage: uiimage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: isLandscape ? 250 : 180)
                        .aspectRatio( contentMode: .fill)
                        .clipped()
                        .onRotate { orientation in
                            if orientation.isValidInterfaceOrientation {
                                isLandscape = orientation.isLandscape
                            }
                        }
                        .scaleEffect(currentScale * finalScale)
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in
                                    // Access the magnification property of the value
                                    currentScale = value.magnification
                                }
                                .onEnded { value in
                                    // Combine the final and current scales
                                    finalScale *= value.magnification
                                    currentScale = 1.0 // Reset current scale for the next gesture
                                }
                            )
                }
            } else  {
                //Dummy Space
                Text("")
                    .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                    .frame(width: 250,height: 150)
                    .modifier(CardBackground2())
                    .onAppear{
                        
                        Task {
                            await api.fetchImage(urlString: urlString, authType: nvr.getAuthType()){ (data, error) in
                                
                                if let _ = error {
                                    
                                    Log.shared().print(page: "ViewEventImGE",
                                                       fn: "SubView:body",
                                                       type: "WARNING",
                                                       text: "\(error)")
                                    
                                    //TODO
                                    //Not sure i like this approach as it forces the list to reload when an image is removed
                                    //print("Found ERROR ======================================================================")
                                    let flag = EventStorage.shared.delete(frameTime: frameTime)
                                    if flag {
                                        
                                        //if Event Snapshot is empty, show this instead
                                        //                                    api.fetchImage(urlString: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQoBAeYwmKevvqaidagwfKDT6UXrei3kiWYlw&usqp=CAU"){ (data, error) in
                                        //
                                        //                                        if let _ = error {
                                        //                                        } else {
                                        //                                            self.data = data
                                        //                                        }
                                        //                                    }
                                    }
                                    
                                } else {
                                    self.data = data
                                }
                            }
                        }
                    }
            }
        }
    }
    
    struct ImageOverlay: View {
        
        let frigatePlus: Bool
        var frigatePlusOn: Bool = UserDefaults.standard.bool(forKey: "frigatePlusOn")
        
        var body: some View {
            
            if(frigatePlusOn) {
                if(frigatePlus) {
                    Text("Frigate+")
                        .padding( .trailing, 5)
                        .padding(.bottom, 10)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
