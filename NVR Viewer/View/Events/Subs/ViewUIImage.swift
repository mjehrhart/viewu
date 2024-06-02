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
    
    let cNVR = APIRequester()
    let urlString: String
    let frameTime: Double
    let frigatePlus: Bool
    
    @State var data: Data?
    @State private var zoomIn: Bool = false
    @ObservedObject var epsSuper = EndpointOptionsSuper.shared()
    
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    func setWidth() -> CGFloat{
        
        if idiom == .pad {
            var width = UIScreen.screenWidth
            width = width - 200
//            var w = width * 16/9
//            w = (-w + width) * -1
             
            return width
        } else {
            var width = UIScreen.screenWidth
            return width - 110
            //return 260
        }
    }
    
    func setHeight() -> CGFloat {
        
        var height = UIScreen.screenHeight
        
        if idiom == .pad {
            return (setWidth() * 9/16)
        } else {
            return 166
        }
    }
    
    var body: some View {
        
        if let data = data, let uiimage = UIImage(data: data){
             
            ScrollView(.horizontal){
                Image(uiImage: uiimage)
                    .resizable()
                    .aspectRatio(16/9, contentMode: self.zoomIn ? .fill : .fill)
                    .frame(width: self.zoomIn ? setWidth() : setWidth(), height: self.zoomIn ? setHeight() * 1.5 : setHeight() )  //leave screenWidth alone
                    //.frame(width: self.zoomIn ? 260 : 260, height:self.zoomIn ? 310 : 166)
                    .transition(.slide)
                    .onTapGesture{
                        withAnimation {
                            zoomIn.toggle()
                        }
                    }
                    .overlay(ImageOverlay(frigatePlus: frigatePlus), alignment: .bottomTrailing)
            }
            
        } else {
            //Dummy Space
            Text("")
                .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                .frame(width: 250,height: 150)
                .onAppear{
                    
                    cNVR.fetchImage(urlString: urlString){ (data, error) in
                        
                        if let _ = error {
                            
                            //TODO
                            //Not sure i like this approach as it forces the list to reload when an image is removed
                            //print("Found ERROR ======================================================================")
                            let flag = EventStorage.shared.delete(frameTime: frameTime)
                            if flag {
                                 
                                //if Event Snapshot is empty, show this instead
                                cNVR.fetchImage(urlString: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQoBAeYwmKevvqaidagwfKDT6UXrei3kiWYlw&usqp=CAU"){ (data, error) in
                                    
                                    if let _ = error {
                                    } else {
                                        self.data = data
                                    }
                                }
                            }
                            
                        } else {
                            self.data = data
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

