//
//  ViewNVRDetails.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 4/1/24.
//

import SwiftUI

struct ViewNVRDetails: View {
    
    let nvr = NVRConfig.shared()
    
    @EnvironmentObject private var notificationManager2: NotificationManager
    //@ObservedObject var config = NVRConfigurationSuper.shared()
    @ObservedObject var config = NVRConfigurationSuper2.shared()
    
    let cNVR = APIRequester()
    //var sup = NVRConfigurationSuper()
    var sup = NVRConfigurationSuper2()
    let widthMultiplier:CGFloat = 2/5
    
    //Use the dismiss action
    @Environment(\.dismiss) var dismiss
    
    init(){
    }
    
    var body: some View {
          
        Form{
            Section{
                ForEach(Array(config.item.cameras.keys).enumerated().sorted(by: {$0 < $1} ), id: \.element) { index, camera in
                    NavigationLink("\(camera)", value: config.item.cameras[camera])
                        .foregroundStyle(.blue)
                }
            } header: {
                Text("Cameras")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Section{
                HStack{
                    Text("ClientID")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(config.item.mqtt.client_id)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.secondary)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("Host")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(config.item.mqtt.host)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.secondary)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("Port")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(String(config.item.mqtt.port))")
                        .frame( alignment: .leading)
                        .foregroundStyle(.secondary)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("Topic")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(config.item.mqtt.topic_prefix)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.secondary)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("Interval2")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(config.item.mqtt.stats_interval)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.secondary)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
            } header: {
                Text("MQTT")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
          
            if ( config.item.go2rtc.streams != nil  ){ 
                //streams: ["" : [] ])
                Section {
                    ForEach(Array(config.item.go2rtc.streams!.keys ).sorted(by: {$0 < $1}), id: \.self) { value in
                      if !value.isEmpty {
                        Text("\(value)")
                            .frame(width:UIScreen.screenWidth, alignment: .leading)
                            .padding(.leading, 75)
  
                            ForEach(config.item.go2rtc.streams![value]!, id: \.self) { item in
                                ScrollView(.horizontal){
                                    Text("\(item)")
                                        .textSelection(.enabled)
                                        .foregroundStyle(.secondary)
                                        .padding(.leading, 0)
                                        .frame(width:UIScreen.screenWidth, alignment: .leading)
                                }
                            }
                        }
                   }
                } header: {
                    Text("Go2RTC")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
              
          
            
        }
        .background(Color(UIColor.secondarySystemBackground)) //very light gray
        .toolbar(.hidden, for: .bottomBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                
                Label("Back", systemImage: "chevron.backward")
                    .labelStyle(HorizontalLabelStyle())
                    .foregroundStyle(.blue)
                    .onTapGesture(perform: {
                        dismiss() // Manually dismiss the view
                        notificationManager2.newPage = 0
                    })
            }
        }
        .navigationBarTitle("NVR Configuration", displayMode: .inline)
        .navigationBarBackButtonHidden(true) 
    }
    
}

struct HorizontalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon.font(.system(size: 18, weight: .medium, design: .default))
            configuration.title.font(.system(size: 17)) 
        }
    }
}

//#Preview {
//    ViewNVRDetails()
//}
