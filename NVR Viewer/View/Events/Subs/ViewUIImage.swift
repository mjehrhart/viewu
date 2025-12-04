//
//  ViewUIImage.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import Foundation
import SwiftUI
import SwiftData

struct ViewUIImage: View{
    
    let api = APIRequester()
    let nvr = NVRConfig.shared()
    
    let urlString: String
    let frameTime: Double
    let frigatePlus: Bool
    
    @State var data: Data?
    @State private var zoomIn: Bool = false
    @ObservedObject var epsSuper = EndpointOptionsSuper.shared()
    
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    @State var orientation = UIDevice.current.orientation
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    func setWidth() -> CGFloat{
        
        if idiom == .pad {
            var width = UIScreen.screenWidth
            width = width - 200
            //            var w = width * 16/9
            //            w = (-w + width) * -1
            
            return width
        } else {
            let width = UIScreen.screenWidth
            return width - 110
            //return 260
        }
    }
    
    func setHeight() -> CGFloat {
        
        //var height = UIScreen.screenHeight
        
        if idiom == .pad {
            return (setWidth() * 9/16)
        } else {
            return 166
        }
    }
    
    //TODO Overlays
    var body: some View {
        
        GeometryReader { geometry in
            
            if let data = data, let uiimage = UIImage(data: data){
                
                ScrollView(.horizontal){
                    
                    if orientation.isLandscape {
                        
                        if idiom == .pad {
                            
                        } else {
                            Image(uiImage: uiimage)
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                            //.frame(maxWidth: geometry.size.width )
                                .onTapGesture{
                                    withAnimation {
                                        zoomIn.toggle()
                                    }
                                }
                                .background(.orange)
                                .overlay(ImageOverlay(frigatePlus: frigatePlus), alignment: .bottomTrailing)
                        }
                    } else {
                        
                        if idiom == .pad {
                            Image(uiImage: uiimage)
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fit)
                                .frame(maxWidth: geometry.size.width)
                                .onTapGesture{
                                    withAnimation {
                                        zoomIn.toggle()
                                    }
                                }
                                .background(.teal)
                                .overlay(ImageOverlay(frigatePlus: frigatePlus), alignment: .bottomTrailing)
                        } else {
                            //iphone max portrait mode
                            Image(uiImage: uiimage)
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fit)
                                .frame(maxWidth: geometry.size.width)
                                .onTapGesture{
                                    withAnimation {
                                        zoomIn.toggle()
                                    }
                                }
                                .background(.teal)
                                .overlay(ImageOverlay(frigatePlus: frigatePlus), alignment: .bottomTrailing)
                        }
                    }
                    
                }
                
            } else {
                //Dummy Space
                Text("")
                    .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                    .frame(width: 250,height: 150)
                    .onAppear{
                        //fetchImage
                        Task{
                            await api.fetchImage(urlString: urlString, authType: nvr.getAuthType()){ (data, error) in
                                
//                                if let _ = error {
//                                     
//                                    let flag = EventStorage.shared.delete(frameTime: frameTime)
//                                    if flag {
//                                        
//                                        //if Event Snapshot is empty, show this instead
//                                        await api.fetchImage(urlString: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQoBAeYwmKevvqaidagwfKDT6UXrei3kiWYlw&usqp=CAU", authType: .none){ (data, error) in
//                                            
//                                            if let _ = error {
//                                            } else {
//                                                self.data = data
//                                            }
//                                        }
//                                    }
//                                    
//                                } else {
//                                    self.data = data
//                                }
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
                        .padding( .trailing, 35)
                        .padding(.bottom, 10)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

