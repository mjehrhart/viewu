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
    @State var data: Data?
    @State private var zoomIn: Bool = false
    
    var body: some View {
        
        if let data = data, let uiimage = UIImage(data: data){
            
            Image(uiImage: uiimage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: self.zoomIn ? UIScreen.screenWidth*1.25: 250, height:self.zoomIn ? UIScreen.screenWidth : 150 )  //leave screenWidth alone
                .transition(.slide)
                .onAppear{
                }
                .onTapGesture{
                    withAnimation {
                        zoomIn.toggle()
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
                            
                            //if Event Snapshot is empty, show this instead
                            cNVR.fetchImage(urlString: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQoBAeYwmKevvqaidagwfKDT6UXrei3kiWYlw&usqp=CAU"){ (data, error) in
                                
                                if let error = error {  
                                } else {
                                    self.data = data
                                }
                            }
                            
                        } else {
                            self.data = data
                        }
                    }
                }
        }   
    }
}

