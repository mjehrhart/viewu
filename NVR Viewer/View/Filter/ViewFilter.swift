//
//  ViewFilter.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/20/24.
//

import SwiftUI

struct ViewFilter: View {

    //@ObservedObject private var filter2 = EventFilter.shared()
    @ObservedObject private var epsSuper = EndpointOptionsSuper.shared()
    @StateObject private var filter = EventFilter.shared()
    
    // You can tweak this accent if you ever want to centralize it
    private let accentBlue = Color(red: 0.153, green: 0.69, blue: 1)

    init() {}

    var body: some View {
        VStack {
            Form {
                // MARK: - Filter section
                Section {
                    FilterPickerRow(
                        systemImage: "web.camera",
                        tint: accentBlue,
                        title: "Camera",
                        selection: $filter.selectedCamera,
                        options: filter.cameras
                    )

                    FilterPickerRow(
                        systemImage: "figure.walk.motion",
                        tint: accentBlue,
                        title: "Object",
                        selection: $filter.selectedObject,
                        options: filter.objects
                    )

                    FilterPickerRow(
                        systemImage: "square.stack.3d.down.right.fill",
                        tint: accentBlue,
                        title: "Zones",
                        selection: $filter.selectedZone,
                        options: filter.zones
                    )

                    FilterPickerRow(
                        systemImage: "lineweight",
                        tint: accentBlue,
                        title: "Type",
                        selection: $filter.selectedType,
                        options: filter.types
                    )

                } header: {
                    Text("Filter")
                        .font(.largeTitle)
                }

                // MARK: - Date range section
                Section {
                    DatePicker(
                        "Start Date",
                        selection: $filter.startDate,
                        in: ...Date.now,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)

                    DatePicker(
                        "End Date",
                        selection: $filter.endDate,
                        in: ...Date.now,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)

                } header: {
                    Text("Date Range")
                        .font(.largeTitle)
                }

                // MARK: - Reset
                Button("Reset") {
                    filter.reset() 
                }
                .buttonStyle(CustomPressEffectButtonStyle())
                .frame(width: UIScreen.screenWidth - 50, alignment: .trailing)
                
                Section {
                    Toggle("Keep Filters Persistent", isOn: $filter.persistPickerValues)
                        .tint(accentBlue)

                    Text("Date range always resets when the app opens")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onDisappear {
            // Trigger reload of data when filter sheet closes
            EventStorage.shared.readAll3 { res in
                guard let res = res else {
                    DispatchQueue.main.async {
                        epsSuper.list3 = []
                    }
                    return
                }

                DispatchQueue.main.async {
                    epsSuper.list3 = res
                }
            }
        }
        // Optional nice-to-have: keep start <= end
        .onChange(of: filter.startDate) { _, newStart in
            if newStart > filter.endDate {
                filter.endDate = newStart
            }
        }
        .onChange(of: filter.endDate) { _, newEnd in
            if newEnd < filter.startDate {
                filter.startDate = newEnd
            }
        }
    }
}

// MARK: - Reusable picker row

private struct FilterPickerRow: View {
    let systemImage: String
    let tint: Color
    let title: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        HStack {
            Label("", systemImage: systemImage)
                .foregroundStyle(tint)

            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option)
                }
            }
            .pickerStyle(.menu)
            .frame(minWidth: 100)
            .tint(tint)
        }
    }
}

 

//#Preview {
//    ViewFilter()
//}
