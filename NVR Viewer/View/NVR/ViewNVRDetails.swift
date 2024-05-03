//
//  ViewNVRDetails.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 4/1/24.
//

import SwiftUI

struct ViewNVRDetails: View {
    
    @EnvironmentObject private var notificationManager2: NotificationManager  
    @ObservedObject var config = NVRConfigurationSuper.shared()
    
    let cNVR = APIRequester()
    var sup = NVRConfigurationSuper()
    let widthMultiplier:CGFloat = 2/5
    init(){
    }
    var body: some View {
          
        Form{
            Section{
                //HStack{
                    ForEach(Array(config.item.cameras.keys).enumerated().sorted(by: {$0 < $1} ), id: \.element) { index, camera in
                        NavigationLink("\(camera)", value: config.item.cameras[camera]) 
                            .foregroundStyle(.blue)
                    }
                //}
            } header: {
                Text("Cameras")
                    .font(.caption)
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
                    Text("Interval")
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
            }
            
            Section {
                ForEach(Array(config.item.go2rtc.streams.keys).sorted(by: {$0 < $1}), id: \.self) { value in
                    Text("\(value)")
                        .frame(width:UIScreen.screenWidth, alignment: .leading)
                        .padding(.leading, 75)
                        //.foregroundStyle(.secondary)
                    
                    ForEach(config.item.go2rtc.streams[value]!, id: \.self) { item in
                        ScrollView(.horizontal){
                            Text("\(item)")
                                .textSelection(.enabled)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 0)
                                .frame(width:UIScreen.screenWidth, alignment: .leading)
                        }
                    }
                }
            } header: {
                Text("Go2RTC")
                    .font(.caption)
            }
            
        }
        .background(Color(UIColor.secondarySystemBackground)) //very light gray
        .toolbar(.hidden, for: .bottomBar)
        .task(){
            cNVR.fetchNVRConfig(urlString: "http://100.73.173.67:5555/api/config" ){ (data, error) in
                
                guard let data = data else { return }
                
                do {
                    config.item = try JSONDecoder().decode(NVRConfigurationCall.self, from: data)
                    //print("nvr = ", config.item)
                }catch{
                    print("Error Message goes here - 1001")
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                
                Label("Timeline", systemImage: "chevron.left")
                    .labelStyle(HorizontalLabelStyle())
                    .foregroundStyle(.blue)
                    .onTapGesture(perform: {
                        notificationManager2.newPage = 0
                    })
                
//                Button{
//                    
//                    cNVR.fetchNVRConfig(urlString: "http://100.73.173.67:5555/api/config" ){ (data, error) in
//                        
//                        guard let data = data else { return }
//                        
//                        do {
//                            config.item = try JSONDecoder().decode(NVRConfigurationCall.self, from: data)
//                            //print("nvr = ", config.item)
//                        }catch(let error){
//                            print("Error Message goes here - 1001", error)
//                        }
//                    }
//                } label: {Label("play", systemImage: "play")}
//                    .foregroundStyle(.gray)
//                    .frame(alignment: .trailing)
            }
        }
        .navigationBarTitle("NVR Configuration", displayMode: .inline)
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

#Preview {
    ViewNVRDetails()
}
