//
//  EventFilter.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/20/24.
//

import Foundation

@MainActor
final class EventFilter: ObservableObject {
    
    static let _shared = EventFilter()
 
    static func shared() -> EventFilter {
        return _shared
    }

    private let defaults = UserDefaults.standard
    
    private enum Keys {
            static let persistEnabled = "eventFilter.persistEnabled"
            static let selectedCamera = "eventFilter.selectedCamera"
            static let selectedObject = "eventFilter.selectedObject"
            static let selectedZone   = "eventFilter.selectedZone"
            static let selectedType   = "eventFilter.selectedType"
        }

    @Published var persistPickerValues: Bool = false {
        didSet {
            defaults.set(persistPickerValues, forKey: Keys.persistEnabled)

            if persistPickerValues {
                persistSelections()
            } else {
                clearPersistedSelections()

                // Recommended behavior: turning OFF means "start fresh"
                selectedCamera = "all"
                selectedObject = "all"
                selectedZone   = "all"
                selectedType   = "all"
            }
        }
    }
 
    @Published var selectedCamera: String = "all" {
        didSet { persistIfEnabled(Keys.selectedCamera, selectedCamera) }
    }
    @Published var cameras: [String] = ["all"]

    @Published var selectedObject: String = "all" {
        didSet { persistIfEnabled(Keys.selectedObject, selectedObject) }
    }
    @Published var objects: [String] = ["all"]

    @Published var selectedZone: String = "all" {
        didSet { persistIfEnabled(Keys.selectedZone, selectedZone) }
    }
    @Published var zones: [String] = ["all"]
    
    @Published var selectedType: String = "all" {
        didSet { persistIfEnabled(Keys.selectedType, selectedType) }
    }
    @Published var types: [String] = ["all", "new", "end", "update", "background", "ctask", "scenePhase"]
 
    // Add 1 future day so the app can search til midnight of today
    @Published var endDate: Date = Calendar.current.date(byAdding: DateComponents(day: 1), to: Date()) ?? Date()
    @Published var startDate: Date = Calendar.current.date(byAdding: DateComponents(day: -1), to: Date()) ?? Date()
    
    init() {
        
        // Date range is intentionally NOT persistent
        resetDateRangeToDefault()
        
        // Restore persisted values only if persistence was enabled
        let enabled = defaults.bool(forKey: Keys.persistEnabled)

        if enabled {
            selectedCamera = defaults.string(forKey: Keys.selectedCamera) ?? "all"
            selectedObject = defaults.string(forKey: Keys.selectedObject) ?? "all"
            selectedZone   = defaults.string(forKey: Keys.selectedZone)   ?? "all"
            selectedType   = defaults.string(forKey: Keys.selectedType)   ?? "all"
        }

        // Set the toggle last so we don't accidentally overwrite restored values
        persistPickerValues = enabled
    }
    
    func normalizeSelections(
        validateCamera: Bool = true,
        validateObject: Bool = true,
        validateZone: Bool = true,
        validateType: Bool = true
    ) {
        if validateCamera, !cameras.contains(selectedCamera) { selectedCamera = "all" }
        if validateObject, !objects.contains(selectedObject) { selectedObject = "all" }
        if validateZone, !zones.contains(selectedZone) { selectedZone = "all" }
        if validateType, !types.contains(selectedType) { selectedType = "all" }

        if persistPickerValues {
            persistSelections()
        }
    }
    
    func reset() {
        selectedCamera = "all"
        selectedObject = "all"
        selectedZone = "all"
        selectedType = "all"
        
        resetDateRangeToDefault()
    }
    
    func setZones(items: [String: Cameras2]) {
        var set = Set<String>()
        for (_, value) in items {
            for zone in value.zones.keys {
                set.insert(zone)
            }
        }

        zones = ["all"] + set.sorted()
        normalizeSelections(validateCamera: false, validateObject: false, validateType: false)
    }

    
    func setCameras(items: [String: Cameras2]) {
        cameras = ["all"] + items.keys.sorted()
        normalizeSelections(validateObject: false, validateZone: false, validateType: false)
    }

    
    func setObject(items: [String: Cameras2]) {
        var set = Set<String>()
        for (_, value) in items {
            for obj in value.objects.filters.keys {
                set.insert(obj)
            }
        }

        objects = ["all"] + set.sorted()
        normalizeSelections(validateCamera: false, validateZone: false, validateType: false)
    }

    
    func resetDateRangeToDefault() {
        startDate = Calendar.current.date(byAdding: DateComponents(day: -1), to: Date()) ?? Date()
        endDate   = Calendar.current.date(byAdding: DateComponents(day: 1),  to: Date()) ?? Date()
    }
    
    private func persistIfEnabled(_ key: String, _ value: String) {
        guard persistPickerValues else { return }
        defaults.set(value, forKey: key)
    }

    private func persistSelections() {
        defaults.set(selectedCamera, forKey: Keys.selectedCamera)
        defaults.set(selectedObject, forKey: Keys.selectedObject)
        defaults.set(selectedZone,   forKey: Keys.selectedZone)
        defaults.set(selectedType,   forKey: Keys.selectedType)
    }

    private func clearPersistedSelections() {
        defaults.removeObject(forKey: Keys.selectedCamera)
        defaults.removeObject(forKey: Keys.selectedObject)
        defaults.removeObject(forKey: Keys.selectedZone)
        defaults.removeObject(forKey: Keys.selectedType)
    }

}
