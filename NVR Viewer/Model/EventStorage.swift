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
     
    @Published var epsSup3 = EndpointOptionsSuper.shared().list3
    
    static let DIR_DB = "EventStorageDB"
    static let STORE_NAME = "event.sqlite3"

    private let events = Table("events")
 
    private let thumbnail = Expression<String>("thumbnail")
    private let snapshot = Expression<String>("snapshot")
    private let m3u8 = Expression<String>("m3u8")
    private let mp4 = Expression<String>("mp4")
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
    
    private let sub_label = Expression<String>("subLabel")
    private let current_zones = Expression<String>("currentZones")
    private let entered_zones = Expression<String>("enteredZones")
    private let frigtePlus = Expression<Bool>("frigtePlus")
      
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
            } catch {
                db = nil
                Log.error(page: "EventStorage",
                                   fn: "init", "SQLiteDataStore init error: \(error)")
                
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
        } catch(let error) {
            Log.error(page: "EventStorage", fn: "delete",  "\(error)")
            return false
        }
    }
    
    //TODO this may need to change to ID 5/29
    func delete(frameTime: Double) -> Bool {
        
        guard let database = db else {
            return false
        }
        do {
            let filter = events.filter(self.frameTime == frameTime)
            try database.run(filter.delete())
             
            return true
        } catch (let error){
            Log.error(page: "EventStorage", fn: "delete", "\(error)")
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
        } catch (let error){
            Log.error(page: "EventStorage", fn: "delete", "\(error)")
            return false
        }
    }
     
    func getEventByFrameTime(frameTime3: Double) -> [EndpointOptions] {
        
        var eps: EndpointOptions = EndpointOptions(thumbnail: "", snapshot: "", m3u8: "", mp4: "", camera: "", debug: "", image: "", id: "", type: "", cameraName: "", score: 0.0, frameTime: 0.0, label: "", sublabel: "", currentZones: "", enteredZones: "", transportType: "")
        
        guard let database = db else { return [] }

        let filter = self.events.filter( frameTime3 == frameTime)
        do {
            for events in try database.prepare(filter) {
                eps.thumbnail = events[thumbnail]
                eps.snapshot = events[snapshot]
                eps.m3u8 = events[m3u8]
                eps.mp4 = events[mp4]
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
                eps.sublabel = events[sub_label]            // 5/26
                eps.currentZones = events[current_zones]
                eps.enteredZones = events[entered_zones]
                eps.sid = events[sid]
                eps.frigatePlus = events[frigtePlus]
                
            }
        } catch(let error) {
            Log.error(page: "EventStorage", fn: "getEventByFrameTime", "\(error)")
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
                    mp4: events[mp4],
                    camera: events[camera],
                    debug: events[debug],
                    image: events[image],
                    id: events[id],
                    type: events[type],
                    cameraName: events[cameraName],
                    score: events[score],
                    frameTime: events[frameTime],
                    label: events[label],
                    sublabel: events[sub_label], // ADDED THIS 5/26
                    currentZones: events[current_zones],
                    enteredZones: events[entered_zones],
                    transportType: events[transportType],
                    sid: events[sid]
                   ) )
            }
        } catch(let error) {
            Log.error(page: "EventStorage", fn: "getEventById", "\(error)")
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
 
            let startDate = startDate3.timeIntervalSince1970
   
            let endDate2 = Calendar.current.nextDate(after: filter2.endDate, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTimePreservingSmallerComponents)!
 
            let endDate = endDate2.timeIntervalSince1970
             
            if filter2.selectedCamera == "all" && filter2.selectedObject == "all" && filter2.selectedType == "all" && filter2.selectedZone == "all" {
                  
                filter = self.events.filter(
                    frameTime >= startDate &&
                    frameTime <= endDate
                    ).order(frameTime.desc)
                
            } else if filter2.selectedCamera == "all" && filter2.selectedObject == "all" && filter2.selectedType == "all" && filter2.selectedZone != "all" {
                
                filter = self.events.filter(
                    frameTime >= startDate &&
                    frameTime <= endDate &&
                    entered_zones .like("%"+filter2.selectedZone+"%")
                    ).order(frameTime.desc)
                
            }
            
            //******// 1
            else if filter2.selectedCamera == "all" && filter2.selectedObject == "all" && filter2.selectedType != "all" && filter2.selectedZone == "all" {
                
                filter = self.events.filter(
                    type == filter2.selectedType &&
                    frameTime >= startDate &&
                    frameTime <= endDate
                    ).order(frameTime.desc)
                
            } else if filter2.selectedCamera == "all" && filter2.selectedObject != "all" && filter2.selectedType == "all" && filter2.selectedZone == "all" {
                
                filter = self.events.filter(
                    label == filter2.selectedObject &&
                    frameTime >= startDate &&
                    frameTime <= endDate
                    ).order(frameTime.desc)
                
            } else if filter2.selectedCamera != "all" && filter2.selectedObject == "all" && filter2.selectedType == "all" && filter2.selectedZone == "all" {
                 
                filter = self.events.filter(
                    cameraName == filter2.selectedCamera &&
                    frameTime >= startDate &&
                    frameTime <= endDate
                    ).order(frameTime.desc)
                
            } else if filter2.selectedCamera == "all" && filter2.selectedObject != "all" && filter2.selectedType != "all" && filter2.selectedZone == "all" {
                
                filter = self.events.filter(
                    type == filter2.selectedType &&
                    label == filter2.selectedObject &&
                    frameTime >= startDate &&
                    frameTime <= endDate
                    ).order(frameTime.desc)
                
            } else if filter2.selectedCamera != "all" && filter2.selectedObject == "all" && filter2.selectedType != "all" && filter2.selectedZone == "all" {
                 
                filter = self.events.filter(
                    type == filter2.selectedType &&
                    cameraName == filter2.selectedCamera &&
                    frameTime >= startDate &&
                    frameTime <= endDate
                    ).order(frameTime.desc)
                
            } else if filter2.selectedCamera != "all" && filter2.selectedObject != "all" && filter2.selectedType != "all" && filter2.selectedZone == "all" {
                
                filter = self.events.filter(
                    type == filter2.selectedType &&
                    cameraName == filter2.selectedCamera &&
                    label == filter2.selectedObject &&
                    frameTime >= startDate &&
                    frameTime <= endDate
                    ).order(frameTime.desc)
                
            }
            
            //******// 2
            else if filter2.selectedCamera == "all" && filter2.selectedObject == "all" && filter2.selectedType != "all" && filter2.selectedZone != "all" {
                
                filter = self.events.filter(
                    type == filter2.selectedType &&
                    frameTime >= startDate &&
                    frameTime <= endDate &&
                    entered_zones .like("%"+filter2.selectedZone+"%")
                    ).order(frameTime.desc)
                
            } else if filter2.selectedCamera == "all" && filter2.selectedObject != "all" && filter2.selectedType == "all" && filter2.selectedZone != "all" {
                
                filter = self.events.filter(
                    label == filter2.selectedObject &&
                    frameTime >= startDate &&
                    frameTime <= endDate &&
                    entered_zones .like("%"+filter2.selectedZone+"%")
                    ).order(frameTime.desc)
                
            } else if filter2.selectedCamera != "all" && filter2.selectedObject == "all" && filter2.selectedType == "all" && filter2.selectedZone != "all" {
                 
                filter = self.events.filter(
                    cameraName == filter2.selectedCamera &&
                    frameTime >= startDate &&
                    frameTime <= endDate &&
                    entered_zones .like("%"+filter2.selectedZone+"%")
                    ).order(frameTime.desc)
                
            } else if filter2.selectedCamera == "all" && filter2.selectedObject != "all" && filter2.selectedType != "all" && filter2.selectedZone != "all" {
                
                filter = self.events.filter(
                    type == filter2.selectedType &&
                    label == filter2.selectedObject &&
                    frameTime >= startDate &&
                    frameTime <= endDate &&
                    entered_zones .like("%"+filter2.selectedZone+"%")
                    ).order(frameTime.desc)
                
            } else if filter2.selectedCamera != "all" && filter2.selectedObject == "all" && filter2.selectedType != "all" && filter2.selectedZone != "all" {
                 
                filter = self.events.filter(
                    type == filter2.selectedType &&
                    cameraName == filter2.selectedCamera &&
                    frameTime >= startDate &&
                    frameTime <= endDate &&
                    entered_zones .like("%"+filter2.selectedZone+"%")
                    ).order(frameTime.desc)
                
            }
            
            //******// 3
            else if filter2.selectedCamera != "all" && filter2.selectedObject != "all" && filter2.selectedType != "all" && filter2.selectedZone == "all"{
                
                filter = self.events.filter(
                    type == filter2.selectedType &&
                    cameraName == filter2.selectedCamera &&
                    label == filter2.selectedObject &&
                    frameTime >= startDate &&
                    frameTime <= endDate
                    ).order(frameTime.desc)
                
            }  else if filter2.selectedCamera != "all" && filter2.selectedObject != "all" && filter2.selectedType != "all" && filter2.selectedZone != "all" {
                
                filter = self.events.filter(
                    type == filter2.selectedType &&
                    cameraName == filter2.selectedCamera &&
                    label == filter2.selectedObject &&
                    frameTime >= startDate &&
                    frameTime <= endDate &&
                    entered_zones .like("%"+filter2.selectedZone+"%")
                    ).order(frameTime.desc)
            } else if filter2.selectedCamera != "all" && filter2.selectedObject != "all" && filter2.selectedType == "all" && filter2.selectedZone == "all" {
 
                filter = self.events.filter(
                    cameraName == filter2.selectedCamera &&
                    label == filter2.selectedObject &&
                    frameTime >= startDate &&
                    frameTime <= endDate
                    ).order(frameTime.desc)
 
            }
             
            for events in try database.prepare(filter) {
                    
                let x = EndpointOptionsSuper.EventMeta3()
                x.sid = events[sid]  //5/26
                x.thumbnail = events[thumbnail]
                x.snapshot = events[snapshot]
                x.m3u8 = events[m3u8]
                x.mp4 = events[mp4]
                x.camera = events[camera]
                x.debug = events[debug]
                x.image = events[image]
                x.id = events[id]
                x.type = events[type]
                x.cameraName = events[cameraName]
                x.score = events[score]
                x.frameTime = events[frameTime]
                x.label = events[label]
                x.sublabel = events[sub_label] // ADDED THIS 5/26
                x.currentZones = events[current_zones]
                x.enteredZones = events[entered_zones]
                x.transportType = events[transportType]
                x.frigatePlus = events[frigtePlus]
                
                //Fprint(x.frigatePlus!)
                
                eps3.append( x )
                 
            }
        } catch (let error){
            Log.error(page: "EventStorage", fn: "readAll3", "\(error)")
        }
          
        //TODO
        epsSup3 = eps3
        
        completion(eps3)
        //return eps3
    }
    
    //TODO check this logic, something is off here
    func updateFrigatePlus(id: String, value: Bool) {
        guard let database = db else {
            Log.error(
                page: "EventStorage",
                fn: "updateFrigatePlus",
                "Database not initialized"
            )
            return
        }

        do {
            // NOTE: your column is spelled "frigtePlus"
            let filter = events.filter(self.id == id)
            let update = filter.update(self.frigtePlus <- value)

            let updatedCount = try database.run(update)

            if updatedCount > 0 {
                // ✅ Patch in-memory list3 instead of reloading everything
                DispatchQueue.main.async {
                    let epsSuper = EndpointOptionsSuper.shared()

                    if let index = epsSuper.list3.firstIndex(where: { $0.id == id }) {
                        epsSuper.list3[index].frigatePlus = value
                    } else {
                        Log.warning(
                            page: "EventStorage",
                            fn: "updateFrigatePlus",
                            "DB updated but list3 does not contain id \(id)"
                        )
                    }
                }

                Log.debug(
                    page: "EventStorage",
                    fn: "updateFrigatePlus",
                    "Updated frigtePlus=\(value) for id \(id)"
                )
            } else {
                Log.warning(
                    page: "EventStorage",
                    fn: "updateFrigatePlus",
                    "No rows updated for id \(id)"
                )
            }

        } catch {
            Log.error(
                page: "EventStorage",
                fn: "updateFrigatePlus",
                "Failed to update frigtePlus for id \(id): \(error.localizedDescription)"
            )
        }
    }

//    func updateFrigatePlus(id: String, value: Bool){
//        //TODO is this needed DispatchQueue.main.async
//        DispatchQueue.main.async { [self] in
//            
//            guard let database = db else { return }
//              
//            let filter = events.filter(self.id == id)
//            
//            let update = filter.update(
//                self.frigtePlus <- value
//            )
//             
//            do {
//                let rowID = try database.run(update)
//                if rowID > -1 {
//                    EventStorage.shared.readAll3(completion: { res in
//                        self.epsSup3 = res!
//                        self.epsSuper.list3 = res!
//                        return
//                    })
//                }
//                  
//            } catch (let error){
//                Log.error(page: "EventStorage", fn: "updateFrigatePlus", "\(error)")
//                return
//            }
//            
//        }
//    }
    
    // EventStorage.swift
    func insertOrUpdate(
        id: String,
        frameTime: Double,
        score: Double,
        type: String,
        cameraName: String,
        label: String,
        thumbnail: String,
        snapshot: String,
        m3u8: String,
        mp4: String,
        camera: String,
        debug: String,
        image: String,
        transportType: String,
        subLabel: String,
        currentZones: String,
        enteredZones: String
    ) {
        guard let database = db else {
            Log.error(
                page: "EventStorage",
                fn: "insertOrUpdate",
                "Database not initialized"
            )
            return
        }

        do {
            // 1) Try UPDATE first
            let filter = events.filter(self.id == id)

            let update = filter.update(
                self.frameTime      <- frameTime,
                self.score          <- score,
                self.type           <- type,
                self.cameraName     <- cameraName,
                self.label          <- label,
                self.thumbnail      <- thumbnail,
                self.snapshot       <- snapshot,
                self.m3u8           <- m3u8,
                self.mp4            <- mp4,
                self.camera         <- camera,
                self.debug          <- debug,
                self.image          <- image,
                self.transportType  <- transportType,
                self.sub_label      <- subLabel,
                self.current_zones  <- currentZones,
                self.entered_zones  <- enteredZones
            )

            let updatedCount = try database.run(update)

            if updatedCount == 0 {
                // 2) No existing row → INSERT
                let insert = events.insert(
                    self.id            <- id,
                    self.frameTime     <- frameTime,
                    self.score         <- score,
                    self.type          <- type,
                    self.cameraName    <- cameraName,
                    self.label         <- label,
                    self.thumbnail     <- thumbnail,
                    self.snapshot      <- snapshot,
                    self.m3u8          <- m3u8,
                    self.mp4           <- mp4,
                    self.camera        <- camera,
                    self.debug         <- debug,
                    self.image         <- image,
                    self.transportType <- transportType,
                    self.sub_label     <- subLabel,
                    self.current_zones <- currentZones,
                    self.entered_zones <- enteredZones
                )

                _ = try database.run(insert)

                Log.debug(
                    page: "EventStorage",
                    fn: "insertOrUpdate",
                    "Inserted event id=\(id)"
                )
            } else {
                Log.debug(
                    page: "EventStorage",
                    fn: "insertOrUpdate",
                    "Updated event id=\(id)"
                )
            }

            // 3) Incremental in-memory sync (no readAll3)
            upsertInMemoryEvent3(
                id: id,
                frameTime: frameTime,
                score: score,
                type: type,
                cameraName: cameraName,
                label: label,
                thumbnail: thumbnail,
                snapshot: snapshot,
                m3u8: m3u8,
                mp4: mp4,
                camera: camera,
                debug: debug,
                image: image,
                transportType: transportType,
                subLabel: subLabel,
                currentZones: currentZones,
                enteredZones: enteredZones
            )

        } catch {
            Log.error(
                page: "EventStorage",
                fn: "insertOrUpdate",
                "SQLite error in insertOrUpdate for id \(id): \(error.localizedDescription)"
            )
        }
    }


    // MARK: - In-memory upsert for EndpointOptionsSuper.list3
    // MARK: - In-memory upsert for EndpointOptionsSuper.list3

    private func upsertInMemoryEvent3(
        id: String,
        frameTime: Double,
        score: Double,
        type: String,
        cameraName: String,
        label: String,
        thumbnail: String,
        snapshot: String,
        m3u8: String,
        mp4: String,
        camera: String,
        debug: String,
        image: String,
        transportType: String,
        subLabel: String,
        currentZones: String,
        enteredZones: String
    ) {
        // Stay on main thread because UI observes EndpointOptionsSuper / epsSup3
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.upsertInMemoryEvent3(
                    id: id,
                    frameTime: frameTime,
                    score: score,
                    type: type,
                    cameraName: cameraName,
                    label: label,
                    thumbnail: thumbnail,
                    snapshot: snapshot,
                    m3u8: m3u8,
                    mp4: mp4,
                    camera: camera,
                    debug: debug,
                    image: image,
                    transportType: transportType,
                    subLabel: subLabel,
                    currentZones: currentZones,
                    enteredZones: enteredZones
                )
            }
            return
        }

        let store = EndpointOptionsSuper.shared()

        if let index = store.list3.firstIndex(where: { $0.id == id }) {
            // ✅ Update existing meta in place
            let meta = store.list3[index]
            meta.frameTime     = frameTime
            meta.score         = score
            meta.type          = type
            meta.cameraName    = cameraName
            meta.label         = label
            meta.thumbnail     = thumbnail
            meta.snapshot      = snapshot
            meta.m3u8          = m3u8
            meta.mp4           = mp4
            meta.camera        = camera
            meta.debug         = debug
            meta.image         = image
            meta.transportType = transportType
            meta.sublabel      = subLabel
            meta.currentZones  = currentZones
            meta.enteredZones  = enteredZones
        } else {
            // ✅ New meta object
            let meta = EndpointOptionsSuper.EventMeta3()
            meta.id            = id
            meta.frameTime     = frameTime
            meta.score         = score
            meta.type          = type
            meta.cameraName    = cameraName
            meta.label         = label
            meta.thumbnail     = thumbnail
            meta.snapshot      = snapshot
            meta.m3u8          = m3u8
            meta.mp4           = mp4
            meta.camera        = camera
            meta.debug         = debug
            meta.image         = image
            meta.transportType = transportType
            meta.sublabel      = subLabel
            meta.currentZones  = currentZones
            meta.enteredZones  = enteredZones
            // frigatePlus defaults to false from DB; ok to leave as default

            // Insert in descending frameTime order (same as readAll3)
            let insertIndex = store.list3.firstIndex {
                ($0.frameTime ?? 0) < frameTime
            } ?? store.list3.endIndex

            store.list3.insert(meta, at: insertIndex)
        }

        // Keep EventStorage's own published copy in sync (if anything is observing it)
        epsSup3 = store.list3
    }



    
//    func insertOrUpdate(id: String, frameTime: Double, score: Double, type: String, cameraName: String, label: String, thumbnail: String, snapshot: String, m3u8: String, mp4: String, camera: String, debug: String, image: String, transportType: String, subLabel: String, currentZones: String, enteredZones: String  ) {
//           
//        //TODO is this needed DispatchQueue.main.async
//        DispatchQueue.main.async { [self] in
//             
//            //let dataset = self.getEventByFrameTime(frameTime3: frameTime)
//            let dataset = self.getEventById(id3: id)
//           
//            if dataset.isEmpty {
//                guard let database = db else { return }
//                 
//                let insert = events.insert(
//                   self.id <- id,
//                   self.frameTime <- frameTime,
//                   self.score <- score,
//                   self.type <- type,
//                   self.cameraName <- cameraName,
//                   self.label <- label,
//                   self.thumbnail <- thumbnail,
//                   self.snapshot <- snapshot,
//                   self.m3u8 <- m3u8,
//                   self.mp4 <- mp4,
//                   self.camera <- camera,
//                   self.debug <- debug,
//                   self.image <- image,
//                   self.transportType <- transportType,
//                   self.sub_label <- subLabel,                  //5/26
//                   self.current_zones <- currentZones,
//                   self.entered_zones <- enteredZones
//                )
//                do {
//                    let rowID = try database.run(insert)
//                    if rowID > -1 {
//                        EventStorage.shared.readAll3(completion: { res in
//                            self.epsSup3 = res!
//                            self.epsSuper.list3 = res!
//                            return
//                        })
//                    }
//                      
//                } catch (let error){
//                    Log.error(page: "EventStorage", fn: "insertOrUpdate", "\(error)")
//                    return
//                }
//            } else {
//               
//                guard let database = db else { return }
//                  
//                let filter = events.filter(self.id == id)
//                
//                let update = filter.update(
//                   self.id <- id,
//                   self.frameTime <- frameTime,
//                   self.score <- score,
//                   self.type <- type,
//                   self.cameraName <- cameraName,
//                   self.label <- label,
//                   self.thumbnail <- thumbnail,
//                   self.snapshot <- snapshot,
//                   self.m3u8 <- m3u8,
//                   self.mp4 <- mp4,
//                   self.camera <- camera,
//                   self.debug <- debug,
//                   self.image <- image,
//                   self.transportType <- transportType,
//                   self.sub_label <- subLabel,                  //5/26
//                   self.current_zones <- currentZones,
//                   self.entered_zones <- enteredZones
//                )
//                do {
//                     
//                    let rowID = try database.run(update)
//                    if rowID > -1 {
//                        EventStorage.shared.readAll3(completion: { res in
//                            self.epsSup3 = res!
//                            self.epsSuper.list3 = res!
//                            return
//                        })
//                    }
//                      
//                } catch (let error){
//                    Log.error(page: "EventStorage", fn: "insertOrUpdate", "\(error)")
//                    return
//                }
//            }
//        }
//    }
    
    func insertIfNone(
        id: String,
        frameTime: Double,
        score: Double,
        type: String,
        cameraName: String,
        label: String,
        thumbnail: String,
        snapshot: String,
        m3u8: String,
        mp4: String,
        camera: String,
        debug: String,
        image: String,
        transportType: String,
        subLabel: String,
        currentZones: String,
        enteredZones: String
    ) {
        guard let database = db else {
            Log.error(
                page: "EventStorage",
                fn: "insertIfNone",
                "Database not initialized"
            )
            return
        }

        do {
            // Fast existence check on id
            let filter = events.filter(self.id == id)
            if try database.pluck(filter) != nil {
                Log.debug(
                    page: "EventStorage",
                    fn: "insertIfNone",
                    "Event id=\(id) already exists; skipping insert"
                )
                return
            }

            let insert = events.insert(
                self.id            <- id,
                self.frameTime     <- frameTime,
                self.score         <- score,
                self.type          <- type,
                self.cameraName    <- cameraName,
                self.label         <- label,
                self.thumbnail     <- thumbnail,
                self.snapshot      <- snapshot,
                self.m3u8          <- m3u8,
                self.mp4           <- mp4,
                self.camera        <- camera,
                self.debug         <- debug,
                self.image         <- image,
                self.transportType <- transportType,
                self.sub_label     <- subLabel,
                self.current_zones <- currentZones,
                self.entered_zones <- enteredZones
            )

            let rowID = try database.run(insert)
            if rowID > -1 {
                Log.debug(
                    page: "EventStorage",
                    fn: "insertIfNone",
                    "Inserted event id=\(id)"
                )

                // Incremental in-memory sync (no readAll3)
                upsertInMemoryEvent3(
                    id: id,
                    frameTime: frameTime,
                    score: score,
                    type: type,
                    cameraName: cameraName,
                    label: label,
                    thumbnail: thumbnail,
                    snapshot: snapshot,
                    m3u8: m3u8,
                    mp4: mp4,
                    camera: camera,
                    debug: debug,
                    image: image,
                    transportType: transportType,
                    subLabel: subLabel,
                    currentZones: currentZones,
                    enteredZones: enteredZones
                )
            }

        } catch {
            Log.error(
                page: "EventStorage",
                fn: "insertIfNone",
                "SQLite error in insertIfNone for id \(id): \(error.localizedDescription)"
            )
        }
    }

    
//    func insertIfNone(id: String, frameTime: Double, score: Double, type: String, cameraName: String, label: String, thumbnail: String, snapshot: String, m3u8: String, mp4: String, camera: String, debug: String, image: String, transportType: String, subLabel: String, currentZones: String, enteredZones: String  ) {
//           
//        //TODO is this needed DispatchQueue.main.async
//        DispatchQueue.main.async { [self] in
//             
//            //let dataset = self.getEventByFrameTime(frameTime3: frameTime)
//            let dataset = self.getEventById(id3: id)
//              
//            if dataset.isEmpty {
//                guard let database = db else { return }
//                 
//                let insert = events.insert(
//                   self.id <- id,
//                   self.frameTime <- frameTime,
//                   self.score <- score,
//                   self.type <- type,
//                   self.cameraName <- cameraName,
//                   self.label <- label,
//                   self.thumbnail <- thumbnail,
//                   self.snapshot <- snapshot,
//                   self.m3u8 <- m3u8,
//                   self.mp4 <- mp4,
//                   self.camera <- camera,
//                   self.debug <- debug,
//                   self.image <- image,
//                   self.transportType <- transportType,
//                   self.sub_label <- subLabel,                  //5/26
//                   self.current_zones <- currentZones,
//                   self.entered_zones <- enteredZones
//                )
//                do {
//                    let rowID = try database.run(insert)
//                    if rowID > -1 {
//                        EventStorage.shared.readAll3(completion: { res in
//                            self.epsSup3 = res!
//                            self.epsSuper.list3 = res!
//                            return
//                        })
//                    }
//                    
//                } catch (let error){
//                    Log.error(page: "EventStorage", fn: "insertIfNone", "\(error)")
//                    return
//                }
//            } else {
//                Log.debug(page: "EventStorage", fn: "insertIfNone", "No Rows Returned")
//                return
//            }
//        }
//    }
     
    func insert(
        id: String,
        frameTime: Double,
        score: Double,
        type: String,
        cameraName: String,
        label: String,
        thumbnail: String,
        snapshot: String,
        m3u8: String,
        mp4: String,
        camera: String,
        debug: String,
        image: String,
        transportType: String,
        subLabel: String,
        currentZones: String,
        enteredZones: String
    ) -> Int64? {

        guard let database = db else {
            Log.error(
                page: "EventStorage",
                fn: "insert",
                "Database not initialized"
            )
            return nil
        }

        let insert = events.insert(
            self.id            <- id,
            self.frameTime     <- frameTime,
            self.score         <- score,
            self.type          <- type,
            self.cameraName    <- cameraName,
            self.label         <- label,
            self.thumbnail     <- thumbnail,
            self.snapshot      <- snapshot,
            self.m3u8          <- m3u8,
            self.mp4           <- mp4,
            self.camera        <- camera,
            self.debug         <- debug,
            self.image         <- image,
            self.transportType <- transportType,
            self.sub_label     <- subLabel,
            self.current_zones <- currentZones,
            self.entered_zones <- enteredZones
        )

        do {
            let rowID = try database.run(insert)

            Log.debug(
                page: "EventStorage",
                fn: "insert",
                "Inserted event id=\(id), rowID=\(rowID)"
            )

            // Incremental in-memory sync (no readAll3)
            upsertInMemoryEvent3(
                id: id,
                frameTime: frameTime,
                score: score,
                type: type,
                cameraName: cameraName,
                label: label,
                thumbnail: thumbnail,
                snapshot: snapshot,
                m3u8: m3u8,
                mp4: mp4,
                camera: camera,
                debug: debug,
                image: image,
                transportType: transportType,
                subLabel: subLabel,
                currentZones: currentZones,
                enteredZones: enteredZones
            )

            return rowID
        } catch {
            Log.error(
                page: "EventStorage",
                fn: "insert",
                "SQLite error in insert for id \(id): \(error.localizedDescription)"
            )
            return nil
        }
    }

//    func insert(id: String, frameTime: Double, score: Double, type: String, cameraName: String, label: String, thumbnail: String, snapshot: String, m3u8: String, mp4: String, camera: String, debug: String, image: String, transportType: String, subLabel: String, currentZones: String, enteredZones: String  ) -> Int64? {
//        
//        guard let database = db else { return nil }
//
//        let insert = events.insert(self.id <- id,
//                                  self.frameTime <- frameTime,
//                                  self.score <- score,
//                                  self.type <- type,
//                                  self.cameraName <- cameraName,
//                                  self.label <- label,
//                                  self.thumbnail <- thumbnail,
//                                  self.snapshot <- snapshot,
//                                  self.m3u8 <- m3u8,
//                                  self.mp4 <- mp4,
//                                  self.camera <- camera,
//                                  self.debug <- debug,
//                                  self.image <- image,
//                                  self.transportType <- transportType,
//                                  self.sub_label <- subLabel,      //5/26
//                                  self.current_zones <- currentZones,
//                                  self.entered_zones <- enteredZones
//        )
//        do {
//            let rowID = try database.run(insert)
//            
//            //TODO
//            EventStorage.shared.readAll3(completion: { res in
//                self.epsSup3 = res!
//                return
//            })
//              
//            return rowID
//        } catch (let error){
//            Log.error(page: "EventStorage", fn: "insert", "\(error)")
//            return nil
//        }
//    }
 
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
                table.column(m3u8)      //added mp4 through below
                table.column(camera)
                table.column(debug)
                table.column(image)
                table.column(transportType)
            })
            
            //database.userVersion = 1
            database.userVersion = 2
            
        } catch (let error){
            Log.warning(page: "EventStorage", fn: "createEventsTable", "\(error)")
        }
         
        do { 
            try database.run(
                events.addColumn(sub_label, defaultValue: "")
            )
        } catch {
            Log.warning(page: "EventStorage", fn: "createEventsTable", "\(error)")
        }
        
        do {
            try database.run(
                events.addColumn(current_zones, defaultValue: "")
            )
        } catch {
            Log.warning(page: "EventStorage", fn: "createEventsTable", "\(error)")
        }
        
        do {
            try database.run(
                events.addColumn(entered_zones, defaultValue: "")
            )
        } catch {
            Log.warning(page: "EventStorage", fn: "createEventsTable", "\(error)")
        }
        
        do {
            try database.run(
                events.addColumn(frigtePlus, defaultValue: false)
            )
        } catch (let error){
            Log.warning(page: "EventStorage", fn: "createEventsTable", "\(error)")
        }
        
        do {
            try database.run(
                events.addColumn(mp4, defaultValue: "")
            )
        } catch (let error){
            Log.warning(page: "EventStorage", fn: "createEventsTable", "\(error)")
        }
    }
}
