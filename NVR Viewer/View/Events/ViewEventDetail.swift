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
  
    //Orientation and Landscape/Portrait Mode
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
    @StateObject private var viewModel = DownloadViewModel()
    @StateObject private var vm = DownloadViewModel()
    
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
      
                        VStack(spacing: 2) {
                                InfoCard(
                                    title: container.cameraName ?? "",
                                    color: Color.orange.opacity(0.6),
                                    systemImage: "web.camera",
                                    width: geometry.size.width / 2
                                )

                                InfoCard(
                                    title: container.label ?? "",
                                    color: Color.red.opacity(0.6),
                                    systemImage: "figure.walk.motion",
                                    width: geometry.size.width / 2
                                )

                                if developerModeIsOn {
                                    InfoCard(
                                        title: container.type ?? "",
                                        color: Color.gray.opacity(0.6),
                                        systemImage: "moonphase.new.moon.inverse",
                                        width: geometry.size.width / 2
                                    )
                                }
                            }
                            .frame(width: geometry.size.width / 2, alignment: .trailing)
                         
                        EnteredZones(zones: container.enteredZones!)
                            .frame(maxWidth: .infinity, alignment: .leading)
                         
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    //Video Segment
                    if showClip {
                        Spacer()
                            .frame(height: 10)
                         
                        if( container.m3u8 != nil ){
 
                            HStack {
                                HStack(spacing: 10) {

                                    // Small gradient badge with icon
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        cBlue,
                                                        cBlue.opacity(0.7)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )

                                        Image(systemName: "play.rectangle.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                    .frame(width: 28, height: 28)

                                    // Title + subtle subtitle
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Video Segment")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(Color(red: 0.18, green: 0.18, blue: 0.18))

                                        Text("Recorded clip preview")
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundStyle(Color.gray.opacity(0.7))
                                    }
                                }

                                Spacer()

                                // Optional little “pill” status on the right
//                                Text("Live • H.264")
//                                    .font(.system(size: 11, weight: .semibold))
//                                    .padding(.horizontal, 10)
//                                    .padding(.vertical, 4)
//                                    .background(
//                                        Capsule()
//                                            .fill(Color.black.opacity(0.06))
//                                    )
//                                    .foregroundStyle(Color.gray.opacity(0.8))
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .padding(.bottom, 2)
                            
                            ViewPlayVideo(urlString: container.m3u8!, urlMp4String: container.mp4 ?? "", frameTime: container.frameTime!) 
                                .contentShape(Rectangle())
                        }
                    }
 
                    HStack {
                        HStack(spacing: 10) {

                            // Small gradient badge with icon
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                cBlue,
                                                cBlue.opacity(0.7)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 28, height: 28)

                            // Title + subtle subtitle
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Snapshot")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.18, green: 0.18, blue: 0.18))

                                Text("Event focused Image")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(Color.gray.opacity(0.7))
                            }
                        }

                        Spacer()

                        // Optional little “pill” status on the right
//                        Text("Live • H.264")
//                            .font(.system(size: 11, weight: .semibold))
//                            .padding(.horizontal, 10)
//                            .padding(.vertical, 4)
//                            .background(
//                                Capsule()
//                                    .fill(Color.black.opacity(0.06))
//                            )
//                            .foregroundStyle(Color.gray.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 2)
                    
                    ViewUIImageFull(urlString: container.snapshot!)
                    
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
    
    struct CardBackground1: ViewModifier {
        func body(content: Content) -> some View {
            content
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 4)
        }
    }
    
    struct EnteredZones2: View {
        
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
    
    private struct InfoCard: View {
        let title: String
        let color: Color
        let systemImage: String
        let width: CGFloat

        var body: some View {
            Rectangle()
                .fill(color)
                .frame(width: width, height: 50)
                .modifier(CardBackground1())
                .overlay(
                    Label(title.capitalized, systemImage: systemImage)
                        .font(.system(size: 15))
                        .fontWeight(.regular)
                        .foregroundColor(.white)
                )
        }
    }
    
    struct EnteredZones: View {

        private let zones: [String]

        init(zones: String) {
            // Split "zone1|zone2|zone3" into an array of clean strings
            self.zones = zones
                .split(separator: "|")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        var body: some View {
            if zones.isEmpty {
                ZoneRow(title: "No Zones Detected")
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .padding(0)
            } else {
                VStack(spacing: 8) {
                    ForEach(zones, id: \.self) { zone in
                        ZoneRow(title: zone)
                            .frame(maxHeight: .infinity)
                    }
                }
            }
        }
    }

    private struct ZoneRow: View {
        let title: String

        var body: some View {
            Rectangle()
                .fill(Color.blue.opacity(0.6))
                //.frame(height: 36)
                .modifier(CardBackground1())
                .overlay(
                    HStack {
                        Text(title)
                            .font(.system(size: 15))
                            .fontWeight(.regular)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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

func isLargeiPad() -> Bool {
    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width
    let longerDimension = max(screenHeight, screenWidth)
     
    return longerDimension > 1300
}

func isLargeiPhone() -> Bool {
    
    if UIDevice.current.userInterfaceIdiom == .phone {
        let screenHeight = UIScreen.main.nativeBounds.height / UIScreen.main.nativeScale
         
        return screenHeight >= 900.0
        
    }
    return false
}
 
func isMP4InvalidURL(_ option: String?) -> Bool {
    guard let value = option?.trimmingCharacters(in: .whitespacesAndNewlines),
          !value.isEmpty,
          URL(string: value) != nil else {
        print("Invalid mp4 URL: \(option ?? "nil")")
        return false
    }
    
    return true
}
 
 
 
