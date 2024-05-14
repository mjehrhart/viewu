//
//  EventStorage.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/22/24.
//

import Foundation
import SQLite
import SwiftUI


class EventStorage: ObservableObject {
     
    @ObservedObject var filter2 = EventFilter.shared()
    @ObservedObject var epsSuper = EndpointOptionsSuper.shared() {
        willSet {
            objectWillChange.send()
        }
    }
    
    @Published var epsSup = EndpointOptionsSuper.shared().list2 {
        willSet {
            objectWillChange.send()
        }
    }
    @Published var epsSup3 = EndpointOptionsSuper.shared().list3 {
        willSet {
            objectWillChange.send()
        }
    }
    
    static let DIR_DB = "EventStorageDB"
    static let STORE_NAME = "event.sqlite3"

    private let events = Table("events")
 
    private let thumbnail = Expression<String>("thumbnail")
    private let snapshot = Expression<String>("snapshot")
    private let m3u8 = Expression<String>("m3u8")
    private let camera = Expression<String>("camera")
    private let debug = Expression<String>("debug")
    private let image = Expression<String>("image")
    private let sid = Expression<Int64>("sid")
    private let id = Expression<String>("id")
    private let frameTime = Expression<Double>("frameTime")
    private let score = Expression<Double>("score")
    private let type = Expression<String>("type")
    private let cameraName = Expression<String>("cameraName")
    private let label = Expression<String>("label")
    private let transportType = Expression<String>("transportType")
      
    static let shared = EventStorage()

    private var db: Connection? = nil

    private init() {
        if let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dirPath = docDir.appendingPathComponent(Self.DIR_DB)

            do {
                try FileManager.default.createDirectory(atPath: dirPath.path, withIntermediateDirectories: true, attributes: nil)
                let dbPath = dirPath.appendingPathComponent(Self.STORE_NAME).path
                db = try Connection(dbPath)
                
                createEventsTable()
                print("SQLiteDataStore init successfully at: \(dbPath) ")
            } catch {
                db = nil
                print("SQLiteDataStore init error: \(error)")
            }
        } else {
            db = nil
        }
    }
    
    func delete(daysBack: Int, cameraName: String) -> Bool {
 
        guard let database = db else {
            return false
        }
         
        do {
             
            if let date = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) {
           
                let d = floor(date.timeIntervalSince1970)
                 
                let filter = events.filter(self.frameTime < d &&
                                           self.cameraName == cameraName)
                 
                try database.run(filter.delete())
                
                return true
            }
             
            return false
        } catch {
            print(error)
            return false
        }
    }
    
    func delete(frameTime: Double) -> Bool {
        
        guard let database = db else {
            return false
        }
        do {
            let filter = events.filter(self.frameTime == frameTime)
            try database.run(filter.delete())
             
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    func delete() -> Bool {
        
        guard let database = db else {
            return false
        }
        do {
            let filter = events.filter(self.id != "-1")
            try database.run(filter.delete())
            return true
        } catch {
            print(error)
            return false
        }
    }
     
    func getEventByFrameTime(frameTime3: Double) -> [EndpointOptions] {
        
        var eps: EndpointOptions = EndpointOptions(thumbnail: "", snapshot: "", m3u8: "", camera: "", debug: "", image: "", id: "", type: "", cameraName: "", score: 0.0, frameTime: 0.0, label: "", transportType: "")
        
        guard let database = db else { return [] }

        let filter = self.events.filter( frameTime3 == frameTime)
        do {
            for events in try database.prepare(filter) {
                eps.thumbnail = events[thumbnail]
                eps.snapshot = events[snapshot]
                eps.m3u8 = events[m3u8]
                eps.camera = events[camera]
                eps.debug = events[debug]
                eps.image = events[image]
                eps.id = events[id]
                eps.type = events[type]
                eps.cameraName = events[cameraName]
                eps.score = events[score]
                eps.frameTime = events[frameTime]
                eps.label = events[label]
                eps.transportType = events[transportType]
            }
        } catch {
            print(error)
        }
        return [eps]
    }
    
    func getEventById(id3: String) -> [EndpointOptions] {
        
        var eps: [EndpointOptions] = []
        guard let database = db else { return [] }
        
        do {
            let filter = self.events.filter( id3 == id).order(frameTime.desc)
            
            for events in try database.prepare(filter) { //self.events
                
                eps.append( EndpointOptions(thumbnail: events[thumbnail],
                                            snapshot: events[snapshot],
                                            m3u8: events[m3u8],
                                            camera: events[camera],
                                            debug: events[debug],
                                            image: events[image],
                                            id: events[id],
                                            type: events[type],
                                            cameraName: events[cameraName],
                                            score: events[score],
                                            frameTime: events[frameTime],
                                            label: events[label],
                                            transportType: events[transportType]
                                           ) )
            }
        } catch {
            print(error)
        }
       
        return eps
    }
    
    func readAll3(completion: @escaping ([EndpointOptionsSuper.EventMeta3]?) -> Void) {
    
        //CLEAR epsSup3
        epsSup3.removeAll()
         
        var eps3: [EndpointOptionsSuper.EventMeta3] = []
        guard let database = db else { return  }

        do {
            var filter = Table("events")
 
            //TODO
            //Breifly wrote this. seems to work but needs further testing
            let startDate4 = Calendar.current.date(byAdding: DateComponents(day: -1), to: filter2.startDate) ?? Date()
            let startDate3 = Calendar.current.nextDate(after: startDate4, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTimePreservingSmallerComponents)!
            
            //Maybe below works, needs futher testing
//            let timezoneOffset =  TimeZone.current.secondsFromGMT()
//            let epochDate = startDate3.timeIntervalSince1970
//            let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
//            let timeZoneOffsetDate = Date(timeIntervalSince1970: timezoneEpochOffset)
//            print()
//            print("Date Time")
//            print("timeZoneOffsetDate",timeZoneOffsetDate.timeIntervalSince1970 )
//            print("start",timeZoneOffsetDate)
            
            var startDate = startDate3.timeIntervalSince1970
            //var startDate = timeZoneOffsetDate.timeIntervalSince1970
   
            let endDate2 = Calendar.current.nextDate(after: filter2.endDate, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTimePreservingSmallerComponents)!
            //print("end", endDate2)
            var endDate = endDate2.timeIntervalSince1970
            print(Date(timeIntervalSince1970: endDate))
            
            if filter2.selectedCamera == "all" && filter2.selectedObject == "all"{
                 
                filter = self.events.filter(type == "new" &&
                                            frameTime >= startDate &&
                                            frameTime <= endDate
                                            ).order(frameTime.desc)
                 
                //print(filter)
            } else if filter2.selectedCamera == "all" && filter2.selectedObject != "all"{
                
                filter = self.events.filter(type == "new" &&
                                            label == filter2.selectedObject &&
                                            frameTime >= startDate &&
                                            frameTime <= endDate
                                            ).order(frameTime.desc)
                //print(filter)
            } else if filter2.selectedCamera != "all" && filter2.selectedObject == "all"{
                 
                filter = self.events.filter(type == "new" &&
                                            cameraName == filter2.selectedCamera &&
                                            frameTime >= startDate &&
                                            frameTime <= endDate
                                            ).order(frameTime.desc)
                //print(filter)
            } else if filter2.selectedCamera != "all" && filter2.selectedObject != "all"{
                 
                filter = self.events.filter(type == "new" &&
                                            cameraName == filter2.selectedCamera &&
                                            label == filter2.selectedObject &&
                                            frameTime >= startDate &&
                                            frameTime <= endDate
                                            ).order(frameTime.desc)
                //print(filter)
            }
             
            for events in try database.prepare(filter) {
                    
                let x = EndpointOptionsSuper.EventMeta3()
                x.thumbnail = events[thumbnail]
                x.snapshot = events[snapshot]
                x.m3u8 = events[m3u8]
                x.camera = events[camera]
                x.debug = events[debug]
                x.image = events[image]
                x.id = events[id]
                x.type = events[type]
                x.cameraName = events[cameraName]
                x.score = events[score]
                x.frameTime = events[frameTime]
                x.label = events[label]
                x.transportType = events[transportType]
                
                eps3.append( x )
                 
            }
        } catch {
            print(error)
        }
         
        //TODO
        epsSup3 = eps3
        print("3count::\(epsSup3.count)")
        
        completion(eps3)
        //return eps3
    }
    
    func readAll2() -> [EndpointOptionsSuper.EventMeta] {
    
        var eps: [EndpointOptionsSuper.EventMeta] = []
         
        guard let database = db else { return [] }

        do {
            var filter = Table("events")
            var startDate = filter2.startDate.timeIntervalSince1970
            //print(startDate)
            startDate = floor(startDate)
            //print(startDate)
            
            var endDate = filter2.endDate.timeIntervalSince1970
            //print(endDate)
            endDate = ceil(endDate)
            //print(endDate)
            
            if filter2.selectedCamera == "all" && filter2.selectedObject == "all"{
                 
                filter = self.events.filter(type == "new" //&&
                                            //frameTime >= startDate &&
                                            //frameTime <= endDate
                                            ).order(frameTime.desc)
                 
                //print(filter)
            } else if filter2.selectedCamera == "all" && filter2.selectedObject != "all"{
                
                filter = self.events.filter(type == "new" &&
                                            label == filter2.selectedObject //&&
                                            //frameTime >= startDate &&
                                            //frameTime <= endDate
                                            ).order(frameTime.desc)
                
            } else if filter2.selectedCamera != "all" && filter2.selectedObject == "all"{
                 
                filter = self.events.filter(type == "new" &&
                                            cameraName == filter2.selectedCamera //&&
                                            //frameTime >= startDate &&
                                            //frameTime <= endDate
                                            ).order(frameTime.desc)
            } else if filter2.selectedCamera != "all" && filter2.selectedObject != "all"{
                 
                filter = self.events.filter(type == "new" &&
                                            cameraName == filter2.selectedCamera &&
                                            label == filter2.selectedObject //&&
                                            //frameTime >= startDate &&
                                            //frameTime <= endDate
                                            ).order(frameTime.desc)
            }
             
            for events in try database.prepare(filter) {
                   
                eps.append( EndpointOptionsSuper.EventMeta(thumbnail: events[thumbnail],
                                            snapshot: events[snapshot],
                                            m3u8: events[m3u8],
                                            camera: events[camera],
                                            debug: events[debug],
                                            image: events[image],
                                            id: events[id],
                                            type: events[type],
                                            cameraName: events[cameraName],
                                            score: events[score],
                                            frameTime: events[frameTime],
                                            label: events[label],
                                            transportType: events[transportType]
                                           ) )
             
                 
            }
        } catch {
            print(error)
        }
        
        //DispatchQueue.main.async { [self] in
            //epsSuper.list2 = eps
            //print("done reading eps from readall2")
        //}
        
        //TODO
        print("------////////----------count::\(eps.count)")
        epsSup = eps  
        return eps
    }
    
    func readAll() -> [EndpointOptions] {
    
        var eps: [EndpointOptions] = []
        guard let database = db else { return [] }

        do {
            let filter = self.events.filter(type == "new").order(frameTime.desc)
            
            for events in try database.prepare(filter) { //self.events
                 
                eps.append( EndpointOptions(thumbnail: events[thumbnail],
                                            snapshot: events[snapshot],
                                            m3u8: events[m3u8],
                                            camera: events[camera],
                                            debug: events[debug],
                                            image: events[image],
                                            id: events[id],
                                            type: events[type],
                                            cameraName: events[cameraName],
                                            score: events[score],
                                            frameTime: events[frameTime],
                                            label: events[label],
                                            transportType: events[transportType]
                                           ) )
            }
        } catch {
            print(error)
        }
        return eps
    }
     
    func insertIfNone(id: String, frameTime: Double, score: Double, type: String, cameraName: String, label: String, thumbnail: String, snapshot: String, m3u8: String, camera: String, debug: String, image: String, transportType: String ) {
          
        print("insertIfNone()======================================================>")
        //TODO is this needed DispatchQueue.main.async
        DispatchQueue.main.async { [self] in
             
            let dataset = self.getEventByFrameTime(frameTime3: frameTime)
             
            if dataset[0].thumbnail == "" {
                guard let database = db else { return }
                
                let insert = events.insert(self.id <- id,
                                           self.frameTime <- frameTime,
                                           self.score <- score,
                                           self.type <- type,
                                           self.cameraName <- cameraName,
                                           self.label <- label,
                                           self.thumbnail <- thumbnail,
                                           self.snapshot <- snapshot,
                                           self.m3u8 <- m3u8,
                                           self.camera <- camera,
                                           self.debug <- debug,
                                           self.image <- image,
                                           self.transportType <- transportType
                )
                do {
                    let rowID = try database.run(insert)
                    if rowID > -1 {
                        EventStorage.shared.readAll3(completion: { res in
                            self.epsSup3 = res!
                            self.epsSuper.list3 = res! 
                            return
                        })
                        print("Records Inserted: Is this before or after")
                    }
                     
                    print("Insert rowID::", rowID)
                    
                    //return
                } catch {
                    print("No records inserted with Error")
                    print(error)
                    return
                }
            } else { 
                print("No records inserted")
                return
            }
        }
    }
     
    
    func insert(id: String, frameTime: Double, score: Double, type: String, cameraName: String, label: String, thumbnail: String, snapshot: String, m3u8: String, camera: String, debug: String, image: String, transportType: String ) -> Int64? {
        
        guard let database = db else { return nil }

        let insert = events.insert(self.id <- id,
                                  self.frameTime <- frameTime,
                                  self.score <- score,
                                  self.type <- type,
                                  self.cameraName <- cameraName,
                                  self.label <- label,
                                  self.thumbnail <- thumbnail,
                                  self.snapshot <- snapshot,
                                  self.m3u8 <- m3u8,
                                  self.camera <- camera,
                                  self.debug <- debug,
                                  self.image <- image,
                                  self.transportType <- transportType
        )
        do {
            let rowID = try database.run(insert)
            
            //TODO
            EventStorage.shared.readAll3(completion: { res in
                self.epsSup3 = res!
                return
            })
              
            return rowID
        } catch {
            print(error)
            return nil
        }
    }
 
    private func createEventsTable() {
        guard let database = db else {
            return
        }
        do {
            try database.run(events.create { table in
                table.column(sid, primaryKey: .autoincrement)
                table.column(id)
                table.column(frameTime)
                table.column(score)
                table.column(type)
                table.column(cameraName)
                table.column(label)
                table.column(thumbnail)
                table.column(snapshot)
                table.column(m3u8)
                table.column(camera)
                table.column(debug)
                table.column(image)
                table.column(transportType)
            })
            
        } catch {
            print(error)
        }
    }
}
