//
//  ViewQuickDayFilter.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 11/10/25.
//
 
import SwiftUI

struct ViewQuickDayFilter: View {
 
    let fontSize: CGFloat = 25
    let dateSpacer: CGFloat = (UIScreen.screenWidth-0)/4
    var days = [String]()
    var daysEpoch = [Double]()
    
    @ObservedObject var filter2 = EventFilter.shared() 
    @ObservedObject var epsSuper = EndpointOptionsSuper.shared()
     
    @AppStorage("frigateAlertsRetain")  var frigateAlertsRetain: Int = 10
    @AppStorage("frigateDetectionsRetain")  var frigateDetectionsRetain: Int = 10
    var retain = 5
    
    @Environment(\.scenePhase) var scenePhase

    init() {
        if frigateAlertsRetain > frigateDetectionsRetain {
            retain = frigateAlertsRetain
        } else {
            retain = frigateAlertsRetain
        }

        let cal = Calendar.current
        var date = cal.startOfDay(for: Date())
        date = cal.date(byAdding: .day, value: -(retain-1), to: date)!
        
        for _ in 1 ... (retain) {
            let day = cal.component(.day, from: date)
            let month = cal.component(.month, from: date)
            days.append("\(month)/\(day)")
            daysEpoch.append(date.timeIntervalSince1970)
            date = cal.date(byAdding: .day, value: +1, to: date)!
        }
    }
     
    var body: some View {
        VStack{
            GeometryReader { metrics in
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.orange)
                                .frame(height: 1.5)
                                .frame(width: metrics.size.width * 0.85)
                                .cornerRadius(2.5)
                            
                            Spacer() // Pushes the bar to the left, adjust as needed
                        }
                        //.background(.yellow)
                        .frame(maxWidth: .infinity, maxHeight: 1.5) // Make HStack fill the GeometryReader
                    }
            
            ScrollView(.horizontal, showsIndicators: false){
                HStack(alignment: .center, spacing: 2) {
                    
                    ForEach(1..<days.count, id: \.self) { index in
                        Text(days[index])
                            .font(.system(size: fontSize))
                            .fontWeight(.light)
                            .foregroundColor(.gray)
                            .frame(width: dateSpacer, height: 20)
                            .onTapGesture {
                                
                                filter2.startDate = Date(timeIntervalSince1970: daysEpoch[index])
                                filter2.endDate = Date(timeIntervalSince1970: getDays(time: getDays(time: daysEpoch[index]) ))
                                
                                EventStorage.shared.readAll3(completion: { res in
                                    epsSuper.list3 = res!
                                })
                            }
                    }
                }
                .frame(maxWidth: .infinity , maxHeight: 20)
            }
            .padding(.bottom, 5)
            .defaultScrollAnchor(.trailing)
            //.padding(.horizontal, 10)
            .safeAreaPadding(.horizontal)
        }
        .frame(maxWidth: .infinity , maxHeight: 40)
        
    }
    
    private func getDays(time: Double) -> Double{
        
        let cal = Calendar.current
        var date = cal.startOfDay(for: Date(timeIntervalSince1970: time))
        date = cal.date(byAdding: .day, value: +0, to: date)!
         
        return date.timeIntervalSince1970
    }
    
//    private func convertDateTime(time: Double) -> String{
//        let date = Date(timeIntervalSince1970: time)
//        let dateFormatter = DateFormatter()
//        dateFormatter.timeStyle = DateFormatter.Style.short
//        dateFormatter.dateStyle = DateFormatter.Style.medium
//        dateFormatter.timeZone = .current
//        var localDate = dateFormatter.string(from: date)
//        localDate.replace("at", with: "")
//        return localDate
//    }
//    
//    private func convertDate(time: Double) -> String{
//        let date = Date(timeIntervalSince1970: time)
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MMM YYYY dd" // hh:mm a"
//        dateFormatter.timeStyle = DateFormatter.Style.none
//        dateFormatter.dateStyle = DateFormatter.Style.medium
//        dateFormatter.timeZone = .current
//        let localDate = dateFormatter.string(from: date)
//        return localDate
//    }
//    
//    private func convertTime(time: Double) -> String{
//        let date = Date(timeIntervalSince1970: time)
//        let dateFormatter = DateFormatter()
//        dateFormatter.timeStyle = DateFormatter.Style.short
//        dateFormatter.dateStyle = DateFormatter.Style.none
//        dateFormatter.timeZone = .current
//        let localDate = dateFormatter.string(from: date)
//        return localDate
//    }
}
