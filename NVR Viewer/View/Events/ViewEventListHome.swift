//
//  ViewEventList.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//
 
import SwiftUI

@MainActor
struct ViewEventListHome: View {

    // Background Tasks (currently just a hook)
    @Environment(\.scenePhase) private var scenePhase

    init() {}

    var body: some View {
        VStack {
            ViewEventList(title: "Event Timeline")
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Hook for future behavior if needed
            switch newPhase {
            case .active:
                // App became active
                break
            case .inactive:
                // App is transitioning
                break
            case .background:
                // App moved to background
                break
            @unknown default:
                break
            }
        }
        .navigationTitle("Event Timeline")
        .navigationBarTitleDisplayMode(.inline)
    }

    struct ViewEventList: View {

        let title: String

        var body: some View {
            VStack {
                // History timeline
                ViewEventsHistory()

                // Quick date filter toolbar
                ViewQuickDayFilter()
            }
        }
    }
}

// MARK: - Remove
/*
import SwiftUI
import SwiftData

struct ViewEventListHome: View {
    
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
                //print("Active")
            } else if newPhase == .inactive {
                //print("Inactive")
            } else if newPhase == .background {
                //print("Background")
            }
        }
        .navigationBarTitle("Event Timeline", displayMode: .inline)
        .environmentObject(mqttManager)
        .environmentObject(nvrManager)
    }
    
    struct ViewEventList: View {
        
        let title: String
        @EnvironmentObject private var mqttManager: MQTTManager
        @EnvironmentObject private var nvrManager: NVRConfig
        
        var body: some View {
            
            VStack {
                //Layout 1
                //ViewLiveEvent() //oboslete
                
                //History
                ViewEventsHistory()
                
                //Quick Date Filter
                ViewQuickDayFilter()
            }
        }
    }
}
*/
