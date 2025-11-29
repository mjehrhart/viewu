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
import UIKit
import Photos

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
    
    let menuBGColor = Color.orange.opacity(0.6)
    let menuTextColor = Color.white
    let cBlue = Color(red: 0.153, green: 0.69, blue: 1)
    
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
    
    @State private var showingAlert = false
    
    
    //TODO Overlays
    var body: some View {
        
        //Top Bar Line
        HStack {
            Spacer()
            Rectangle()
                .fill(Color.orange)
                .frame(width: UIScreen.screenWidth * 0.85, height: 1.5)
            Spacer()
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity,maxHeight: 1.5 )
        
        
        GeometryReader { geometry in
            
            VStack {
                
                ScrollView(.vertical, showsIndicators: false) {
                    
                    //Top Layout Display Info
                    HStack{
                        VStack(spacing:2){
                            //Label("\(container.cameraName!.capitalized)", systemImage: "web.camera")
                            Rectangle()
                                .fill(Color.orange.opacity(0.6))
                                .padding(0)
                                .frame(width:(geometry.size.width / 2), height: 50)
                                .modifier(CardBackground2())
                                .overlay(
                                    Label("\(container.cameraName!.capitalized)", systemImage: "web.camera")
                                        .font(.system(size: 15))
                                        .fontWeight(.regular)
                                        .foregroundColor(.white)
                                )
                            
                            //Label("\(container.label!.capitalized)", systemImage: "figure.walk.motion")
                            Rectangle()
                                .fill(Color.red.opacity(0.6))
                                .padding(0)
                                .frame(width:(geometry.size.width / 2), height: 50)
                                .modifier(CardBackground2())
                                .overlay(
                                    Label("\(container.label!.capitalized)", systemImage: "figure.walk.motion")
                                        .font(.system(size: 15))
                                        .fontWeight(.regular)
                                        .foregroundColor(.white)
                                )
                            
                            
                            if developerModeIsOn {
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.6))
                                    .padding(0)
                                    .frame(width:(geometry.size.width / 2), height: 50)
                                    .modifier(CardBackground2())
                                    .overlay(
                                        Label("\(container.type!)", systemImage: "moonphase.new.moon.inverse")
                                            .font(.system(size: 15))
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .frame(width: geometry.size.width/2, alignment: .trailing)
                        
                        
                        if idiom == .pad {
                           if orientation.isLandscape {
                               VStack(spacing:2){
                                   EnteredZones(zones: container.enteredZones!)
                                       .frame( maxWidth: .infinity, alignment: .leading)
                               }
                               .frame( maxWidth: geometry.size.width * 2, alignment: .leading)
                           }
                           else {
                               VStack(spacing:2){
                                   EnteredZones(zones: container.enteredZones!)
                                       .frame( maxWidth: .infinity, alignment: .leading)
                               }
                               .frame( maxWidth: .infinity, alignment: .leading)
                           }
                        } else {
                            if orientation.isLandscape {
                                VStack(spacing:2){
                                    EnteredZones(zones: container.enteredZones!)
                                        .frame( maxWidth: .infinity, alignment: .leading)
                                }
                                .frame( maxWidth: geometry.size.width * 2, alignment: .leading)
                            }
                            else {
                                VStack(spacing:2){
                                    EnteredZones(zones: container.enteredZones!)
                                        .frame( maxWidth: .infinity, alignment: .leading)
                                }
                                .frame( maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                         
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    
                    //Video Segment
                    if showClip {
                        Spacer()
                            .frame(height: 10)
                        
                        if( container.m3u8 != nil ){
                            HStack{
                                Text("Video Segment")
                                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                    .font(.system(size: 20))
                                    .fontWeight(.regular)
                                    .foregroundStyle(Color(red: 0.35, green: 0.35, blue: 0.35))
                                    .frame(width: geometry.size.width, alignment: .leading)
                            }
                            
                            if idiom == .pad {
                                if orientation.isLandscape {
                                    ViewPlayVideo(urlString: container.m3u8!)
                                    //.modifier(CardBackground())
                                    //.overlay(CameraOverlayVideoClip(toCopy: container.m3u8! ), alignment: .bottomTrailing)
                                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                                        .aspectRatio(16/9, contentMode: .fill)
                                        .frame(width: ((geometry.size.width) ), alignment: .leading)
                                }
                                else {
                                    ViewPlayVideo(urlString: container.m3u8!)
                                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                                        .aspectRatio(16/9, contentMode: .fill)
                                        .frame(width: (geometry.size.width ),  alignment: .leading)
                                    //.background(.green)
                                }
                            } else {
                                if orientation.isLandscape {
                                    ViewPlayVideo(urlString: container.m3u8!)
                                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20))
                                        .aspectRatio(16/9, contentMode: .fill)
                                        .frame(width: (geometry.size.width + 20) ,  alignment: .leading)
                                    //.background(.orange)
                                }
                                else {
                                    ViewPlayVideo(urlString: container.m3u8!)
                                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 60))
                                        .aspectRatio(16/9, contentMode: .fill)
                                        .frame(width: geometry.size.width + 40, alignment: .leading)
                                    //.background(.brown)
                                }
                            } 
                        }
                    }
                    
                    //Snapshot
                    Spacer()
                        .frame(height: 40)
                    HStack{
                        Text("Snapshot")
                            .padding(10)
                            .font(.system(size: 20))
                            .fontWeight(.regular)
                            .foregroundStyle(Color(red: 0.35, green: 0.35, blue: 0.35))
                            .frame(width: geometry.size.width, alignment: .leading)
                    }
                    if idiom == .pad {
                        if orientation.isLandscape {
                            if(container.id != nil && container.snapshot != nil && container.frigatePlus != nil) {
                                ViewUIImageFull(urlString: container.snapshot!)
                                //.modifier(CardBackground())
                                //.overlay(CameraOverlaySnapShot(eventId: container.id!, toCopy: container.snapshot!, frigatePlus: container.frigatePlus! ), alignment: .bottomTrailing)
                                //.aspectRatio(16/9, contentMode: .fill)
                                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                                    .frame(maxWidth: geometry.size.width, maxHeight: .infinity, alignment: .leading)
                            }
                            //Obsolete since the app now does http fetch
                            //ViewEventSlideShow(eventId: container.id!)
                        }
                        else {
                            if(container.id != nil && container.snapshot != nil && container.frigatePlus != nil) {
                                ViewUIImageFull(urlString: container.snapshot!)
                                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                                    .frame(maxWidth: geometry.size.width, maxHeight: .infinity, alignment: .leading)
                                //.background(.yellow)
                            }
                        }
                    }
                    else {
                        if orientation.isLandscape {
                            
                            if(container.id != nil && container.snapshot != nil && container.frigatePlus != nil) {
                                ViewUIImageFull(urlString: container.snapshot!)
                                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                    .frame(maxWidth: geometry.size.width, maxHeight: .infinity, alignment: .leading)
                                //.background(Color.green)
                            }
                        }
                        else {
                            if(container.id != nil && container.snapshot != nil && container.frigatePlus != nil) {
                                
                                ViewUIImageFull(urlString: container.snapshot!)
                                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 60))
                                    .frame(maxWidth: (geometry.size.width + 40), maxHeight: .infinity,  alignment: .leading)
                                //.background(Color.yellow)
                            }
                        }
                    }
                    
                    
                    //Dumbest fix ever! =)
                    if idiom == .pad {
                   
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                    } else {
                     
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                        Text("")
                    }
                    
                } // End of ScrollView
                
                
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
    
    struct CardBackground2: ViewModifier {
        func body(content: Content) -> some View {
            content
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.2), radius: 4)
        }
    }
    
    struct EnteredZones: View {
        
        let zones:String
        var enteredZones: Array<Substring>;
        
        @State var orientation = UIDevice.current.orientation
        private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
        
        let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .makeConnectable()
            .autoconnect()
        
        init(zones: String) {
            self.zones = zones
            enteredZones = zones.split(separator: "|")
        }
        
        var body: some View {
            
            //iPAD
            if idiom == .pad {
                if orientation.isLandscape {
                    if !enteredZones.isEmpty {
                        
                        GeometryReader{ geometry in
                            VStack(spacing:2){
                                
                                ForEach(enteredZones, id: \.self) { zone in
                                    
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.6))
                                        .padding(0)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity) //(geometry.size.width * 5)+80
                                        .modifier(CardBackground2())
                                        .overlay(
                                            Label("\(zone)", systemImage: "")
                                                .font(.system(size: 15))
                                                .fontWeight(.regular)
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, maxHeight: 20) //max(.infinity, 400) geometry.size.width
                                        )
                                        //.padding(.trailing, 20)
                                }
                            }
                            //.frame( maxWidth: (geometry.size.width  * 4), alignment: .leading)
                            .frame( maxWidth: .infinity, alignment: .leading)
                            //.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: -150))
                        }
                    }
                    else {
                        VStack(spacing:2){
                            
                            Rectangle()
                                .fill(Color.blue.opacity(0.6))
                                .padding(0)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .modifier(CardBackground2())
                                .overlay(
                                    Label("No Zones Detected", systemImage: "")
                                        .font(.system(size: 15))
                                        .fontWeight(.regular)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, maxHeight: 20)
                                )
                                //.padding(.trailing, 40)
                        }
                        .frame( maxWidth: .infinity, alignment: .leading)
                        .padding(0)
                    }
                }
                else {
                    if !enteredZones.isEmpty {
                        
                        GeometryReader{ geometry in
                            VStack(spacing:2){
                                
                                ForEach(enteredZones, id: \.self) { zone in
                                    
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.6))
                                        .padding(0)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity) //(geometry.size.width * 5)+80
                                        .modifier(CardBackground2())
                                        .overlay(
                                            Label("\(zone)", systemImage: "")
                                                .font(.system(size: 15))
                                                .fontWeight(.regular)
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, maxHeight: 20) //max(.infinity, 400) geometry.size.width
                                        )
                                        //.padding(.trailing, 20)
                                }
                            }
                            //.frame( maxWidth: (geometry.size.width  * 4), alignment: .leading)
                            .frame( maxWidth: .infinity, alignment: .leading)
                            //.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: -150))
                        }
                    }
                    else {
                        GeometryReader{ geometry in
                            VStack(spacing:2){
                                
                                Rectangle()
                                    .fill(Color.blue.opacity(0.6))
                                    .padding(0)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .modifier(CardBackground2())
                                    .overlay(
                                        Label("No Zones Detected", systemImage: "")
                                            .font(.system(size: 15))
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, maxHeight: 20)
                                    )
                                    //.padding(.trailing, 40)
                            }
                            .frame( maxWidth: geometry.size.width  * 2, alignment: .leading)
                            .padding(0)
                        }
                    }
                }
            }
            //iPHONE
            else {
                if orientation.isLandscape {
                    if !enteredZones.isEmpty {
                        
                        GeometryReader{ geometry in
                            VStack(spacing:2){
                                
                                ForEach(enteredZones, id: \.self) { zone in
                                    
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.6))
                                        .padding(0)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity) //(geometry.size.width * 5)+80
                                        .modifier(CardBackground2())
                                        .overlay(
                                            Label("\(zone)", systemImage: "")
                                                .font(.system(size: 15))
                                                .fontWeight(.regular)
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, maxHeight: 20) //max(.infinity, 400) geometry.size.width
                                        )
                                        //.padding(.trailing, 20)
                                }
                            }
                            //.frame( maxWidth: (geometry.size.width  * 4), alignment: .leading)
                            .frame( maxWidth: .infinity, alignment: .leading)
                            //.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: -150))
                        }
                    }
                    else {
                        GeometryReader{ geometry in
                            VStack(spacing:2){
                                
                                Rectangle()
                                    .fill(Color.blue.opacity(0.6))
                                    .padding(0)
                                    .frame(maxWidth: geometry.size.width  * 2, maxHeight: .infinity)
                                    .modifier(CardBackground2())
                                    .overlay(
                                        Label("No Zones Detected", systemImage: "")
                                            .font(.system(size: 15))
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, maxHeight: 20)
                                    )
                                    //.padding(.trailing, 40)
                            }
                            .frame( maxWidth: geometry.size.width  * 2, alignment: .leading)
                            .padding(0)
                        }
                    }
                }
                else {
                    if !enteredZones.isEmpty {
                        
                        GeometryReader{ geometry in
                            VStack(spacing:2){
                                
                                ForEach(enteredZones, id: \.self) { zone in
                                    
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.6))
                                        .padding(0)
                                        .frame(maxWidth:(geometry.size.width * 2), maxHeight: .infinity)
                                        .modifier(CardBackground2())
                                        .overlay(
                                            Label("\(zone)", systemImage: "")
                                                .font(.system(size: 15))
                                                .fontWeight(.regular)
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, maxHeight: 20)
                                        )
                                        .padding(.trailing, 40)
                                }
                            }
                            .frame( maxWidth: geometry.size.width  * 2, alignment: .leading)
                            .padding(0)
                        }
                    }
                    else {
                        GeometryReader{ geometry in
                            VStack(spacing:2){
                                
                                Rectangle()
                                    .fill(Color.blue.opacity(0.6))
                                    .padding(0)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .modifier(CardBackground2())
                                    .overlay(
                                        Label("No Zones Detected", systemImage: "")
                                            .font(.system(size: 15))
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, maxHeight: 20)
                                    )
                                    .padding(.trailing, 40)
                            }
                            .frame( maxWidth: geometry.size.width  * 2, alignment: .leading)
                            .padding(0)
                        }
                    }
                }
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
                        .foregroundStyle(.white)
                        .font(.system(size: 24))
                        
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 40))
                        .frame(maxWidth: .infinity, maxHeight: 300, alignment: .trailing)
                    }
                    .padding(EdgeInsets(top: 00, leading: 0, bottom: 0, trailing: 40))
                    .frame(maxWidth: .infinity, maxHeight: 300, alignment: .trailing)
                    
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
        
        @State private var showingAlert = false
        
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
                        
                        //                        Button{
                        //                            UIPasteboard.general.string = toCopy
                        //                        } label: {
                        //                            Image(systemName: "doc.on.doc")
                        //                        }
                        //                        .frame(width: 340, alignment: .trailing)
                        //                        .foregroundColor(.white)
                        //                        .fontWeight(.bold)
                        
                        //                        ShareLink(item: toCopy, preview: SharePreview("Viewu SnapshotE", image: toCopy)){
                        //                            Image(systemName: "square.and.arrow.up")
                        //                        }
                        //                        .frame(alignment: .trailing)
                        //                        .foregroundColor(.white)
                        //                        .fontWeight(.bold)
                        
                        Label("", systemImage: "square.and.arrow.down")
                            .onTapGesture {
                                Task {
                                    let urlString = toCopy
                                    if let image = await downloadImage(from: urlString) {
                                        ImageSaver().saveToPhotoLibrary(image)
                                        
                                        showingAlert = true
                                    }
                                    
                                }
                            }
                            .alert(isPresented: $showingAlert) {
                                Alert(title: Text("Image Saved"),
                                      message: Text("This image has been saved to Photos"),
                                      dismissButton: .default(Text("OK")))
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
        
        
        
        /*
         func saveImageToPhotos(image: UIImage) {
         PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
         switch status {
         case .authorized:
         UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
         case .denied, .restricted:
         print("Access to photo library denied or restricted.")
         // Handle denied/restricted access (e.g., show an alert)
         case .notDetermined:
         // This case should ideally not be reached if requestAuthorization is called
         print("Photo library access not determined.")
         case .limited:
         // Handle limited access in iOS 14+
         print("Limited access to photo library.")
         @unknown default:
         fatalError("Unknown PHAuthorizationStatus")
         }
         }
         }
         
         //@objc
         func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
         if let error = error {
         print("Error saving image: \(error.localizedDescription)")
         } else {
         print("Image saved successfully to Photos.")
         }
         }
         */
    }
}

func downloadImage(from urlString: String) async -> UIImage? {
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return nil
    }
    
    do {
        // Asynchronously download the data
        let (data, _) = try await URLSession.shared.data(from: url)
        // Create a UIImage from the downloaded data
        return UIImage(data: data)
    } catch {
        print("Error downloading image: \(error.localizedDescription)")
        return nil
    }
}

class ImageSaver: NSObject {
    func saveToPhotoLibrary(_ image: UIImage) {
        // This function asks for permission and saves the image
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }
    
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer) {
        if let error = error {
            // Handle the error (e.g., user denied permission)
            print("Save error: \(error.localizedDescription)")
        } else {
            // Image saved successfully
            print("Image saved successfully!")
        }
    }
}
