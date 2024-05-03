//
//  ViewEventSlideShow.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/22/24.
//

import SwiftUI
import TipKit

struct ViewEventSlideShow: View {
    
    let containers: [EndpointOptions] 
    var tipEventHistory = TipEventHistory()
    
    init(eventId: String) {
        containers = EventStorage.shared.getEventById(id3: eventId)
    }
    
    var body: some View {
        VStack{
            Spacer().frame(height:20)
            Text("Event History: \(containers.count)")
                .frame(width: UIScreen.screenWidth-30, alignment: .leading)
                .padding(10)
                //.background(.secondary, in: RoundedRectangle(cornerRadius: 5))
            
            TipView(tipEventHistory, arrowEdge: .bottom)
            
            ScrollView(.horizontal){
                HStack{
                    ForEach(containers, id: \.self){ container in
                        ViewUIImage(urlString: container.image! )
                            .modifier(CardBackground())
                            .padding(0)
                    }
                }
                .padding(.trailing, 30)
            }
            //.popoverTip(tipEventHistory, arrowEdge: .top)
        } 
    }
}
 
struct TipEventHistory: Tip {
    
    @Parameter
    static var shownBefore: Bool = false
    
    var title: Text {
        Text("Information About Event History")
    }


    var message: Text? {
        Text("These are high resolution images based on your event. They are different than snapshots and take a longer time to load.")
    }


    var image: Image? {
        Image(systemName: "info.bubble")
    }
    
    var rules: [Rule] {
        [
            #Rule(Self.$shownBefore) { $0 == false }
        ]
    }
}
 
