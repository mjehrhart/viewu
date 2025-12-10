import CoreData
import Foundation

@MainActor
class DataController: ObservableObject {
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "EventContainer")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("CoreData failed to load! \(error.localizedDescription)")
            }
        }
    }
}


// MARK: - Remove
////
////  DataController.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 3/22/24.
////
//
//import CoreData
//import Foundation
//
//class DataController: ObservableObject {
//    let container = NSPersistentContainer(name: "EventContainer")
//    
//    init(){
//        container.loadPersistentStores{description, error in
//            if let error = error {
//                print("CoreData failed to load! \(error.localizedDescription)")
//            }
//        }
//    }
//}
 
