//
//  ViewUIImageFull.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import SwiftUI

struct ViewUIImageFull: View{
    
    let cNVR = APIRequester()
    let urlString: String
    @State var data: Data?
    @State var zoomIn: Bool = false
    
    @State var orientation = UIDevice.current.orientation
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    //TODO Overlays
    var body: some View {
        
        GeometryReader { geometry in
            if let data = data, let uiimage = UIImage(data: data){
                
                if orientation.isLandscape {
                    if idiom == .pad { 
                        Image(uiImage: uiimage)
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: geometry.size.width - 18)
                            .offset(x: 0,y: 0)
                            .transition(.slide)
                        //.opacity(self.zoomIn ? 0 : 0.5)
                            .onTapGesture{
                                withAnimation {
                                    zoomIn.toggle()
                                }
                            }
                    } else {
                        Image(uiImage: uiimage)
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: geometry.size.width - 18, alignment: .leading)
                            .onTapGesture{
                                withAnimation {
                                    zoomIn.toggle()
                                }
                            }
                    }
                } else {
                    
                    if idiom == .pad {
                        Image(uiImage: uiimage)
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: geometry.size.width - 18)
                            //.offset(x: 0,y: 0)
                            //.transition(.slide)
                            .onTapGesture{
                                withAnimation {
                                    zoomIn.toggle()
                                }
                            }
                    } else {
                        Image(uiImage: uiimage)
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: geometry.size.width - 18, alignment: .leading)
                            .onTapGesture{
                                withAnimation {
                                    zoomIn.toggle()
                                }
                            }
                    }
                }
            } else {
                //Dummy Space
                Text("")
                    .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                    .frame(width: 250,height: 150)
                    .onAppear{
                        
                        cNVR.fetchImage(urlString: urlString){ (data, error) in
                            
                            if let error = error {
                                
                                Log.shared().print(page: "ViewUIImageFull", fn: "onAppear", type: "ERROR", text: "\(error)")
                                //if Event Snapshot is empty, show this instead
                                cNVR.fetchImage(urlString: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQoBAeYwmKevvqaidagwfKDT6UXrei3kiWYlw&usqp=CAU"){ (data, error) in
                                    self.data = data
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
