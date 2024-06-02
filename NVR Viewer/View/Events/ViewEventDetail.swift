//
//  ViewEventDetail.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//
//  Depreciated

import SwiftUI
import AVKit
import SwiftData

struct ViewEventDetail: View {
    
    let text: String
    let container: EndpointOptions
    
    @State private var player = AVPlayer()
    @State private var path = NavigationPath()
    
    var frigatePlusOn: Bool = UserDefaults.standard.bool(forKey: "frigatePlusOn")
    //
    @EnvironmentObject private var notificationManager2: NotificationManager
    @State var selection: Int = 0
    @State var showButton: Bool
    @State var showClip: Bool
     
    init(text: String, container: EndpointOptions, path: NavigationPath = NavigationPath(), showButton: Bool, showClip: Bool) {
        self.text = text
        self.container = container
        self.path = path
        self.showButton = showButton
        self.showClip = showClip
    }
    
    var body: some View {
        VStack(alignment: .trailing){
             
            ScrollView {
                HStack{
                    
                    Label("\(container.cameraName!.capitalized)", systemImage: "web.camera")
                        .frame( alignment: .leading)
                        .padding()
                    Label("\(container.label!.capitalized)", systemImage: "figure.walk.motion")
                        .frame(alignment: .trailing)
                        .padding()
                    Label("\(container.type!)", systemImage: "moonphase.new.moon.inverse")
                        .frame(alignment: .trailing)
                        .padding()
                }
                .padding([.top, .bottom], 0)
                 
                EnteredZones(zones: container.enteredZones!)
  
                if showClip {
                    if( container.m3u8 != nil ){
                        if( container.m3u8! != nil ){
                            
                            HStack{
                                Text("Video Clip")
                                    .frame(width:UIScreen.screenWidth - 30, alignment: .leading)
                                    .padding(10)
                            }
                            
                            ViewPlayVideo(urlString: container.m3u8!)
                                .modifier(CardBackground())
                                .padding(0)
                                .overlay(CameraOverlayVideoClip(toCopy: container.m3u8! ), alignment: .bottomTrailing) 
                        }
                    }
                }
                
                Text("Snapshot")
                    .frame(width: UIScreen.screenWidth-30, alignment: .leading)
                    .padding(10)
                 
                ViewUIImageFull(urlString: container.snapshot!)
                    .modifier(CardBackground())
                    .padding(0)
                    .overlay(CameraOverlaySnapShot(eventId: container.id!, toCopy: container.snapshot!, frigatePlus: container.frigatePlus! ), alignment: .bottomTrailing)
 
                //Obsolete since the app now does http fetch
                //ViewEventSlideShow(eventId: container.id!)
                Spacer()
            }
        } 
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                
                if showButton {
                    Label("Timeline", systemImage: "chevron.left")
                        .labelStyle(HorizontalLabelStyle())
                        .foregroundStyle(.blue)
                        .onTapGesture(perform: {
                            notificationManager2.newPage = 0
                        })
                }
            }
        }
        .navigationBarTitle(text, displayMode: .inline)
    }
    
    struct EnteredZones: View {
    
        let zones:String
        var enteredZones: Array<Substring>;
          
        init(zones: String) {
            self.zones = zones
            enteredZones = zones.split(separator: "|")
        }
         
        var body: some View {
            
            if !enteredZones.isEmpty {
                HStack{
                    Label("Zones", systemImage: "square.stack.3d.down.right.fill")
                        .frame( alignment: .leading)
                        .padding(0)
                    
                    ForEach(enteredZones, id: \.self) { zone in
                        Text(zone)
                    }
                }
                .frame( alignment: .leading)
                .padding(0)
            }
        }
    }
    
    struct CameraOverlayVideoClip: View {
        
        let toCopy: String
        var body: some View {
             
            HStack{
                ShareLink(item: toCopy, preview: SharePreview("Viewu Video", image: toCopy)){
                    Image(systemName: "square.and.arrow.up")
                }
                .frame(alignment: .trailing)
                .foregroundColor(.white)
                .fontWeight(.bold)
            }
            .padding(.trailing, 5)
            .padding(.bottom, 5)
             
        }
    }
    
    struct CameraOverlaySnapShot: View {
        
        let nvr = NVRConfig.shared()
        let cNVR = APIRequester()
        
        let eventId: String
        let toCopy: String
        @State var frigatePlus: Bool
        var frigatePlusOn: Bool = UserDefaults.standard.bool(forKey: "frigatePlusOn")
        
        @ObservedObject var epsSuper = EndpointOptionsSuper.shared()
        //@ObservedObject var epsSup3 = EndpointOptionsSuper.shared().list3
        
        var body: some View {
             
            HStack{
                
                Button{
                    UIPasteboard.general.string = toCopy
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .frame(width: 340, alignment: .trailing)
                .foregroundColor(.white)
                .fontWeight(.bold)
                
                ShareLink(item: toCopy, preview: SharePreview("Viewu SnapshotE", image: toCopy)){
                    Image(systemName: "square.and.arrow.up")
                }
                .frame(alignment: .trailing)
                .foregroundColor(.white)
                .fontWeight(.bold)
                
                if !frigatePlus{
                    if frigatePlusOn {
                        Button{
                            
                            frigatePlus = true
                            
                            let url = nvr.getUrl()
                            let urlString = url + "/api/events/\(eventId)/plus"
                            cNVR.postImageToFrigatePlus(urlString: urlString, eventId: eventId ){ (data, error) in
                                
                                guard let data = data else { return }
                                
                                do {
                                    if let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed ) as? [String: Any] {
                                        
                                        if let res = json["success"] as? Int {
                                            print(res)
                                            if res == 1 {
                                                
                                                EventStorage.shared.updateFrigatePlus(id:eventId, value: true)
                                                
                                                EventStorage.shared.readAll3(completion: { res in
                                                    //self.epsSup3 = res!
                                                    epsSuper.list3 = res!
                                                    return
                                                })
                                            } else {
                                                
                                                if let msg = json["message"] as? String {
                                                    print(msg)
                                                    
                                                    if (msg == "PLUS_API_KEY environment variable is not set" ){
                                                        frigatePlus = false
                                                        EventStorage.shared.updateFrigatePlus(id: eventId, value: false)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } catch(let err) {
                                    print(err)
                                }
                            }
                            
                        } label: {
                            Image(systemName: "plus.rectangle")
                        }
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    }
                }
            }
            .padding(.trailing, 5)
            .padding(.bottom, 5)
             
        }
    }
    
}
