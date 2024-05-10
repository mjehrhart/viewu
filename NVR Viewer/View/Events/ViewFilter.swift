//
//  ViewFilter.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/20/24.
//

import SwiftUI

struct ViewFilter: View {
    
    @ObservedObject var filter2 = EventFilter.shared()
    @ObservedObject var epsSuper = EndpointOptionsSuper.shared()
    
    @State private var scale = 1.0
      
    
    init(){
        //        _selectedCamera = State(initialValue: filter.selectedCamera)
        //        _selectedObject = State(initialValue: filter.selectedObject)
        //        _selectedDaysBack = State(initialValue: 1)
    }
    
    @State private var isPresented = false
    var body: some View {
        VStack{
            //Text("")
            Form{
                Section {
                    HStack{
                        Label("", systemImage: "web.camera")
                            .padding(0)
                        Picker("Camera", selection: $filter2.selectedCamera) {
                            ForEach(filter2.cameras, id: \.self) {
                                Text($0)
                            }
                        }.pickerStyle( .menu )
                            .frame(minWidth: 100)
                            .padding(0)
                    }
                    
                    HStack{
                        Label("", systemImage: "figure.walk.motion")
                            .padding(0)
                        Picker("Object", selection: $filter2.selectedObject) {
                            ForEach(filter2.objects, id: \.self) {
                                Text($0)
                            }
                        }.pickerStyle( .menu )
                            .frame(minWidth: 100)
                            .padding(0)
                    }
                    
//                    HStack{
//                        Label("", systemImage: "square.dashed")
//                            .padding(0)
//                        Picker("Zone", selection: $filter2.selectedZone) {
//                            ForEach(filter2.zones, id: \.self) {
//                                Text($0)
//                            }
//                        }.pickerStyle( .menu )
//                            .frame(minWidth: 100)
//                            .padding(0)
//                    }
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
                .buttonStyle(.bordered)
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
        //let endComponents = DateComponents(year: 2023, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        let endComponents = DateComponents(year: 2024, month: 03, day: 23)
        return calendar.date(from:startComponents)!
        ...
        calendar.date(from:endComponents)!
    }()
}

#Preview {
    ViewFilter()
}
 
