//
//  ContentView.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import SwiftUI
import CocoaMQTT
import SwiftData
import TipKit

struct ContentView: View {
    //Load Config
    @ObservedObject var filter2 = EventFilter.shared()
    let nvr = NVRConfig.shared()
    @ObservedObject var config = NVRConfigurationSuper.shared()
    let cNVR = APIRequester()
    
    //
    @EnvironmentObject private var notificationManager2: NotificationManager
    @State var selection: Int = 0
    
    @StateObject var mqttManager = MQTTManager.shared()
    @StateObject var nvrManager = NVRConfig.shared()
    @StateObject var notificationManager = NotificationManager() //this may not be needed here
    
    @State private var showFilter = false
    @State public var Connection:Bool = false
    @State private var showEventList = false
    @State private var showCamera = false
    @State private var showSettings = false
    @State private var showConnection = false
    @State private var showNVR = false
    @State private var showLog = false
    @State private var developerModeIsOn: Bool = UserDefaults.standard.bool(forKey: "developerModeIsOn")
     
    @State private var path = NavigationPath()
    //@State private var path: NavigationPath = .init()
    
    init() {
        //UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont(name: "Georgia-Bold", size: 20)!]
    }
    
    var body: some View{
        
        NavigationStack (path: $path) { //(path: $path)
            VStack {
 
                //ViewNVRDetails()
                //ViewEventListHome()
                 
                ZStack {
                    GeometryReader { reader in
                        Color.white
                                .frame(height: reader.safeAreaInsets.top, alignment: .top)
                                .ignoresSafeArea()
                        }
                    
                    switch selection {
                    case 0:
                        ViewEventListHome()
                    case 1:
                        //ViewLive(text: convertDateTime(time: notificationManager2.frameTime!), container: notificationManager2.eps!, showButton: false)
                        ViewEventDetail(text: convertDateTime(time: notificationManager2.frameTime!), container: notificationManager2.eps!, showButton: true, showClip: false)
                    case 2:
                        ViewNVRDetails()
                            .transition(.move(edge: .trailing))
                            .animation(Animation.default)
                    default:
                        ViewEventListHome()
                    }
                }
            }
            .task(){
                
                //Load Defaults for app
                let url = nvr.getUrl()
                let urlString = url + "/api/config"
                
                cNVR.fetchNVRConfig(urlString: urlString ){ (data, error) in
 
                    guard let data = data else { return }
                    
                    do {
                        config.item = try JSONDecoder().decode(NVRConfigurationCall.self, from: data)
                         
                        filter2.setCameras(items: config.item.cameras)
                        filter2.setObject(items: config.item.cameras)
                        filter2.setZones(items: config.item.cameras)
                        
                        // Delete non-retained snapshots
                        for (name, value) in config.item.cameras{
         
                            let daysBack = value.snapshots.retain.default
                            var db:Int = Int(daysBack)
                            let cont = EventStorage.shared.delete(daysBack:db, cameraName: value.name)
                        }
                         
                    }catch (let err){
                        print("Error Message goes here - 1001")
                        print(err)
                    }
                } 
                
                
                //DEV
                //Load Events
                let urlEvents = nvr.getUrl()
                let urlStringEvents = url + "/api/events?limit=10000"
                cNVR.fetchNVREvents(urlString: urlStringEvents) { data, error in
                    
                    guard let data = data else { return }
                    
                    print(data)
                    do{
                        let arrayEvents = try JSONDecoder().decode([NVRConfigurationHTTP].self, from: data)
                        //print(arrayEvents)
                        
                        for event in arrayEvents {
                            
                            //print(event)
                            let url = nvr.getUrl()
                            let id = event.id   
                            let frameTime = event.start_time
                            
                            var enteredZones = ""
                            for zone in event.zones! {
                                enteredZones += zone + "|"
                            }
                             
                            var eps = EndpointOptions()
                            eps.snapshot = url + "/api/events/\(id)/snapshot.jpg?bbox=1"
                            eps.cameraName = event.camera
                            eps.m3u8 = url + "/vod/event/\(id)/master.m3u8"
                            eps.frameTime = event.start_time
                            eps.label = event.label
                            eps.id = event.id
                            eps.thumbnail = url + "/api/events/\(id)/thumbnail.jpg"
                            eps.camera = url + "/cameras/\(event.camera)"
                            eps.debug = url + "/api/\(event.camera)?h=480"
                            eps.image = url + "/api/\(event.camera)/recordings/\(frameTime)/snapshot.png"
                            eps.score = 0.0
                            eps.transportType = "http"
                            eps.type = "web"
                            eps.currentZones = ""
                            eps.enteredZones = enteredZones
                            eps.sublabel = event.sub_label
                             
                            //Check if value is nil
                            if eps.sublabel == nil {
                                eps.sublabel = ""
                            }
                            if eps.currentZones == nil {
                            }
                            if eps.enteredZones == nil {
                                eps.enteredZones = ""
                            } 
                            
                            let _ = EventStorage.shared.insertIfNone(
                                  id: eps.id!,
                                  frameTime: eps.frameTime!,
                                  score: eps.score!,
                                  type: eps.type!,
                                  cameraName: eps.cameraName!,
                                  label: eps.label!,
                                  thumbnail: eps.thumbnail!,
                                  snapshot: eps.snapshot!,
                                  m3u8: eps.m3u8!,
                                  camera: eps.camera!,
                                  debug: eps.debug!,
                                  image: eps.image!,
                                  transportType: eps.transportType!,
                                  subLabel: eps.sublabel!, //ADDED 5/26 ?? "" TODO !
                                  currentZones: eps.currentZones!,
                                  enteredZones: eps.enteredZones!
                            )
                            
                        }
                    } catch(let err) {
                        print("Error Message goes here - 1002")
                        print(err)
                    }
                    
                    
                }
            }
            .task {
                do{
                    try? Tips.showAllTipsForTesting()
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                        .datastoreLocation(.applicationDefault)
                    ])
                } catch{
                    print("there was a tip error")
                }
            }
            .onReceive(notificationManager2.$newPage) {
                guard let notificationSelection = $0 else  { return }
                self.selection = notificationSelection
                
            }
            .onAppear{
                //check accesibilty to nvr
                nvrManager.checkConnectionStatus(){data,error in
                    //do nothing
                }
                
                //TODO check if connection is disconnected first
                //connect to mqtt broker
                mqttManager.initializeMQTT()
                mqttManager.connect()
            }
            .environmentObject(mqttManager)
            .environmentObject(nvrManager)
            .scrollContentBackground(.hidden)
            .navigationBarBackButtonHidden()
            .navigationDestination(isPresented: $showEventList){
                ViewEventListHome()
            }
            .navigationDestination(isPresented: $showNVR){
                ViewNVRDetails() 
            }
            .navigationDestination(isPresented: $showSettings){
                ViewSettings(title: "Settings")
                    .environmentObject(nvrManager)
                    .environmentObject(mqttManager)
            }
            .navigationDestination(isPresented: $showConnection){
                ViewConnection(title: "Connection")
                    .environmentObject(nvrManager)
                    .environmentObject(mqttManager)
            }
            .navigationDestination(isPresented: $showLog){
                ViewTest(title:"test")
            }
            .navigationDestination(isPresented: $showCamera){
                ViewCamera(title: "Live Cameras")
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationDestination(for: Cameras.self){ config in 
                
                ViewCameraDetails(text: "\(config.name.uppercased()) Camera Details", cameras: config)
            }
            .navigationDestination(for: EndpointOptions.self){ eps in
                
                ViewEventDetail(text: convertDateTime(time: eps.frameTime!), container: eps, showButton: false, showClip: true)
            }
            .navigationDestination(for: String.self){ jsonObject in
          
                if let dataJson = jsonObject.data(using: .utf8) {
                    let epsArray = try! JSONDecoder().decode([EndpointOptions].self, from: dataJson)
                    ViewEventInformation( endPointOptionsArray: epsArray)
                }
            } 
            .navigationDestination(for: Int.self){ page in
                ViewTest(title: "cow")
            }
            .sheet(isPresented: $showFilter) {
                ViewFilter()
                    .presentationDetents([.large])
            }
            //added this 5/9
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) { 
                    Label("Filter", systemImage: "calendar.day.timeline.leading")
                        .labelStyle(VerticalLabelStyle())
                        .onTapGesture(perform: {
                            showFilter.toggle()
                        })
                        .foregroundStyle(showSettings ? .blue : .blue)
                    Spacer()
                    Label("Cameras", systemImage: "web.camera")
                        .labelStyle(VerticalLabelStyle())
                        .onTapGesture(perform: {
                            showCamera.toggle()
                        })
                        .foregroundStyle(showCamera ? .blue : .gray)
                    Spacer()
                    //NavigationLink(destination: ViewNVRDetails()){
                        Label("NVR", systemImage: "arrow.triangle.2.circlepath.circle")
                            .labelStyle(VerticalLabelStyle())
                            .onTapGesture(perform: {
                                //showNVR.toggle()
                                notificationManager2.newPage = 2
                                self.selection = 2
                            })
                            .foregroundStyle(showNVR ? .blue : .gray)
                    //}
                    Spacer()
                    Label("Settings", systemImage: "gearshape")
                        .labelStyle(VerticalLabelStyle())
                        .onTapGesture(perform: {
                            showSettings.toggle()
                        })
                        .foregroundStyle(showSettings ? .blue : .gray)
                    
//                    if developerModeIsOn {
//                        Spacer()
//                        Label("Log", systemImage: "note.text")
//                            .labelStyle(VerticalLabelStyle())
//                            .onTapGesture(perform: {
//                                showLog.toggle()
//                            })
//                            .foregroundStyle(showSettings ? .blue : .gray)
//                    }
                }
            } 
        }
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

struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon.font(.system(size: 18))
            configuration.title.font(.system(size: 10))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MQTTManager.shared())
            .environmentObject(NVRConfig.shared())
    }
}

extension AnyTransition {
    static var moveAndFade: AnyTransition {
        AnyTransition.slide
    }
}
