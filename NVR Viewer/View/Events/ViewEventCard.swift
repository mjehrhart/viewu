//
//  ViewEventCard.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/15/24.
//

import SwiftUI
struct ViewEventCard: View {
    
    @State private var scale = 1.0
    @State var containers: [EndpointOptions]
      
    @ObservedObject var epsSuper = EndpointOptionsSuper.shared()
    
    var developerModeIsOn: Bool = UserDefaults.standard.bool(forKey: "developerModeIsOn")
    
    let nvr = NVRConfig.shared()
    let api = APIRequester()
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
    func setHeight() -> CGFloat {
        
        //var height = UIScreen.screenHeight
        
        if idiom == .pad {
            return (setWidth() * 16/9)
        } else {
            return 166
        }
    }
    
    struct CustomPressEffectButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(8)
                .background(configuration.isPressed ? Color.gray : Color.orange.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        
        ForEach( 0..<containers.count, id: \.self){ index in
            
            VStack{
                
                // One event row
                HStack(alignment: .top, spacing: 12) {

                    // LEFT: time + meta
                    VStack(alignment: .leading, spacing: 4) {

                        // Time (NavigationLink)
                        NavigationLink(convertTime(time: containers[index].frameTime!), value: containers[index])
                            .font(.system(size: fontSizeDate, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 0.18, green: 0.18, blue: 0.18))
                            .padding(.top, 4)

                        // Date
                        Text(convertDate(time: containers[index].frameTime!))
                            .foregroundColor(.gray)
                            .font(.system(size: fontSizeLabel, weight: .regular))

                        // Label
                        Text("\(containers[index].label!)")
                            .font(.system(size: fontSizeLabel, weight: .regular))
                            .foregroundColor(.gray.opacity(0.9))

                        if developerModeIsOn {
                            Text("\(containers[index].score!)")
                                .font(.system(size: fontSizeLabel, weight: .regular))
                                .foregroundColor(.gray.opacity(0.9))
                        }
                        
                        if !(containers[index].sublabel ?? "").isEmpty {
                            Text(containers[index].sublabel!)
                                .font(.system(size: fontSizeLabel, weight: .thin))
                                .foregroundColor(.gray.opacity(0.8))
                        }

                        if developerModeIsOn {
                            Text(containers[index].type ?? "")
                                .font(.system(size: fontSizeLabel, weight: .thin))
                                .foregroundColor(.gray.opacity(0.8))
                        }

                        Spacer(minLength: 4)

                        // Optional Frigate+ button
                        if frigatePlusOn, !(containers[index].frigatePlus ?? false) {
                            Button {
                                Task {
                                    containers[index].frigatePlus?.toggle()

                                    let url = nvr.getUrl()
                                    let endpoint = "/api/events/\(containers[index].id!)/plus"

                                    await api.postImageToFrigatePlus(
                                        urlString: url,
                                        endpoint: endpoint,
                                        eventId: containers[index].id!,
                                        authType: nvr.getAuthType()
                                    ) { data, error in
                                        guard let data else { return }

                                        do {
                                            if let json = try JSONSerialization.jsonObject(
                                                with: data,
                                                options: .fragmentsAllowed
                                            ) as? [String: Any],
                                               let res = json["success"] as? Int {

                                                if res == 1 {
                                                    EventStorage.shared.updateFrigatePlus(id: containers[index].id!, value: true)
                                                    EventStorage.shared.readAll3 { res in
                                                        epsSuper.list3 = res ?? []
                                                    }
                                                } else if let msg = json["message"] as? String,
                                                          msg == "PLUS_API_KEY environment variable is not set" {
                                                    containers[index].frigatePlus?.toggle()
                                                    EventStorage.shared.updateFrigatePlus(id: containers[index].id!, value: false)
                                                }
                                            }
                                        } catch {
                                            Log.shared().print(page: "ViewEventCard", fn: "button", type: "ERROR", text: "\(error)")
                                        }
                                    }
                                }
                            } label: {
                                Text("Frigate+")
                                    .font(.system(size: 11, weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule().fill(Color.black.opacity(0.08))
                                    )
                            }
                            .buttonStyle(CustomPressEffectButtonStyle())
                            .tint(Color(white: 0.58))
                            .padding(.top, 4)
                            .padding(.bottom, 8)
                        }

                        if developerModeIsOn {
                            Text(containers[index].transportType ?? "")
                                .font(.system(size: fontSizeLabel, weight: .thin))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                    }
                    //.frame(width: setWidth(), height: setHeight(), alignment: .leading)
                    .frame(maxWidth: setWidth(), maxHeight: .infinity, alignment: .leading)

                    // RIGHT: snapshot image
                    ZStack(alignment: .topTrailing) {
                        ViewEventImage(
                            urlString: containers[index].snapshot!,
                            frameTime: containers[index].frameTime!,
                            frigatePlus: containers[index].frigatePlus!,
                            widthG: 302,
                            heightG: 180
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        // Optional chevron overlay on top-right of image
//                        Image(systemName: "chevron.right")
//                            .font(.system(size: 14, weight: .semibold))
//                            .foregroundStyle(Color.white.opacity(0.95))
//                            .padding(8)
//                            .background(
//                                Circle().fill(Color.black.opacity(0.35))
//                            )
//                            .padding(10)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading) 
                .background(
                    cardShape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(.secondarySystemBackground).opacity(0.46),  // 12/7/25 was .white
                                    Color(.secondarySystemBackground).opacity(0.96)  // 12/7/25 was .white
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    ZStack {
                        // Outer border
                        cardShape
                            .stroke(Color.black.opacity(0.05), lineWidth: 0.7) 
                        // Inner “glass” border  .background(Color(.secondarySystemBackground))
                        cardShape
                            .inset(by: 4)
                            //.stroke(Color.white.opacity(0.45), lineWidth: 0.6)
                            .stroke(Color(.secondarySystemBackground).opacity(0.45), lineWidth: 0.6)
                    }
                )
                .shadow(color: Color.gray.opacity(0.10), radius: 10, x: 0, y: 6)
                .contentShape(Rectangle())
                .padding(.horizontal, 2)
                .padding(.vertical, 3)

                VStack{
                    if developerModeIsOn {
                        ScrollView(.horizontal){
                            Text(containers[index].snapshot!)
                                .font(.system(size: fontSizeLabel))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .textSelection(.enabled)
                        }
                        .scrollIndicators(.hidden)
                    }
                } 
                .frame(maxWidth: .infinity, alignment: .bottomLeading)
            }
            .frame(maxHeight: .infinity)
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
