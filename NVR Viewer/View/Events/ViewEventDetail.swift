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
    var developerModeIsOn: Bool = UserDefaults.standard.bool(forKey: "developerModeIsOn")
    
    //
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @EnvironmentObject private var notificationManager2: NotificationManager
    @State var selection: Int = 0
    @State var showButton: Bool
    @State var showClip: Bool
    
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    @State var orientation = UIDevice.current.orientation
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    init(text: String, container: EndpointOptions, path: NavigationPath = NavigationPath(), showButton: Bool, showClip: Bool) {
        self.text = text
        self.container = container
        self.path = path
        self.showButton = showButton
        self.showClip = showClip
    }
    
    //TODO Overlays
    var body: some View {
        
        GeometryReader { geometry in
            
            VStack {
                
                ScrollView {
                   
                    HStack{
                        
                        Label("\(container.cameraName!.capitalized)", systemImage: "web.camera")
                            .frame( alignment: .leading)
                            .padding()
                            .font(.system(size: 15))
                            .fontWeight(.regular)
                            .foregroundColor(.gray)
                        Label("\(container.label!.capitalized)", systemImage: "figure.walk.motion")
                            .frame(alignment: .trailing)
                            .padding()
                            .font(.system(size: 15))
                            .fontWeight(.regular)
                            .foregroundColor(.gray)
                        
                        if developerModeIsOn {
                            Label("\(container.type!)", systemImage: "moonphase.new.moon.inverse")
                                .frame(alignment: .trailing)
                                .padding()
                                .font(.system(size: 15))
                                .fontWeight(.regular)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding([.top, .bottom], 0)
                     
                    EnteredZones(zones: container.enteredZones!)
                   
                    if showClip {
                        
                        if( container.m3u8 != nil ){
                             
                            HStack{
                                Text("Video Segment")
                                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                    .font(.system(size: 20))
                                    .fontWeight(.regular)
                                    .foregroundColor(.gray)
                                    .frame(width: geometry.size.width, alignment: .leading)
                            }
                            if orientation.isLandscape {
                                
                                if idiom == .pad {
                                    ViewPlayVideo(urlString: container.m3u8!)
                                        .modifier(CardBackground())
                                        .overlay(CameraOverlayVideoClip(toCopy: container.m3u8! ), alignment: .bottomTrailing)
                                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 30))
                                        .aspectRatio(16/9, contentMode: .fill)
                                        .frame(width: ((geometry.size.width) - 20), alignment: .leading)
                                    
                                } else {
                                    ViewPlayVideo(urlString: container.m3u8!)
                                        .modifier(CardBackground())
                                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20))
                                        .overlay(CameraOverlayVideoClip(toCopy: container.m3u8! ), alignment: .bottomTrailing)
                                        .aspectRatio(16/9, contentMode: .fill)
                                        .frame(width: (geometry.size.width + 20) ,  alignment: .leading)
                                        //.background(.orange)
                                }
                                
                            } else {
                                if idiom == .pad {
                                    ViewPlayVideo(urlString: container.m3u8!)
                                        .modifier(CardBackground())
                                        .padding(20)
                                        .overlay(CameraOverlayVideoClip(toCopy: container.m3u8! ), alignment: .bottomTrailing)
                                        .aspectRatio(16/9, contentMode: .fill)
                                        .frame(width: (geometry.size.width + 17 ),  alignment: .leading)
                                        //.background(.green)
                                } else {
                                    ViewPlayVideo(urlString: container.m3u8!)
                                        .overlay(CameraOverlayVideoClip(toCopy: container.m3u8! ), alignment: .bottomTrailing)
                                        .modifier(CardBackground())
                                        //.scaledToFit()
                                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 60))
                                        .aspectRatio(16/9, contentMode: .fill)
                                        .frame(width: geometry.size.width + 40,  alignment: .leading)
                                        //.background(.brown)
                                }
                            }
                        }
                    }
                    
                    HStack{
                        Text("Snapshot")
                            .padding(10)
                            .font(.system(size: 20))
                            .fontWeight(.regular)
                            .foregroundColor(.gray)
                            .frame(width: geometry.size.width, alignment: .leading)
                    }
                    if orientation.isLandscape {
                        if idiom == .pad {
                            if(container.id != nil && container.snapshot != nil && container.frigatePlus != nil) {
                                ViewUIImageFull(urlString: container.snapshot!)
                                    .modifier(CardBackground())
                                    .padding(20)
                                    .overlay(CameraOverlaySnapShot(eventId: container.id!, toCopy: container.snapshot!, frigatePlus: container.frigatePlus! ), alignment: .bottomTrailing)
                                    .aspectRatio(16/9, contentMode: .fill)
                                    .frame(width: geometry.size.width ,  alignment: .leading)
                            }
                            //Obsolete since the app now does http fetch
                            //ViewEventSlideShow(eventId: container.id!)
                            
                            
                        } else {
                            if(container.id != nil && container.snapshot != nil && container.frigatePlus != nil) {
                                ViewUIImageFull(urlString: container.snapshot!)
                                    .modifier(CardBackground())
                                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                    .overlay(CameraOverlaySnapShot(eventId: container.id!, toCopy: container.snapshot!, frigatePlus: container.frigatePlus! ), alignment: .bottomTrailing)
                                    .aspectRatio(16/9, contentMode: .fill)
                                    .frame(width: geometry.size.width ,  alignment: .leading)
                                    //.background(Color.yellow)
                            }
                        }
                    }
                    else {
                        if idiom == .pad {
                            if(container.id != nil && container.snapshot != nil && container.frigatePlus != nil) {
                                ViewUIImageFull(urlString: container.snapshot!)
                                    .modifier(CardBackground())
                                    .padding(20)
                                    .overlay(CameraOverlaySnapShot(eventId: container.id!, toCopy: container.snapshot!, frigatePlus: container.frigatePlus! ), alignment: .bottomTrailing)
                                    .aspectRatio(16/9, contentMode: .fill)
                                    .frame(width: geometry.size.width ,  alignment: .leading)
                                    //.background(.yellow)
                            }
                            
                        } else {
                            if(container.id != nil && container.snapshot != nil && container.frigatePlus != nil) {
                                ViewUIImageFull(urlString: container.snapshot!)
                                    .modifier(CardBackground())
                                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 60))
                                    .overlay(CameraOverlaySnapShot(eventId: container.id!, toCopy: container.snapshot!, frigatePlus: container.frigatePlus! ), alignment: .bottomTrailing)
                                    .aspectRatio(16/9, contentMode: .fill)
                                    .frame(width: geometry.size.width + 40 ,  alignment: .leading)
                                    //.background(.brown)
                            }
                        }
                    }
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
        .onReceive(orientationChanged) { _ in
            self.orientation = UIDevice.current.orientation
        }
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
                        .font(.system(size: 15))
                        .fontWeight(.regular)
                        .foregroundColor(.gray)
                    
                    ForEach(enteredZones, id: \.self) { zone in
                        Text(zone)
                            .font(.system(size: 15))
                            .fontWeight(.regular)
                            .foregroundColor(.gray)
                    }
                }
                .frame( alignment: .leading)
                .padding(0)
            }
        }
    }
    
    struct CameraOverlayVideoClip: View {
        
        let toCopy: String
        private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
        @State var orientation = UIDevice.current.orientation
        let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .makeConnectable()
            .autoconnect()
        
        var body: some View {
            
            if idiom == .pad{
                
                if orientation.isLandscape {
                    HStack{
                        
                        ShareLink(item: toCopy, preview: SharePreview("Viewu Video", image: toCopy)){
                            Image(systemName: "square.and.arrow.up")
                        }
                        .frame(alignment: .trailing)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 30))
                }
                else {
                    
                    HStack{
                        
                        ShareLink(item: toCopy, preview: SharePreview("Viewu Video", image: toCopy)){
                            Image(systemName: "square.and.arrow.up")
                        }
                        .frame(alignment: .trailing)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 40, trailing: 80))
                }
            }
            else {
                
                if orientation.isLandscape {
                    HStack{
                        
                        ShareLink(item: toCopy, preview: SharePreview("Viewu Video", image: toCopy)){
                            Image(systemName: "square.and.arrow.up")
                        }
                        .frame(alignment: .trailing)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 30, trailing: 35))
                }
                else {
                    
                    HStack{
                        
                        ShareLink(item: toCopy, preview: SharePreview("Viewu Video", image: toCopy)){
                            Image(systemName: "square.and.arrow.up")
                        }
                        .frame(alignment: .trailing)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 30, trailing: 10))
                    
                }
            }
        }
    }
    
    struct CameraOverlaySnapShot: View {
        
        let nvr = NVRConfig.shared()
        let cNVR = APIRequester()
        
        let eventId: String
        let toCopy: String
        @State var frigatePlus: Bool
        var frigatePlusOn: Bool = UserDefaults.standard.bool(forKey: "frigatePlusOn")
        
        private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
        @State var orientation = UIDevice.current.orientation
        let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .makeConnectable()
            .autoconnect()
        
        @ObservedObject var epsSuper = EndpointOptionsSuper.shared()
        
        var body: some View {
            
            if idiom == .pad{
                
                if orientation.isLandscape {
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
                                                    //print(res)
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
                                                                Log.shared().print(page: "ViewEventDetail", fn: "button", type: "ERROR", text: "PLUS_API_KEY environment variable is not set")
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        } catch(let error) {
                                            
                                            Log.shared().print(page: "ViewEventDetail", fn: "button", type: "ERROR", text: "\(error)")
                                            print(error)
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
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 30, trailing: 70))
                }
                else {
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
                                                    //print(res)
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
                                                                Log.shared().print(page: "ViewEventDetail", fn: "button", type: "ERROR", text: "PLUS_API_KEY environment variable is not set")
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        } catch(let error) {
                                            
                                            Log.shared().print(page: "ViewEventDetail", fn: "button", type: "ERROR", text: "\(error)")
                                            print(error)
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
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 35, trailing: 60))
                }
            }
            else {
                if orientation.isLandscape {
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
                                                    //print(res)
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
                                                                Log.shared().print(page: "ViewEventDetail", fn: "button", type: "ERROR", text: "PLUS_API_KEY environment variable is not set")
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        } catch(let error) {
                                            
                                            Log.shared().print(page: "ViewEventDetail", fn: "button", type: "ERROR", text: "\(error)")
                                            print(error)
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
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 20))
                }
                else {
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
                                                    //print(res)
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
                                                                Log.shared().print(page: "ViewEventDetail", fn: "button", type: "ERROR", text: "PLUS_API_KEY environment variable is not set")
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        } catch(let error) {
                                            
                                            Log.shared().print(page: "ViewEventDetail", fn: "button", type: "ERROR", text: "\(error)")
                                            print(error)
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
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 70))
                }
            }
            
            
        }
    }
    
}
