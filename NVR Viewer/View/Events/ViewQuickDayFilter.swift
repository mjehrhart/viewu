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
    //@ObservedObject var epsSup3 = EndpointOptionsSuper.shared() 
    @ObservedObject var epsSuper = EndpointOptionsSuper.shared()
    
    @Environment(\.scenePhase) var scenePhase

    init() {
        print("ViewQuickDayFilter init")

        let cal = Calendar.current
        var date = cal.startOfDay(for: Date())
        date = cal.date(byAdding: .day, value: -6, to: date)!
        
        for _ in 1 ... 7 {
            let day = cal.component(.day, from: date)
            let month = cal.component(.month, from: date)
            days.append("\(month)/\(day)")
            daysEpoch.append(date.timeIntervalSince1970)
            date = cal.date(byAdding: .day, value: +1, to: date)!
        }
    }
    
 
    
    var body: some View {
        ScrollView(.horizontal){
            HStack(alignment: .center, spacing: 2) {
                
                ForEach(0..<days.count) { index in
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
            .frame(width: .infinity, height: 40)
        }
        .defaultScrollAnchor(.trailing) 
    }
    
    private func getDays(time: Double) -> Double{
        
        let cal = Calendar.current
        var date = cal.startOfDay(for: Date(timeIntervalSince1970: time))
        date = cal.date(byAdding: .day, value: +0, to: date)!
         
        return date.timeIntervalSince1970
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
