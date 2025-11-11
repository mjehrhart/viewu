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
    
    let nvr = NVRConfig.shared()
    let cNVR = APIRequester()
    let fontSizeDate: CGFloat = 20
    let fontSizeLabel: CGFloat = 13
    
    //
    @State private var zoomIn: Bool = false
    var frigatePlusOn: Bool = UserDefaults.standard.bool(forKey: "frigatePlusOn")
    
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
        //ForEach(containers, id: \.self){ container in
        ForEach( 0..<containers.count, id: \.self){ index in
            
            VStack{
                
                HStack{
                    //VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                 
                        //Time
                        NavigationLink(convertTime(time: containers[index].frameTime!), value: containers[index])
                            //.foregroundColor(.primary)
                            //.font(.title3)
                            .font(.system(size: fontSizeDate))
                            //.fontWeight(.thin)
                            //.foregroundColor(.gray)
                            .foregroundStyle(Color(red: 0.45, green: 0.45, blue: 0.45))
                            .frame(width: setWidth(), alignment: .topLeading)
                            .padding(.top,5)
                        
                        //Date
                        Text(convertDate(time: containers[index].frameTime!))
                            .foregroundColor(.gray)
                            //.font(.caption)
                            .font(.system(size: fontSizeLabel))
                            .fontWeight(.thin)
                        
                        //Label
                        Text("\(containers[index].label!)")
                            //.foregroundColor(.secondary)
                            //.font(.caption)
                            .font(.system(size: fontSizeLabel))
                            .fontWeight(.thin)
                            .foregroundColor(.gray)
                        
                        //Text("\(containers[index].score ?? 0)")
//                        Text("\()")
//                        Text("\()")
                        if(containers[index].sublabel! != ""){
                            Text("\(containers[index].sublabel!)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        
                        if developerModeIsOn {
                            Text("\(containers[index].type!)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        
                        //EnteredZones(zones: containers[index].enteredZones!)
                         
                        Spacer()
                         
                        if !containers[index].frigatePlus!{
                            if frigatePlusOn {
                                Button( action: {
                                    
                                    containers[index].frigatePlus!.toggle()
                                    
                                    let url = nvr.getUrl()
                                    let urlString = url + "/api/events/\(containers[index].id!)/plus"
                                    cNVR.postImageToFrigatePlus(urlString: urlString, eventId: containers[index].id! ){ (data, error) in
                                         
                                        guard let data = data else { return }
                                        
                                        do {
                                            if let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed ) as? [String: Any] {
                                                
                                                if let res = json["success"] as? Int {
                                                    print(res)
                                                    if res == 1 {
                                                         
                                                        EventStorage.shared.updateFrigatePlus(id: containers[index].id!, value: true)
                                                        EventStorage.shared.readAll3(completion: { res in
                                                            //self.epsSup3 = res!
                                                            epsSuper.list3 = res!
                                                            return
                                                        })
                                                    } else {
                                                        if let msg = json["message"] as? String {
                                                            print(msg)
                                                            
                                                            if (msg == "PLUS_API_KEY environment variable is not set" ){
                                                                containers[index].frigatePlus!.toggle()
                                                                EventStorage.shared.updateFrigatePlus(id: containers[index].id!, value: false)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        } catch(let error) {
                                            Log.shared().print(page: "ViewEventCard", fn: "button", type: "ERROR", text: "\(error)")
                                            print(error)
                                        }
                                    }
                                    return
                                } ){
                                    Text("Frigate+")
                                        .padding(1)
                                }
                                .buttonStyle(.borderedProminent)
//                                .tint(.gray).opacity(0.2)
//                                .foregroundColor(.white).opacity(1.0)
                                .font(.footnote)
                                .foregroundColor(.black)
                                .background(.gray).opacity(0.4)
                                .cornerRadius(4)
                                .padding(.bottom, 5)
                            }
                        }
                        
                        if developerModeIsOn {
                            Text(containers[index].transportType!)
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .frame(width: setWidth(), alignment: .bottomLeading)
                        }
                         
                    }
                    .frame(width: setWidth(), alignment: .leading) //110
                     
                    ViewUIImage(urlString: containers[index].snapshot!, frameTime: containers[index].frameTime!, frigatePlus: containers[index].frigatePlus! )
                        .modifier(CardBackground())
                }
                 
                VStack{
                    if developerModeIsOn {
                        Text(containers[index].snapshot!)
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }
                .frame(width: UIScreen.screenWidth-20, alignment: .bottomLeading)
            }
            //.background( container.frigatePlus! ? Color(.systemGreen).opacity(0.09) : Color.white)
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
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(enteredZones, id: \.self) { zone in
                        Text(zone)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
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
