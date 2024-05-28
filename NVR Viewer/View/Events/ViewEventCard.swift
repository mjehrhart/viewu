//
//  ViewEventCard.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/15/24.
//

import SwiftUI
struct ViewEventCard: View {
    
    @State var containers: [EndpointOptions]
    @ObservedObject var epsSuper = EndpointOptionsSuper.shared()
    var developerModeIsOn: Bool = UserDefaults.standard.bool(forKey: "developerModeIsOn")
    
    //
    @State private var zoomIn: Bool = false
    
    init(frameTime: Double) {
        containers = EventStorage.shared.getEventByFrameTime(frameTime3: frameTime )
    }
    
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    func setWidth() -> CGFloat{
        
        if idiom == .pad {
            return 200
        } else {
            return 110
        }
    }
    
    var body: some View {
        ForEach(containers, id: \.self){ container in
            
            VStack{
                
                HStack{
                    VStack(alignment: .leading, spacing: 1) {
                        NavigationLink(convertTime(time: container.frameTime!), value: container)
                            .foregroundColor(.primary)
                            .font(.title3)
                        Text(convertDate(time: container.frameTime!))
                            .foregroundColor(.primary)
                            .font(.caption)
                        Text("\(container.label!)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        if(container.sublabel! != ""){
                            Text("\(container.sublabel!)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        
                        Text("\(container.type!)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        EnteredZones(zones: container.enteredZones!)
                         
                        Spacer()
                        
                        if developerModeIsOn {
                            Text(container.transportType!)
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .frame(width: setWidth(), alignment: .bottomLeading)
                        }
                        
                    }
                    .modifier(CardBackground())
                    .frame(width: setWidth(), alignment: .leading) //110
                    
                    ViewUIImage(urlString: container.snapshot!, frameTime: containers[0].frameTime! )
                        .modifier(CardBackground())
                }
                
                VStack{
                    if developerModeIsOn {
                        Text(container.snapshot!)
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }
                .frame(width: UIScreen.screenWidth-20, alignment: .bottomLeading)
            }
        }
        .onDelete{ indexes in
            let flag = EventStorage.shared.delete(frameTime: containers[0].frameTime!)
            if flag {
                EventStorage.shared.readAll3(completion: { res in
                    epsSuper.list3 = res!
                })
            }
        }
    }
    
    struct EnteredZones: View {
    
        let zones:String
        var enteredZones: Array<Substring>;
          
        init(zones: String) {
            self.zones = zones
            enteredZones = zones.split(separator: "|")
        }
         
        var body: some View {
            
            if !enteredZones.isEmpty {
                Text("Zones")
                    .font(.caption)
                ForEach(enteredZones, id: \.self) { zone in
                    Text(zone)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
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

#Preview {
    ViewEventCard(frameTime: 1710541384.496615)
        .modelContainer(for: ImageContainer.self)
}
