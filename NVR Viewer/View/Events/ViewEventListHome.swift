//
//  ViewEventList.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import SwiftUI
import SwiftData

struct ViewEventListHome: View {
    @ObservedObject var filter2 = EventFilter.shared()
    
    @State private var showingCredits = false
    @State private var isPresented = false
    
    @StateObject var mqttManager = MQTTManager.shared()
    @StateObject var nvrManager = NVRConfig.shared()
    
    //Background Tasks
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) var context
     
    init(){
    }
    
    var body: some View {
        VStack {
            ViewEventList(title: "Event Timeline") 
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
              
            if newPhase == .active {
                print("Active")
            } else if newPhase == .inactive {
                print("Inactive")
            } else if newPhase == .background {
                print("Background")
            }
        }
        .navigationBarTitle("Event Timeline", displayMode: .inline)
        .environmentObject(mqttManager)
        .environmentObject(nvrManager)
    }
    
    struct ViewEventList: View {
         
        let title: String
        @State private var showEventList = true
        @State private var showCamera = false
        @State private var showSettings = false
        @State private var showConnection = false
        //
        @State var topic: String = "frigate/events"
        @State var message: String = ""
        //
        @EnvironmentObject private var mqttManager: MQTTManager
        @EnvironmentObject private var nvrManager: NVRConfig
 
        var body: some View {
        //
       /*--------------------------------------------------------------------------------------*/
            
            VStack {
                //Layout 1
                //ViewLiveEvent()
                
                //History 
                ViewEventsHistory()
                
                ViewTest(title:"test")
                    .frame(height: 30)
                    //.background(.yellow)
                    .padding(.vertical, 5)
            }
        }
        
        /*--------------------------------------------------------------------------------------*/
        
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
        
        private func subscribe(topic: String) {
            print("private subscribe2", topic)
            mqttManager.subscribe(topic: topic)
        }
        
        private func usubscribe() {
            mqttManager.unSubscribeFromCurrentTopic()
        }
        
        private func send(message: String) {
            mqttManager.publish(topic: topic, with: message)
            //clear message after sending
            //self.message = ""
        }
        
        private func titleForSubscribButtonFrom(state: MQTTAppConnectionState) -> String {
            switch state {
            case .connected, .connectedUnSubscribed, .disconnected, .connecting:
                return "Subscribe"
            case .connectedSubscribed:
                return "Unsubscribe"
            }
        }
        
        private func functionFor(state: MQTTAppConnectionState) -> () -> Void {
            switch state {
            case .connected, .connectedUnSubscribed, .disconnected, .connecting:
                return { subscribe(topic: topic) }
            case .connectedSubscribed:
                return { usubscribe() }
            }
        }
    }
    
    #Preview {
        ViewEventList(title: "Frigate Events")
    }
    
    struct MessageHistoryTextView: UIViewRepresentable {
        @Binding var text: String
        
        func makeUIView(context: Context) -> UITextView {
            let textView = UITextView()
            
            textView.autocapitalizationType = .sentences
            textView.isSelectable = true
            textView.isUserInteractionEnabled = false
            textView.font = UIFont.systemFont(ofSize: 14.0)
            
            return textView
        }
        
        func updateUIView(_ uiView: UITextView, context: Context) {
            uiView.text = text
            let myRange = NSMakeRange(uiView.text.count - 1, 0)
            uiView.scrollRangeToVisible(myRange)
        }
    }
    
    struct MQTTTextField: View {
        var placeHolderMessage: String
        var isDisabled: Bool
        @Binding var message: String
        var body: some View {
            TextField(placeHolderMessage, text: $message)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.5 : 1.0)
        }
    }
}
