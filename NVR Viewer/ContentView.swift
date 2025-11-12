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
import BackgroundTasks

struct ContentView: View {
    //Load Config
    @ObservedObject var filter2 = EventFilter.shared()
    let nvr = NVRConfig.shared()
    //Commented out for testing on 11/08/2025
    //@ObservedObject var config = NVRConfigurationSuper.shared()
    @ObservedObject var config = NVRConfigurationSuper2.shared()
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
    @State private var showNotificationManager = false
    
    @AppStorage("developerModeIsOn") var developerModeIsOn = true
    @AppStorage("notificationModeIsOn") var notificationModeIsOn = UserDefaults.standard.bool(forKey: "notificationModeIsOn")
    @AppStorage("frigateAlertsRetain")  var frigateAlertsRetain: Int = 10
    @AppStorage("frigateDetectionsRetain")  var frigateDetectionsRetain: Int = 10
    @AppStorage("frigateVersion")  var frigateVersion: String = "0.0-0"
    @AppStorage("background_fetch_events_epochtime") private var backgroundFetchEventsEpochtime: String = "0"
    @AppStorage("isOnboarding") var isOnboarding: Bool = true
    
    @Environment(\.scenePhase) var scenePhase
    
    @State private var path = NavigationPath()
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont(name: "Georgia-Bold", size: 20)!]
    }
    
    var body: some View{
        
        NavigationStack (path: $path) {
            VStack {
                
                ZStack {
                    GeometryReader { reader in
                        Color.secondary
                            .frame(height: reader.safeAreaInsets.top, alignment: .top)
                            .ignoresSafeArea()
                    }
                    
                    switch selection {
                    case 0:
                        
                        if isOnboarding {
                            ViewOnBoarding()
                            
                        } else {
                            ViewEventListHome()
                        }
                        
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
                print(urlString)
                cNVR.fetchNVRConfig(urlString: urlString ){ (data, error) in
                    
                    Log.shared().print(page: "ContentView", fn: "task::cnvr.fetchNVRConfig", type: "Info", text: "Entry")
                    
                    guard let data = data else { return }
                    
                    do {
                        //Commented out for Testing on 11/08/2025
                        //config.item = try JSONDecoder().decode(NVRConfigurationCall.self, from: data)
                        config.item = try JSONDecoder().decode(NVRConfigurationCall2.self, from: data)
                        
                        //                        if let dataJson = jsonObject.data(using: .utf8) {
                        //                            let epsArray = try! JSONDecoder().decode([EndpointOptions].self, from: dataJson)
                        //                            ViewEventInformation( endPointOptionsArray: epsArray)
                        //                        }
                        
                        //Commented out for Testing on 11/08/2025
                        filter2.setCameras(items: config.item.cameras)
                        filter2.setObject(items: config.item.cameras)
                        filter2.setZones(items: config.item.cameras)
                        
                        frigateVersion = config.item.version
                        frigateAlertsRetain = config.item.record.alerts.retain.days
                        frigateDetectionsRetain = config.item.record.detections.retain.days
                        
                        // Delete non-retained snapshots
                        for (_, value) in config.item.cameras{
                            
                            let daysBack = value.snapshots.retain.default
                            let db:Int = Int(daysBack)
                            let _ = EventStorage.shared.delete(daysBack:db, cameraName: value.name)
                        }
                        
                    }catch (let err){
                        print("Error Message goes here - 1001.b")
                        print(err)
                        Log.shared().print(page: "ContentView", fn: "task::cnvr.fetchNVRConfig 1001", type: "ERROR", text: "\(err)")
                        
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed ) as? [String: Any] {
                                
                                Log.shared().print(page: "ContentView", fn: "task::cnvr.fetchNVRConfig 2001", type: "Info", text: "\(json)")
                                //print(json)
                            }
                        } catch(let err) {
                            print("Error Message goes here - 2001")
                            print(err)
                            Log.shared().print(page: "ContentView", fn: "task::cnvr.fetchNVRConfig 2001", type: "ERROR", text: "\(err)")
                        }
                    }
                }
                
                //Load Events
                cNVR.fetchEventsInBackground(urlString: nvr.getUrl(), backgroundFetchEventsEpochtime: backgroundFetchEventsEpochtime, epsType: "ctask" )
            }
            .task {
                do{
                    //try? Tips.showAllTipsForTesting()
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                            .datastoreLocation(.applicationDefault)
                    ])
                } catch (let error){
                    Log.shared().print(page: "ContentView", fn: "task", type: "ERROR", text: "\(error)")
                    print("there was a tip error")
                }
            }
            .onReceive(notificationManager2.$newPage) {
                guard let notificationSelection = $0 else  { return }
                self.selection = notificationSelection
                
            }
            //DEBGUGGIG ALL BELOW
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                print("======================================================================================================")
                print("opened! 1")
                print("======================================================================================================")
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                print("======================================================================================================")
                print("opened! 2")
                print("======================================================================================================")
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                print("======================================================================================================")
                print("opened! 3")
                print("======================================================================================================")
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                print("======================================================================================================")
                print("opened! 4") // lll
                print("======================================================================================================")
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                print("======================================================================================================")
                print("opened! 5") // ll
                print("======================================================================================================")
            }
            .onChange(of: scenePhase) { _, newScenePhase in
                print(".onChange(of: scenePhase")
                
                if newScenePhase == .active {
                    print("Active")
                    cNVR.fetchEventsInBackground(urlString: nvr.getUrl(), backgroundFetchEventsEpochtime: backgroundFetchEventsEpochtime, epsType: "scenePhase")
                }
                else if newScenePhase == .inactive {
                    print("Inactive")
                } else if newScenePhase == .background {
                    print("Background")
                }
            }
            .onAppear{
                Task{
                    await sheduleBackgroundTask()
                }
                
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
                //ViewTest(title:"test")
                ViewLog()
            }
            .navigationDestination(isPresented: $showCamera){
                //HERE
                ViewCamera(title: "Live Cameras")
            }
            .navigationDestination(isPresented: $showNotificationManager){
                //ViewNotificationManager(title: "Notification Manager")
                ViewAPN(title: "Notification Manager")
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationDestination(for: Cameras.self){ config in
                
                ViewCameraDetails(text: "\(config.name.uppercased()) Camera Details", cameras: config)
            }
            .navigationDestination(for: Cameras2.self){ config in
                
                ViewCameraDetails2(text: "\(config.name.uppercased()) Camera Details", cameras: config)
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
                if !isOnboarding {
                    ToolbarItemGroup(placement: .bottomBar) {
                        
                        HStack{
                            Label("Filter", systemImage: "calendar.day.timeline.leading")
                                .labelStyle(VerticalLabelStyle(show: false))
                            //.foregroundStyle(.orange)
                                .foregroundStyle(Color(red: 0.45, green: 0.45, blue: 0.45))
                            //.foregroundStyle(showSettings ? .blue : .blue)
                            //.font(.system(size: 20))
                                .fontWeight(.regular)
                                .foregroundColor(.gray)
                                .onTapGesture(perform: {
                                    showFilter.toggle()
                                })
                            
                            Spacer()
                            
                            Label("Cameras", systemImage: "web.camera")
                                .labelStyle(VerticalLabelStyle(show: false))
                            //.foregroundStyle(.orange)
                                .foregroundStyle(Color(red: 0.45, green: 0.45, blue: 0.45))
                            //.foregroundStyle(showCamera ? .blue : .gray)
                            //.font(.system(size: 20))
                                .fontWeight(.regular)
                                .foregroundColor(.gray)
                                .onTapGesture(perform: {
                                    showCamera.toggle()
                                })
                            
                            if notificationModeIsOn {
                                Spacer()
                                Label("Notifications", systemImage: "app.badge")
                                    .labelStyle(VerticalLabelStyle(show: false))
                                //.foregroundStyle(.orange)
                                    .foregroundStyle(Color(red: 0.45, green: 0.45, blue: 0.45))
                                //.foregroundStyle(showNotificationManager ? .blue : .gray)
                                //.font(.system(size: 20))
                                    .fontWeight(.regular)
                                    .foregroundColor(.gray)
                                    .onTapGesture(perform: {
                                        showNotificationManager.toggle()
                                    })
                            }
                            
                            
                            
                            
                            
                            if developerModeIsOn {
                                Spacer()
                                Label("NVR", systemImage: "arrow.triangle.2.circlepath.circle")
                                    .labelStyle(VerticalLabelStyle(show: false))
                                //.foregroundStyle(.orange)
                                    .foregroundStyle(Color(red: 0.45, green: 0.45, blue: 0.45))
                                //.foregroundStyle(showNVR ? .blue : .gray)
                                    .fontWeight(.regular)
                                    .foregroundColor(.gray)
                                    .onTapGesture(perform: {
                                        //showNVR.toggle()
                                        notificationManager2.newPage = 2
                                        self.selection = 2
                                    })
                            }
                            
                            
                            
                            if developerModeIsOn {
                                Spacer()
                                Label("Log", systemImage: "note.text")
                                    .labelStyle(VerticalLabelStyle(show: false))
                                //.foregroundStyle(.orange)
                                    .foregroundStyle(Color(red: 0.45, green: 0.45, blue: 0.45))
                                //.foregroundStyle(showSettings ? .blue : .gray)
                                    .fontWeight(.regular)
                                    .foregroundColor(.gray)
                                    .onTapGesture(perform: {
                                        showLog.toggle()
                                    })
                            }
                            
                            Spacer()
                            
                            Label("Settings", systemImage: "gearshape")
                                .labelStyle(VerticalLabelStyle(show: false))
                            //.foregroundStyle(.orange)
                                .foregroundStyle(Color(red: 0.45, green: 0.45, blue: 0.45))
                            //.foregroundStyle(showSettings ? .blue : .gray)
                            //.font(.system(size: 20))
                                .fontWeight(.regular)
                                .foregroundColor(.gray)
                                .onTapGesture(perform: {
                                    showSettings.toggle()
                                })
                        }//hstack
                    }
                }
            }
        }
    }
    
    func sheduleBackgroundTask() async {
        
        let request = BGAppRefreshTaskRequest(identifier: "viewu_refresh")
        request.earliestBeginDate = Calendar.current.date(byAdding: .second, value: 30 * 60, to: Date())
        do {
            try BGTaskScheduler.shared.submit(request)
            print("DEBUG: Background Task Scheduled!")
        } catch(let error) {
            print("DEBUG: Scheduling Error \(error.localizedDescription)")
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
    
    var show: Bool
    
    init(show: Bool){
        self.show = show
    }
    
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
