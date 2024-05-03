//
//  ViewLiveEvent.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//


import SwiftUI
import SwiftData

struct ViewLiveEvent: View {
     
    //STOPPED HERE NEED TO GET PAST THIS HURDLE
//    @Environment(\.managedObjectContext) var moc
//    @FetchRequest(sortDescriptors: []) var events: FetchedResults<Event>
    
    
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
        //.fixedSize(horizontal: false, vertical: true)
        //.frame(width:300, height:50, alignment: .leading)
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
    
    private func convertDate(time: Double) -> String{
        let date = Date(timeIntervalSince1970: time)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM YYYY dd" // hh:mm a"
        dateFormatter.timeStyle = DateFormatter.Style.none
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeZone = .current
        let localDate = dateFormatter.string(from: date)
        return localDate
    }
    
    private func convertTime(time: Double) -> String{
        let date = Date(timeIntervalSince1970: time)
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateStyle = DateFormatter.Style.none
        dateFormatter.timeZone = .current
        let localDate = dateFormatter.string(from: date)
        return localDate
    }
    
    private func convertDateTime(time: Double) -> String{
        let date = Date(timeIntervalSince1970: time)
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeZone = .current
        var localDate = dateFormatter.string(from: date)
        localDate.replace("at", with: "")
        return localDate
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


//OPTION1 - Lists and Dictionaries
//                ForEach(mqttAppState.sharedEndpointOptions.list, id: \.self) { key in
//                    ForEach(mqttAppState.sharedEndpointOptions.dics[key]!.reversed(), id: \.self ){ eps in
//
//                        if eps.type == "new" {
//                            Spacer()
//                                .onAppear(){
//
//                                    var jsonObjectEPS: Data?
//                                    do {
//                                        jsonObjectEPS = try JSONEncoder().encode([eps])
//                                    } catch(let error){
//                                        print(error)
//                                    }
//
//                                    storeImage(name: "\(eps.id)", urlString: eps.snapshot!, date: eps.frameTime!, camera: eps.cameraName!, label: eps.label!, endPointsData: jsonObjectEPS)
//
//                                    removeFromLiveView(type: eps.type!, id: eps.id! )
//                                }
//                        } else  {
//
//                            ViewEventUpdate(name: "\(eps.id!)", eps: eps)
//                                .onAppear(){
//                                    removeFromLiveView(type: eps.type!, id: eps.id!)
//                                }
//                        }
//                    }
//                }//end of first for each
//            } //end of scroll
 

//OPTION 2 - SwiftData
//        ScrollView {
//            ForEach(x, id: \.self) { eps in
//            //x.mutateEach { eps in
//                if eps.id != nil {
//                    if eps.type == "new" {
//                        Text("1=\(eps.id)")
//                        Spacer()
//                            .onAppear(){
//
//                                var jsonObjectEPS: Data?
//                                do {
//                                    jsonObjectEPS = try JSONEncoder().encode([eps])
//                                } catch(let error){
//                                    print(error)
//                                }
//                                storeImage(name: "\(eps.id)", urlString: eps.snapshot!, date: eps.frameTime!, camera: eps.cameraName!, label: eps.label!, endPointsData: jsonObjectEPS)
//                            }
//                    }
//                    else  {
//                        ViewEventUpdate(name: "\(eps.id!)", eps: eps)
//                    }
//                }
//            }
//            .onDisappear(){
//                print("onDisappear____________________________________________________________>")
//
//                var y: [EndpointOptions] = []
//                let tmp = EndpointOptions()
//                //y.append(tmp)
//
//                var yy: Data?
//                do {
//                    yy = try JSONEncoder().encode(y)
//                } catch(let error){
//                    print("ERROR MESSAGE 3------------------->", error)
//                }
//
//                //part 2
//                UserDefaults.standard.set(yy, forKey: "epsApnArray")
//            }
//        }













