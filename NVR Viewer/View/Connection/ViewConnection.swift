//
//  ViewConnection.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import SwiftUI

struct ViewConnection: View {
    
    let title: String
    @State var brokerAddress: String = "127.0.0.1"
    @State private var path = NavigationPath()
    @EnvironmentObject private var mqttManager: MQTTManager
    
    var body: some View {
        
        VStack {
            VStack(spacing: 50) {
                Button(action: initAndConnect) {
                    Label("Connect", systemImage: "cable.connector")
                }
                .disabled(mqttManager.isConnected())
                
                Button(action: disconnect ) {
                    Label("Disconnect", systemImage: "cable.connector.slash")
                }
                .disabled(!mqttManager.isConnected())
            }
            .padding()
            .onAppear(){
                print(mqttManager.currentAppState.appConnectionState)
            }
        }
        .containerRelativeFrame([.horizontal, .vertical])
        .background(mqttManager.isConnected() ? Color.green.opacity(0.2) : Color.pink.opacity(0.2))
        .navigationBarTitle(title, displayMode: .inline)
        .scrollContentBackground(.hidden) 
        .toolbarBackground(.primary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
     
    private func initAndConnect() {
        //mqttManager.initializeMQTT(host: brokerAddress, identifier: UUID().uuidString)
        //mqttManager.connect()
    }
    
    private func disconnect() {
        mqttManager.disconnect()
    }
}

#Preview {
    ViewConnection(title: "Connection Status")
        .environmentObject(MQTTManager.shared())
}
