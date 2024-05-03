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
    
    var body: some View {
        
        if let data = data, let uiimage = UIImage(data: data){
            
            Image(uiImage: uiimage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: self.zoomIn ? UIScreen.screenWidth-30: UIScreen.screenWidth-30, height:self.zoomIn ? UIScreen.screenWidth : (UIScreen.screenWidth * 9/16)-30)
                //.frame(maxWidth: self.zoomIn ? .infinity: 250, maxHeight: self.zoomIn ? UIScreen.screenHeight : 150 )  //leave screenWidth alone
                //.scaleEffect(self.zoomIn ? 1.5 : 1)
                .offset(x: 0,y: 0)
                .transition(.slide)
                //.opacity(self.zoomIn ? 0 : 0.5)
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
//                .onAppear{
//                    //fetchURLImage()
//                    cNVR.fetchImage(urlString: urlString){ (data, error) in
//                        if let error = error {
//                            print("Error: \(error)")
//                        } else if let data = data {
//                            self.data = data
//                            //print("Received data: \(data)")
//                        }
//                    }
//                }
        }
    }
    
//    private func fetchURLImage(){
//        
//        print("INSIDE fetchURLImage::VIEWUiImageFull")
//        //guard let url = URL(string: "http://127.0.0.1:5555/api/events/1708968097.297187-7pf02z/snapshot.jpg?bbox=1") else {return}
//        guard let url = URL(string: self.urlString) else {return}
//          
//        let task = URLSession.shared.dataTask(with: url, completionHandler: { data, res, error in
//            self.data = data
//        })
//        
//        task.progress.resume()
//    }
}
