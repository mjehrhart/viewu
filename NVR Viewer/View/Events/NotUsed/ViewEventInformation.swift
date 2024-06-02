//
//  ViewEventInformation.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/5/24.
//
// Obsol

import SwiftUI
import SwiftData

struct ViewEventInformation: View {
    
    let endPointOptionsArray: [EndpointOptions]
 
    var body: some View {
        Text("!THIS SHOULD BE OBSOLETE!")
        VStack(alignment: .leading){
            ScrollView {
                Text("\(convertDateTime(time:endPointOptionsArray[0].frameTime!))")
                HStack{
                    Label("Camera \(endPointOptionsArray[0].cameraName!.capitalized)", systemImage: "web.camera")
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                    Label("\(endPointOptionsArray[0].label!.capitalized)", systemImage: "figure.walk.motion")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.bottom, 10)
                .padding(.top, 0)
                
                Text("Video Clip")
                    .frame(width: UIScreen.screenWidth-10, alignment: .leading)
                    .padding([.leading], 34)
                    .padding(.bottom, 0)
                ViewPlayVideo(urlString: endPointOptionsArray[0].m3u8!)
                    .modifier(CardBackground())
                    .padding([.trailing, .leading], 10)
                Text("Snapshot")
                    .frame(width: UIScreen.screenWidth-10, alignment: .leading)
                    .padding([.leading], 34)
                    .padding(.bottom, 0)
                ViewUIImageFull(urlString: endPointOptionsArray[0].snapshot!, zoomIn: true) //snapshot
                    .modifier(CardBackground())
                    .padding([.leading, .top, .trailing], 0)
                
                Spacer()
                Text("Event Snapshot History: \(endPointOptionsArray.count)")
                    .frame(width: UIScreen.screenWidth-30, alignment: .leading)
                    .padding(.bottom, 0)
                
                ScrollView(.horizontal){
                    HStack{
                        ForEach(endPointOptionsArray, id: \.self) { eps in
                             
                            ViewUIImage(urlString: eps.image!,frameTime: 0.0, frigatePlus: false  )
                                .modifier(CardBackground())
                                .padding(0)
                            
                        }//end of first for each
                    }//end of scroll
                    .padding(.leading, 30)
                }
            }
        }
         
        Spacer()
    }
    
    private func convertDateTime(time: Double) -> String{
        let date = Date(timeIntervalSince1970: time)
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeZone = .current
        var localDate = dateFormatter.string(from: date)
        localDate.replace("at", with: "")
        return localDate
    }
}

//#Preview {
//    ViewEventInformation()
//}
