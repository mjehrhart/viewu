//
//  ViewEventsHistory.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/5/24.
//

import SwiftUI
import SwiftData

struct ViewEventsHistory: View {
    //
    @State var index = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let cNVR = APIRequester()
    
    @State var showViewEventDetail = false
    @ObservedObject var filter2 = EventFilter.shared()
    @ObservedObject var epsSuper = EndpointOptionsSuper.shared()
    @ObservedObject var epsSup3 = EndpointOptionsSuper.shared()
    @ObservedObject var nvrManager = NVRConfig.shared() //was stateobject
    
    @Environment(\.scenePhase) var scenePhase
     
    init() {
        
    }
    
    var body: some View {
        VStack{
            List {
                ForEach(epsSup3.list3, id: \.sid) { container in 
                    
                    if container.id! != "" {
                        ViewEventCard(frameTime: container.frameTime!) 
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    HStack{
                        Text("\(epsSup3.list3.count)")
                            //.font(.system(size: 16, weight: .medium, design: .default))
                            .font(.system(size: 20))
                            .fontWeight(.regular)
                            .foregroundColor(.gray)
                        Label(!nvrManager.getConnectionState() ? "" : "", systemImage: "cable.connector")
                            .frame(alignment: .leading)
                            .foregroundStyle(nvrManager.getConnectionState() ? .white : .red)
                    } 
                }
            }
            .task{
                EventStorage.shared.readAll3(completion: { res in
                    epsSup3.list3 = res!
                })
            }
            .listStyle(PlainListStyle())
            .listRowInsets(EdgeInsets.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 50)
            .padding(0)
        }
        //DEBGUGGIG ALL BELOW
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            //            print("======================================================================================================")
            //            print("opened! 1")
            //            print("======================================================================================================")
            //
            //            EventStorage.shared.readAll3(completion: { res in
            //                epsSup3.list3 = res!
            //            })
            //            print("ViewEventsHistory --- \(epsSup3.list3.count)")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            //            print("======================================================================================================")
            //            print("opened! 2")
            //            print("======================================================================================================")
            //
            //            EventStorage.shared.readAll3(completion: { res in
            //                epsSup3.list3 = res!
            //            })
            //            print("ViewEventsHistory --- \(epsSup3.list3.count)")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            //            print("======================================================================================================")
            //            print("opened! 3")
            //            print("======================================================================================================")
            //
            //            EventStorage.shared.readAll3(completion: { res in
            //                epsSup3.list3 = res!
            //            })
            //            print("ViewEventsHistory --- \(epsSup3.list3.count)")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            //            print("======================================================================================================")
            //            print("opened! 4") // lll
            //            print("======================================================================================================")
            //
            //            EventStorage.shared.readAll3(completion: { res in
            //                epsSup3.list3 = res!
            //            })
            //            print("ViewEventsHistory --- \(epsSup3.list3.count)")
            //            //EndpointOptionsSuper.shared().addBlank()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
            //            print("======================================================================================================")
            //            print("opened! 5") // ll
            //            print("======================================================================================================")
            //
            //            EventStorage.shared.readAll3(completion: { res in
            //                epsSup3.list3 = res!
            //            })
            //            print("ViewEventsHistory --- \(epsSup3.list3.count)")
        }
        .onChange(of: scenePhase) { _, newScenePhase in
            
        }
    }
    
    func testMe(object: Data?){
        print("Testme")
    }
    
    private func deserializeObject(object: Data?) ->  String{
        
        let jsonString = String(data: object!, encoding: .utf8)!
        return jsonString
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
}

//#Preview {
//    ViewEventsHistory()
//}


