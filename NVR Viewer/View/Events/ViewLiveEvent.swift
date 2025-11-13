//
//  ViewLiveEvent.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//


import SwiftUI
import SwiftData

struct ViewLiveEvent: View {
 
    var epsA: [EndpointOptions]
    var x: [EndpointOptions] = []
    
    @EnvironmentObject private var mqttManager: MQTTManager
    @StateObject var mqttAppState = MQTTAppState()
    //@StateObject var sharedEndpointOptions = EndpointOptionsList.shared()
    
    @Query(sort: \ImageContainer.date, order: .reverse) var containers: [ImageContainer]
    @Environment(\.modelContext) var context
    
//FOR OPTION 3
    init(){
        epsA = EventStorage.shared.readAll()
    }
 
    var body: some View {
        Text("epsA:count==\(epsA.count)")
        ScrollView{
            ForEach(epsA, id: \.self) { eps in
                Text(eps.id!)
                    .onAppear(){ 
                    }
            }
        }
        Spacer()
        .padding([.top, .bottom], 3)
        .background(Gradient(colors: [.blue]).opacity(0.3))
        .hidden()
        
    }
    
    private func storeImage(name: String, urlString: String, date: Double, camera: String, label: String?, endPointsData: Data?){
        
        //CoreData
//        let eventContainer = Event(context: moc)
//        eventContainer.name = name
//        eventContainer.url = urlString
//        eventContainer.date = date
//        eventContainer.camera = camera
//        eventContainer.label = label!
//        eventContainer.endPoints = endPointsData
//
//        try?moc.save()
        
        //SwiftData
//        let imageContainer = ImageContainer(name: name, url: urlString, date: date, camera: camera, label: label!, endPoints: endPointsData)
//        context.insert(imageContainer)
    }
    
    private func removeFromLiveView(type: String, id: String ) {
        
        //Remove item from list since it is now stored in swiftdata
//        if let index = sharedEndpointOptions.list.firstIndex(of: id) { 
//            sharedEndpointOptions.list.remove(at: index)
//        }
//        sharedEndpointOptions.dics.removeValue(forKey: id)
    }
}

extension Array {
    mutating func mutateEach(by transform: (inout Element) throws -> Void) rethrows {
        self = try map { el in
            var el = el
            try transform(&el)
            return el
        }
    }
}

//#Preview {
//    ViewLiveEvent()
//}












