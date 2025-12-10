//
//  ViewFilter.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/20/24.
//

import SwiftUI

//
//  ViewFilter.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/20/24.
//

import SwiftUI

struct ViewFilter: View {

    @ObservedObject private var filter2 = EventFilter.shared()
    @ObservedObject private var epsSuper = EndpointOptionsSuper.shared()

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
                        selection: $filter2.selectedCamera,
                        options: filter2.cameras
                    )

                    FilterPickerRow(
                        systemImage: "figure.walk.motion",
                        tint: accentBlue,
                        title: "Object",
                        selection: $filter2.selectedObject,
                        options: filter2.objects
                    )

                    FilterPickerRow(
                        systemImage: "square.stack.3d.down.right.fill",
                        tint: accentBlue,
                        title: "Zones",
                        selection: $filter2.selectedZone,
                        options: filter2.zones
                    )

                    FilterPickerRow(
                        systemImage: "lineweight",
                        tint: accentBlue,
                        title: "Type",
                        selection: $filter2.selectedType,
                        options: filter2.types
                    )

                } header: {
                    Text("Filter")
                        .font(.largeTitle)
                }

                // MARK: - Date range section
                Section {
                    DatePicker(
                        "Start Date",
                        selection: $filter2.startDate,
                        in: ...Date.now,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)

                    DatePicker(
                        "End Date",
                        selection: $filter2.endDate,
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
                    filter2.reset()
                }
                .buttonStyle(CustomPressEffectButtonStyle())
                .frame(width: UIScreen.screenWidth - 50, alignment: .trailing)
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
        .onChange(of: filter2.startDate) { _, newStart in
            if newStart > filter2.endDate {
                filter2.endDate = newStart
            }
        }
        .onChange(of: filter2.endDate) { _, newEnd in
            if newEnd < filter2.startDate {
                filter2.startDate = newEnd
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

 

#Preview {
    ViewFilter()
}

// MARK: - Remove
/*
struct ViewFilter: View {
    
    @ObservedObject var filter2 = EventFilter.shared()
    @ObservedObject var epsSuper = EndpointOptionsSuper.shared()
    
    @State private var scale = 1.0
      
    
    init(){ }
    
    @State private var isPresented = false
    var body: some View {
        VStack{
            //Text("")
            Form{
                Section {
                    HStack{
                        Label("", systemImage: "web.camera")
                            .padding(0)
                            .foregroundStyle(Color(red: 0.153, green: 0.69, blue: 1))
                        Picker("Camera", selection: $filter2.selectedCamera) {
                            ForEach(filter2.cameras, id: \.self) {
                                Text($0)
                            }
                        }.pickerStyle( .menu )
                            .frame(minWidth: 100)
                            .padding(0)
                            .tint(Color(red: 0.153, green: 0.69, blue: 1))
                    }
                    
                    HStack{
                        Label("", systemImage: "figure.walk.motion")
                            .padding(0)
                            .foregroundStyle(Color(red: 0.153, green: 0.69, blue: 1))
                        Picker("Object", selection: $filter2.selectedObject) {
                            ForEach(filter2.objects, id: \.self) {
                                Text($0)
                            }
                        }.pickerStyle( .menu )
                            .frame(minWidth: 100)
                            .padding(0)
                            .tint(Color(red: 0.153, green: 0.69, blue: 1))
                    }
                    
                    HStack{
                        Label("", systemImage: "square.stack.3d.down.right.fill")
                            .padding(0)
                            .foregroundStyle(Color(red: 0.153, green: 0.69, blue: 1))
                        Picker("Zones", selection: $filter2.selectedZone) {
                            ForEach(filter2.zones, id: \.self) {
                                Text($0)
                            }
                        }.pickerStyle( .menu )
                            .frame(minWidth: 100)
                            .padding(0)
                            .tint(Color(red: 0.153, green: 0.69, blue: 1))
                    }
                    
                    HStack{
                        Label("", systemImage: "lineweight")
                            .padding(0)
                            .foregroundStyle(Color(red: 0.153, green: 0.69, blue: 1))
                        Picker("Type", selection: $filter2.selectedType) {
                            ForEach(filter2.types, id: \.self) {
                                Text($0)
                            }
                        }.pickerStyle( .menu )
                            .frame(minWidth: 100)
                            .padding(0)
                            .tint(Color(red: 0.153, green: 0.69, blue: 1))
                    }
 
                } header: {
                    Text("Filter")
                        .font(.largeTitle)
                }
                
                Section {
                    DatePicker(
                        "Start Date",
                        selection: $filter2.startDate,
                        in: ...Date.now,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    
                    DatePicker(
                        "End Date",
                        selection: $filter2.endDate,
                        in: ...Date.now,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                }  header: {
                    Text("Date Range")
                        .font(.largeTitle)
                }
                
                Button("Reset") {
                    filter2.reset() 
                }
                .buttonStyle(CustomPressEffectButtonStyle())
                .scaleEffect(scale)
                .animation(.linear(duration: 1), value: scale)
                .frame(width: UIScreen.screenWidth - 50, alignment: .trailing)
            }
        }
        .onDisappear(){
            //Triggers reload of data
            EventStorage.shared.readAll3(completion: { res in
                epsSuper.list3 = res!
            })
        }
    }
    
    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 2024, month: 1, day: 1)
        let endComponents = DateComponents(year: 2024, month: 03, day: 23)
        return calendar.date(from:startComponents)!
        ...
        calendar.date(from:endComponents)!
    }()
    
    struct CustomPressEffectButtonStyle: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .padding(8)
                    .background(configuration.isPressed ? Color.gray : Color.orange.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
}
 
 // MARK: - Button style

 struct CustomPressEffectButtonStyle: ButtonStyle {
     func makeBody(configuration: Configuration) -> some View {
         configuration.label
             .padding(8)
             .background(configuration.isPressed ? Color.gray : Color.orange.opacity(0.6))
             .foregroundColor(.white)
             .cornerRadius(10)
     }
 }
 
*/
