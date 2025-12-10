//
//  ViewEventDetail.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import SwiftUI
import AVKit
import SwiftData
import UIKit
import Photos

struct ViewEventDetail: View {

    let text: String
    let container: EndpointOptions
    let urlMp4String: String

    private let nvr = NVRConfig.shared()
    @EnvironmentObject private var notificationManager2: NotificationManager

    private let menuBGColor = Color.orange.opacity(0.6)
    private let menuTextColor = Color.white
    private let cBlue = Color(red: 0.153, green: 0.69, blue: 1)

    @AppStorage("developerModeIsOn") private var developerModeIsOn: Bool = false

    let showButton: Bool
    let showClip: Bool

    // simple 50/50 width split using screen width
    private var halfWidth: CGFloat {
        UIScreen.screenWidth / 2
    }

    init(
        text: String,
        container: EndpointOptions,
        path: NavigationPath = NavigationPath(),
        showButton: Bool,
        showClip: Bool
    ) {
        self.text = text
        self.container = container
        self.showButton = showButton
        self.showClip = showClip

        // Prefer explicit mp4 if valid, otherwise fall back to Frigate URL
        if isValidMp4URL(container.mp4) {
            self.urlMp4String = container.mp4!.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let nvr = NVRConfig.shared()
            self.urlMp4String = nvr.getUrl() + "/api/events/\(container.id ?? "")/clip.mp4"
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // Top bar line
            HStack {
                Spacer()
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: UIScreen.screenWidth * 0.85, height: 1.5)
                Spacer()
            }
            .padding(.top, 10)
            .padding(.bottom, 20)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: - Misc Details
                    HStack {
                        VStack(spacing: 2) {
                            InfoCard(
                                title: container.cameraName ?? "",
                                color: Color.orange.opacity(0.6),
                                systemImage: "web.camera",
                                width: halfWidth
                            )

                            InfoCard(
                                title: container.label ?? "",
                                color: Color.red.opacity(0.6),
                                systemImage: "figure.walk.motion",
                                width: halfWidth
                            )

                            if developerModeIsOn {
                                InfoCard(
                                    title: container.type ?? "",
                                    color: Color.gray.opacity(0.6),
                                    systemImage: "moonphase.new.moon.inverse",
                                    width: halfWidth
                                )
                            }
                        }
                        .frame(width: halfWidth, alignment: .trailing)

                        EnteredZones(zones: container.enteredZones ?? "")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                    // MARK: - Video header + player
                    if showClip, let m3u8 = container.m3u8 {
                        HStack {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [cBlue, cBlue.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )

                                    Image(systemName: "play.rectangle.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                .frame(width: 28, height: 28)

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
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 2)

                        // ViewPlayVideoMP4 is greatly preferred over ViewPlayVideoM3U8Segments
                        // But ViewVideoPlayStreamM3U8 is the main priority when possible
                        if isHttpsLanURL(nvr.getUrl()) {
                            ViewPlayVideoMP4(
                                urlString: m3u8,
                                urlMp4String: urlMp4String,
                                frameTime: container.frameTime ?? 1
                            )
                        } else {
                            ViewVideoPlayStreamM3U8(
                                urlString: m3u8,
                                urlMp4String: urlMp4String,
                                frameTime: container.frameTime ?? 0
                            )
                        }
                    }

                    // MARK: - Snapshot Header
                    HStack {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [cBlue, cBlue.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 28, height: 28)

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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 2)

                    // MARK: - Snapshot Image
                    if let snapshot = container.snapshot {
                        ViewUIImageFull(urlString: snapshot)
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
                        .onTapGesture {
                            notificationManager2.newPage = 0
                        }
                }
            }
        }
        .navigationBarTitle(text, displayMode: .inline)
    }
}

// MARK: - Info card

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

// MARK: - EnteredZones

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

// MARK: - Global utilities (good candidates to move to a shared file)

/// Simple async image downloader.
func downloadImage(from urlString: String) async -> UIImage? {
    guard let url = URL(string: urlString) else {
        Log.shared().print(page: "ViewEventDetail",
                           fn: "downloadImage",
                           type: "WARNING",
                           text: "Invalid URL - \(urlString)")
        return nil
    }

    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        return UIImage(data: data)
    } catch {
        Log.shared().print(page: "ViewEventDetail",
                           fn: "downloadImage",
                           type: "ERROR",
                           text: "Error downloading image: \(error.localizedDescription)")
        return nil
    }
}

class ImageSaver: NSObject {
    func saveToPhotoLibrary(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }

    @objc private func saveCompleted(_ image: UIImage,
                                     didFinishSavingWithError error: Error?,
                                     contextInfo: UnsafeMutableRawPointer) {
        if let error = error { 
            Log.shared().print(page: "ViewEventDetail",
                               fn: "ImageSaver",
                               type: "ERROR",
                               text: "Save Error \(error.localizedDescription)")
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
    guard UIDevice.current.userInterfaceIdiom == .phone else { return false }
    let screenHeight = UIScreen.main.nativeBounds.height / UIScreen.main.nativeScale
    return screenHeight >= 900.0
}

/// Returns `true` if the mp4 URL is valid, `false` otherwise.
func isValidMp4URL(_ option: String?) -> Bool {
 
    guard let value = option?.trimmingCharacters(in: .whitespacesAndNewlines),
          !value.isEmpty,
          URL(string: value) != nil else {
          Log.shared().print(page: "ViewEventDetail",
                           fn: "isValidMp4URL",
                           type: "ERROR",
                           text: "Invalid mp4 URL: \(option ?? "")")
        return false
    }
    return true
}

/// Backwards-compat wrapper; prefer `isValidMp4URL`.
@available(*, deprecated, message: "Use isValidMp4URL(_:) instead")
func isMP4InvalidURL(_ option: String?) -> Bool {
    isValidMp4URL(option)
}

struct CardBackground1: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 4)
    }
}

struct CardBackground2: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.2), radius: 4)
    }
}

// MARK: - Rotation helper (used by other views)

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                action(UIDevice.current.orientation)
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIDevice.orientationDidChangeNotification
                )
            ) { _ in
                action(UIDevice.current.orientation)
            }
    }
}



/*
import SwiftUI
import AVKit
import SwiftData
import UIKit
import Photos

struct ViewEventDetail: View {

    let text: String
    let container: EndpointOptions
    var urlMp4String: String = ""

    let nvr = NVRConfig.shared()
    @EnvironmentObject private var notificationManager2: NotificationManager

    let menuBGColor = Color.orange.opacity(0.6)
    let menuTextColor = Color.white
    let cBlue = Color(red: 0.153, green: 0.69, blue: 1)
    
    @State private var player = AVPlayer()
    @State private var path = NavigationPath()
    
    var frigatePlusOn: Bool = UserDefaults.standard.bool(forKey: "frigatePlusOn")
    var developerModeIsOn: Bool = UserDefaults.standard.bool(forKey: "developerModeIsOn")
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
     
    @State private var showButton: Bool
    @State private var showClip: Bool
    @State var selection: Int = 0
     
    // simple 50/50 width split using screen width
    private var halfWidth: CGFloat {
        UIScreen.screenWidth / 2
    }
    
    init(text: String,
         container: EndpointOptions,
         path: NavigationPath = NavigationPath(),
         showButton: Bool,
         showClip: Bool)
    {
        self.text = text
        self.container = container

        let nvr = NVRConfig.shared()
        if isMP4InvalidURL(container.mp4 ?? "") {
            urlMp4String = container.mp4 ?? ""
        } else {
            urlMp4String = nvr.getUrl() + "/api/events/\(container.id ?? "")/clip.mp4"
        }

        _showButton = State(initialValue: showButton)
        _showClip   = State(initialValue: showClip)
    }
 
    var body: some View {
        VStack(spacing: 0) {

            // Top bar line
            HStack {
                Spacer()
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: UIScreen.screenWidth * 0.85, height: 1.5)
                Spacer()
            }
            .padding(.top, 10)
            .padding(.bottom, 20)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Misc Details
                    HStack {
                        VStack(spacing: 2) {
                            InfoCard(
                                title: container.cameraName ?? "",
                                color: Color.orange.opacity(0.6),
                                systemImage: "web.camera",
                                width: halfWidth
                            )
                            
                            InfoCard(
                                title: container.label ?? "",
                                color: Color.red.opacity(0.6),
                                systemImage: "figure.walk.motion",
                                width: halfWidth
                            )
                            
                            if developerModeIsOn {
                                InfoCard(
                                    title: container.type ?? "",
                                    color: Color.gray.opacity(0.6),
                                    systemImage: "moonphase.new.moon.inverse",
                                    width: halfWidth
                                )
                            }
                        }
                        .frame(width: halfWidth, alignment: .trailing)
                        
                        EnteredZones(zones: container.enteredZones ?? "")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Video header
                    if showClip, container.m3u8 != nil {
                        HStack {
                            HStack(spacing: 10) {
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
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 2)

                        // ViewPlayVideoMP4 is greatly preferred over ViewPlayVideoM3U8Segments
                        // But ViewVideoPlayStreamM3U8 is the main priority when possible
                        
                        if isHttpsLanURL(nvr.getUrl()) {
//                        ViewPlayVideoM3U8Segments(
//                            urlString: container.m3u8!,
//                            urlMp4String: urlMp4String,
//                            frameTime: container.frameTime ?? 0
//                        )
                            
                            ViewPlayVideoMP4(
                                urlString: container.m3u8!,
                                urlMp4String: urlMp4String,
                                frameTime: container.frameTime ?? 1
                            )
                        } else {
                            ViewVideoPlayStreamM3U8(
                                urlString: container.m3u8!,
                                urlMp4String: urlMp4String,
                                frameTime: container.frameTime ?? 0
                            )
                        }
                    }
 
                    // MARK: Snapshot Header
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 2)
                    
                    // MARK: Snapshot Image
                    if let snapshot = container.snapshot {
                        ViewUIImageFull(urlString: snapshot)
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
                        .onTapGesture {
                            notificationManager2.newPage = 0
                        }
                }
            }
        }
        .navigationBarTitle(text, displayMode: .inline)
    }
}

// MARK: - Helpers

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

// MARK: - EnteredZones

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


// MOVE TO GLOBAL SEPERATE FILES
func downloadImage(from urlString: String) async -> UIImage? {
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return nil
    }
    
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        return UIImage(data: data)
    } catch {
        print("Error downloading image: \(error.localizedDescription)")
        return nil
    }
}

class ImageSaver: NSObject {
    func saveToPhotoLibrary(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }
    
    @objc func saveCompleted(_ image: UIImage,
                             didFinishSavingWithError error: Error?,
                             contextInfo: UnsafeMutableRawPointer)
    {
        if let error = error {
            print("Save error: \(error.localizedDescription)")
        } else {
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

/// Returns `true` if the mp4 URL is **valid**, `false` otherwise.
func isMP4InvalidURL(_ option: String?) -> Bool {
    print("[DEBUG] 🔎 isMP4InvalidURL()\n")
    guard let value = option?.trimmingCharacters(in: .whitespacesAndNewlines),
          !value.isEmpty,
          URL(string: value) != nil else {
        print("Invalid mp4 URL: \(option ?? "nil")")
        return false
    }
    return true
}

struct CardBackground1: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 4)
    }
}

//move to a seperate file
//import SwiftUI
//
// Rotation helper (unchanged)
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                action(UIDevice.current.orientation)
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIDevice.orientationDidChangeNotification
                )
            ) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

struct CardBackground2: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.2), radius: 4)
    }
}
*/
