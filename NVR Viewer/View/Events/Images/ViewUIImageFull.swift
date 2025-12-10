//
//  ViewUIImageFull.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import SwiftUI
 
 struct ViewUIImageFull: View{
     
     let api = APIRequester()
     let nvr = NVRConfig.shared()
     
     let urlString: String
     @State var data: Data?
   
     
     let cBlue = Color(red: 0.153, green: 0.69, blue: 1)
     let menuTextColor = Color.white
     
     var developerModeIsOn: Bool = UserDefaults.standard.bool(forKey: "developerModeIsOn")
  
     private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
     @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
     @State private var showingAlert = false
     
     //Full Screen
     @State private var isFullScreen = false
     
     //Pinch and Zoom
     @State private var currentScale: CGFloat = 1.0
     @State private var finalScale: CGFloat = 1.0
      
     var body: some View {
         VStack(spacing: 0) {
             if let data = data, let uiimage = UIImage(data: data) {
  
                 VStack(spacing: 0) {

                     // MARK: Snapshot image (same behavior as before)
                     if idiom == .pad {
                         Image(uiImage: uiimage)
                             .resizable()
                             .scaledToFill()
                             .frame(maxWidth: .infinity)
                             .frame(height: isLandscape ? 485 : 350)
                             .clipped()
                             .allowsHitTesting(false)
                             .animation(.easeInOut, value: isLandscape)
                             .onRotate { orientation in
                                 if orientation.isValidInterfaceOrientation {
                                     isLandscape = orientation.isLandscape
                                 }
                             }
                     } else {
                         Image(uiImage: uiimage)
                             .resizable()
                             .scaledToFill()
                             .frame(maxWidth: .infinity)
                             .frame(height: isLandscape ? 350 : 230)
                             .clipped()
                             .allowsHitTesting(false)
                             .animation(.easeInOut, value: isLandscape)
                             .onRotate { orientation in
                                 if orientation.isValidInterfaceOrientation {
                                     isLandscape = orientation.isLandscape
                                 }
                             }
                     }
                         
 
                     let pillShape = BottomRoundedRectangle(radius: 22)

                     HStack(spacing: 12) {

                             // Left side: icon + text
                             HStack(spacing: 10) {
                                 ZStack {
                                     Circle()
                                         .fill(Color.white.opacity(0.18))

                                     Image(systemName: "photo.on.rectangle.angled")
                                         .font(.system(size: 18, weight: .semibold))
                                         .foregroundStyle(.white)
                                 }
                                 .frame(width: 34, height: 34)

                                 VStack(alignment: .leading, spacing: 2) {
                                     Text("Event Snapshot")
                                         .font(.system(size: 15, weight: .semibold))
                                         .foregroundStyle(.white)

                                     Text("Tap icons")
                                         .font(.system(size: 12))
                                         .foregroundStyle(.white.opacity(0.85))
                                         .lineLimit(1)
                                         .truncationMode(.tail)
                                 }
                             }

                             Spacer()

                             // Right side: download + fullscreen actions
                             HStack(spacing: 10) {

                                 // Download circle button
                                 Button {
                                     Task {
                                         if let image = await downloadImage(from: urlString) {
                                             ImageSaver().saveToPhotoLibrary(image)
                                             showingAlert = true
                                         }
                                     }
                                 } label: {
                                     ZStack {
                                         Circle()
                                             .fill(Color.white.opacity(0.60))

                                         Image(systemName: "square.and.arrow.down")
                                             .font(.system(size: 18, weight: .semibold))
                                             .foregroundStyle(cBlue)
                                     }
                                     .frame(width: 32, height: 32)
                                 }
                                 .buttonStyle(.plain)

                                 // Full-screen circle button
                                 Button {
                                     isFullScreen.toggle()
                                 } label: {
                                     ZStack {
                                         Circle()
                                             .fill(Color.white.opacity(0.60))

                                         Image(systemName: "arrow.down.left.and.arrow.up.right.rectangle")
                                             .font(.system(size: 18, weight: .semibold))
                                             .foregroundStyle(cBlue)
                                     }
                                     .frame(width: 32, height: 32)
                                 }
                                 .buttonStyle(.plain)
                             }
                         }
                         .padding(.horizontal, 15)
                         .padding(.vertical, 16)
                         .frame(maxWidth: .infinity)
                         .frame(maxHeight: 55) // added 12/9/25
                         .background(
                             LinearGradient(
                                 colors: [
                                     cBlue.opacity(0.6),
                                     cBlue.opacity(0.95)
                                 ],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing
                             )
                         )
                         .clipShape(pillShape)
                         .overlay(
                             ZStack {
                                 // Outer border
                                 pillShape
                                     .stroke(Color.white.opacity(0.25), lineWidth: 0.8)

                                 // Inner border (slightly inset)
                                 pillShape
                                     .inset(by: 8)
                                     .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                             }
                         )
                         .shadow(color: cBlue.opacity(0.35), radius: 8, x: 0, y: 4)
                     }
                     .frame(maxWidth: .infinity, alignment: .center)
                     .alert(isPresented: $showingAlert) {
                         Alert(
                             title: Text("Image Saved"),
                             message: Text("This image has been saved to Photos"),
                             dismissButton: .default(Text("OK"))
                         )
                     }
             } else {
                 Text("")
                     .frame(width: 250, height: 150)
                     .onAppear {
                         Task {
                             await api.fetchImage(urlString: urlString, authType: nvr.getAuthType()) { data, error in
                                 if error == nil {
                                     self.data = data
                                 }
                             }
                         }
                     }
             }
         }
         .modifier(CardBackground2())
         .frame(maxWidth: .infinity)
         .padding(.horizontal, 20)
         .navigationDestination(isPresented: $isFullScreen) {
             ViewUIImageFull2(urlString: urlString)
         }
     }
  
     struct CardBackground2: ViewModifier {
         func body(content: Content) -> some View {
             content
                 .cornerRadius(25)
                 .shadow(color: Color.black.opacity(0.2), radius: 4)
         }
     }
     
     struct CardBackground3: ViewModifier {
         func body(content: Content) -> some View {
             content
             //.cornerRadius(25)
                 .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 15, bottomTrailingRadius: 15))
                 .shadow(color: Color.black.opacity(0.2), radius: 4)
         }
     }
 }
 

