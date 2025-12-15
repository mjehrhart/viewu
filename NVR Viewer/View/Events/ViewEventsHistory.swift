//
//  ViewEventsHistory.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/5/24.
//

import SwiftUI
import SwiftData

@MainActor
struct ViewEventsHistory: View {

    @AppStorage("authType") private var authType: AuthType = .none
    @AppStorage("developerModeIsOn") private var developerModeIsOn = false

    @ObservedObject private var epsSup3 = EndpointOptionsSuper.shared()
    @ObservedObject private var nvrManager = NVRConfig.shared()   // classic singleton

    var body: some View {
        VStack(spacing: 0) {
            List {
                //ForEach(epsSup3.list3, id: \.sid) { container in
                ForEach(epsSup3.list3, id: \.id) { container in
                    if let id = container.id,
                       !id.isEmpty,
                       container.frameTime != nil {

                        ViewEventCard(meta: container)
                            .listRowInsets(.init(top: 6, leading: 10, bottom: 0, trailing: 10))
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    HStack {
                        if developerModeIsOn {
                            Text(authType.description)
                                .font(.system(size: 20))
                                .fontWeight(.regular)
                                .foregroundColor(.gray)
                        }

                        Text("\(epsSup3.list3.count)")
                            .font(.system(size: 20))
                            .fontWeight(.regular)
                            .foregroundColor(.gray)

                        // Just an icon to show connection status
                        Label("", systemImage: "cable.connector")
                            .frame(alignment: .leading)
                            .foregroundStyle(
                                nvrManager.getConnectionState() ? .white : .red
                            )
                    }
                }
            }
            .task {
                // Initial load of events
                EventStorage.shared.readAll3 { res in
                    DispatchQueue.main.async {
                        epsSup3.list3 = res ?? []
                    }
                }
            }
            .listStyle(.plain)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 50)
            .padding(.zero)
        }
    }
}
