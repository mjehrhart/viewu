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
    @State var zoomIn: Bool = false
    
    let cBlue = Color(red: 0.153, green: 0.69, blue: 1)
    let menuTextColor = Color.white
    
    var developerModeIsOn: Bool = UserDefaults.standard.bool(forKey: "developerModeIsOn")
    
    @State var orientation = UIDevice.current.orientation
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    @State private var showingAlert = false
    
    //Full Screen
    @State private var isFullScreen = false
    
    //Pinch and Zoom
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    
    var body: some View {
        
        GeometryReader { geometry in
            if let data = data, let uiimage = UIImage(data: data){
                
                //iPAD
                if idiom == .pad {
                    if orientation.isLandscape {
                        
                        VStack( spacing: 0){
                            
                            Image(uiImage: uiimage)
                                .resizable()
                                .frame(width: geometry.size.width, height: 690,  alignment: .leading)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .aspectRatio( contentMode: .fill)
                                .scaledToFill()
                                .scaleEffect(currentScale * finalScale)
                                .gesture(
                                    MagnifyGesture()
                                        .onChanged { value in
                                            currentScale = value.magnification
                                        }
                                        .onEnded { value in
                                            finalScale *= value.magnification
                                            currentScale = 1.0
                                        }
                                )
                            
                            HStack(alignment: .lastTextBaseline){
                                
                                ZStack{
                                    //Setting the background white so that the blue may be opaque below
                                    Label("", systemImage: "")
                                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
                                        .frame(width: geometry.size.width, height: 50, alignment: .trailing)
                                        .background(.white)
                                    
                                    HStack(alignment: .lastTextBaseline){
                                        
                                        VStack(spacing: 2) {
                                            Label("", systemImage: "square.and.arrow.down")
                                                .foregroundStyle(menuTextColor)
                                                .foregroundStyle(.blue.opacity(0.6))
                                                .font(.system(size: 24))
                                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                                .onTapGesture {
                                                    Task {
                                                        let urlString = urlString
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
                                        }
                                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
                                        .frame(height: 50, alignment: .top)
                                        //.background(.orange)
                                        
                                        Label("", systemImage: "arrow.down.left.and.arrow.up.right.rectangle")
                                            .foregroundStyle(menuTextColor)
                                            .foregroundStyle(.blue.opacity(0.6))
                                            .font(.system(size: 24))
                                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                            .frame(height: 50, alignment: .bottom)
                                        //.background(cBlue.opacity(0.6))
                                            .onTapGesture {
                                                isFullScreen.toggle()
                                            }
                                    }
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
                                    .frame(width: geometry.size.width, height: 50, alignment: .trailing)
                                    .background(cBlue.opacity(0.6))
                                }
                            }
                            
                            if developerModeIsOn {
                                Text("\(urlString)")
                                    .font(.system(size: 15))
                                    .fontWeight(.regular)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .textSelection(.enabled)
                            }
                        }
                        .modifier( CardBackground2() )
                    }
                    else {
                        VStack( spacing: 0){
                            
                            Image(uiImage: uiimage)
                                .resizable()
                                .frame(width: geometry.size.width, height: 450,  alignment: .leading)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .aspectRatio( contentMode: .fill)
                                .scaledToFill()
                                .scaleEffect(currentScale * finalScale)
                                .gesture(
                                    MagnifyGesture()
                                        .onChanged { value in
                                            currentScale = value.magnification
                                        }
                                        .onEnded { value in
                                            finalScale *= value.magnification
                                            currentScale = 1.0
                                        }
                                )
                            
                            HStack(alignment: .lastTextBaseline){
                                
                                ZStack{
                                    //Setting the background white so that the blue may be opaque below
                                    Label("", systemImage: "")
                                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
                                        .frame(width: geometry.size.width, height: 50, alignment: .trailing)
                                        .background(.white)
                                    
                                    HStack(alignment: .lastTextBaseline){
                                        
                                        VStack(spacing: 2) {
                                            Label("", systemImage: "square.and.arrow.down")
                                                .foregroundStyle(menuTextColor)
                                                .foregroundStyle(.blue.opacity(0.6))
                                                .font(.system(size: 24))
                                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                                .onTapGesture {
                                                    Task {
                                                        let urlString = urlString
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
                                        }
                                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
                                        .frame(height: 50, alignment: .top)
                                        //.background(.orange)
                                        
                                        Label("", systemImage: "arrow.down.left.and.arrow.up.right.rectangle")
                                            .foregroundStyle(menuTextColor)
                                            .foregroundStyle(.blue.opacity(0.6))
                                            .font(.system(size: 24))
                                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                            .frame(height: 50, alignment: .bottom)
                                        //.background(cBlue.opacity(0.6))
                                            .onTapGesture {
                                                isFullScreen.toggle()
                                            }
                                    }
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
                                    .frame(width: geometry.size.width, height: 50, alignment: .trailing)
                                    .background(cBlue.opacity(0.6))
                                }
                            }
                            
                            if developerModeIsOn {
                                Text("\(urlString)")
                                    .font(.system(size: 15))
                                    .fontWeight(.regular)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .textSelection(.enabled)
                            }
                        }
                        .modifier( CardBackground2() )
                    }
                }
                // iPHONE
                else {
                    if orientation.isLandscape {
                        
                        VStack( spacing: 0){
                            
                            Image(uiImage: uiimage)
                                .resizable()
                                .frame(maxWidth: geometry.size.width, maxHeight: 450, alignment: .leading)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .aspectRatio( contentMode: .fill)
                                .scaledToFill()
                                .scaleEffect(currentScale * finalScale)
                                .gesture(
                                    MagnifyGesture()
                                        .onChanged { value in
                                            currentScale = value.magnification
                                        }
                                        .onEnded { value in
                                            finalScale *= value.magnification
                                            currentScale = 1.0
                                        }
                                )
                            
                            HStack(alignment: .lastTextBaseline){
                                
                                ZStack{
                                    //Setting the background white so that the blue may be opaque below
                                    Label("", systemImage: "")
                                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
                                        .frame(width: geometry.size.width, height: 50, alignment: .trailing)
                                        .background(.white)
                                    
                                    HStack(alignment: .lastTextBaseline){
                                        
                                        VStack(spacing: 2) {
                                            Label("", systemImage: "square.and.arrow.down")
                                                .foregroundStyle(menuTextColor)
                                                .foregroundStyle(.blue.opacity(0.6))
                                                .font(.system(size: 24))
                                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                                .onTapGesture {
                                                    Task {
                                                        let urlString = urlString
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
                                        }
                                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
                                        .frame(height: 50, alignment: .top)
                                        //.background(.orange)
                                        
                                        Label("", systemImage: "arrow.down.left.and.arrow.up.right.rectangle")
                                            .foregroundStyle(menuTextColor)
                                            .foregroundStyle(.blue.opacity(0.6))
                                            .font(.system(size: 24))
                                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                            .frame(height: 50, alignment: .bottom)
                                        //.background(cBlue.opacity(0.6))
                                            .onTapGesture {
                                                isFullScreen.toggle()
                                            }
                                    }
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
                                    .frame(width: geometry.size.width, height: 50, alignment: .trailing)
                                    .background(cBlue.opacity(0.6))
                                }
                            }
                            
                            if developerModeIsOn {
                                Text("\(urlString)")
                                    .font(.system(size: 15))
                                    .fontWeight(.regular)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .textSelection(.enabled)
                            }
                        }
                        .modifier( CardBackground2() )
                        
                    }
                    else {
                        VStack( spacing: 0){
                            
                            Image(uiImage: uiimage)
                                .resizable()
                                .frame(maxWidth: geometry.size.width, maxHeight: 250, alignment: .leading)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .aspectRatio( contentMode: .fill)
                                .scaledToFill()
                                .scaleEffect(currentScale * finalScale)
                                .gesture(
                                    MagnifyGesture()
                                        .onChanged { value in
                                            currentScale = value.magnification
                                        }
                                        .onEnded { value in
                                            finalScale *= value.magnification
                                            currentScale = 1.0
                                        }
                                )
                            
                            HStack(alignment: .lastTextBaseline){
                                
                                ZStack{
                                    //Setting the background white so that the blue may be opaque below
                                    Label("", systemImage: "")
                                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
                                        .frame(width: geometry.size.width, height: 50, alignment: .trailing)
                                        .background(.white)
                                    
                                    HStack(alignment: .lastTextBaseline){
                                        
                                        VStack(spacing: 2) {
                                            Label("", systemImage: "square.and.arrow.down")
                                                .foregroundStyle(menuTextColor)
                                                .foregroundStyle(.blue.opacity(0.6))
                                                .font(.system(size: 24))
                                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                                .onTapGesture {
                                                    Task {
                                                        let urlString = urlString
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
                                        }
                                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
                                        .frame(height: 50, alignment: .top)
                                        //.background(.orange)
                                        
                                        Label("", systemImage: "arrow.down.left.and.arrow.up.right.rectangle")
                                            .foregroundStyle(menuTextColor)
                                            .foregroundStyle(.blue.opacity(0.6))
                                            .font(.system(size: 24))
                                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                            .frame(height: 50, alignment: .bottom)
                                        //.background(cBlue.opacity(0.6))
                                            .onTapGesture {
                                                isFullScreen.toggle()
                                            }
                                    }
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
                                    .frame(width: geometry.size.width, height: 50, alignment: .trailing)
                                    .background(cBlue.opacity(0.6))
                                }
                            }
                            
                            if developerModeIsOn {
                                Text("\(urlString)")
                                    .font(.system(size: 15))
                                    .fontWeight(.regular)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .textSelection(.enabled)
                            }
                        }
                        .modifier( CardBackground2() )
                         
                    }
                }
                
                
            } else {
                //Dummy Space
                Text("")
                    .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                    .frame(width: 250,height: 150)
                    .onAppear{
                        
                        Task {
                            await api.fetchImage(urlString: urlString, authType: nvr.getAuthType()){ (data, error) in
                                 
                                if let error = error {
                                    
//                                    Log.shared().print(page: "ViewUIImageFull", fn: "onAppear", type: "ERROR", text: "\(error)")
//                                    //if Event Snapshot is empty, show this instead
////                                    await api.fetchImage(urlString: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQoBAeYwmKevvqaidagwfKDT6UXrei3kiWYlw&usqp=CAU", authType: nvr.getAuthType()){ (data, error) in
////                                        self.data = data
////                                    }
                                    
                                } else {
                                    self.data = data
                                }
                            }
                        }
                    }
            }
        }
        .navigationDestination(isPresented: $isFullScreen){
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
