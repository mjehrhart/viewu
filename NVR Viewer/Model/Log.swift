//
//  Log.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/3/24.
//

import Foundation
import SwiftUI

class Log: ObservableObject {
    
    static let _shared = Log()
    
    static func shared() -> Log {
        return _shared
    }
    
    @Published var list: [LogItem] = [] {
        willSet {
            objectWillChange.send()
        }
    }
    
    func print(page: String, fn: String, type: String, text: String) {
        
        let item = LogItem(id: UUID(), page: page, fn: fn, text: text, type: type)
        list.append(item)
    }
    
    func clear() {
        list = []
    }
    
    func getList() -> [LogItem]{
        
        return self.list
    }
}

struct LogItem: Hashable {
    let id: UUID
    let page: String
    let fn: String
    let text: String
    let type: String
}
