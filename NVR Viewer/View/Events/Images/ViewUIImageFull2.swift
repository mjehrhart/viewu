//
//  ViewUIImageFull2.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 11/29/25.
//

import SwiftUI

struct ViewUIImageFull2: View {
    
    let api = APIRequester()
    let nvr = NVRConfig.shared()
    
    let urlString: String
    @State var data: Data?
    
    //Orientation Landscape/Portrait Mode
    @State var orientation = UIDevice.current.orientation
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    //Pinch and Zoom
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    
    //Use the dismiss action
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        HStack {
            if let data = data, let uiimage = UIImage(data: data){
                
                if orientation.isLandscape {
                    Image(uiImage: uiimage)
                        .resizable()
                    //.rotationEffect(.degrees(90)) //this is correct
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .aspectRatio( contentMode: .fit)
                        .scaledToFit()
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
                }
                else {
                    
                    ZStack{
                        Image(uiImage: uiimage)
                            .resizable()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .aspectRatio( contentMode: .fit)
                            .scaledToFit()
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
                        
                        //                        WatermarkContentView()
                        //                            .font(.system(size: 100))
                        //                            .opacity(0.6)
                        //                            .modifier(CardBackground2())
                        
                    }
                }
            }
            else {
                //Dummy Space
                Text("")
                    .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                    .frame(width: 250,height: 150)
                    .onAppear{
                        
                        Task{
                            await api.fetchImage(urlString: urlString, authType: nvr.getAuthType()){ (data, error) in
                                
                                if let error = error {
                                    
                                    Log.warning(page: "ViewUIImageFull", fn: "body", "\(error)")
                                    //if Event Snapshot is empty, show this instead
                                    //                                api.fetchImage(urlString: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQoBAeYwmKevvqaidagwfKDT6UXrei3kiWYlw&usqp=CAU"){ (data, error) in
                                    //                                    self.data = data
                                    //                                }
                                    
                                } else {
                                    self.data = data
                                }
                            }
                        }
                    }
            }
        }
        .navigationTitle("Snapshot Image")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss() // Manually dismiss the view
                }) {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                }
            }
        }
    }
}

struct WatermarkContentView: View {
    var body: some View {
        
        Bundle.main.iconFileName
            .flatMap { UIImage(named: $0) }
            .map { Image(uiImage: $0) }
        
    }
}


extension Bundle {
    var iconFileName: String? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconFileName = iconFiles.last
        else { return nil }
        return iconFileName
    }
}
