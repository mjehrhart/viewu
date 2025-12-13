//
//  LocalNotificationTemplateStore.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/12/25.
//

import Foundation
import Combine

struct LocalNotificationTemplate: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var rawTemplate: String           // canonical template string (what you send to MQTT)
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var lastSentAt: Date? = nil
}

@MainActor
final class LocalNotificationTemplateStore: ObservableObject {

    static let shared = LocalNotificationTemplateStore()

    @Published private(set) var templates: [LocalNotificationTemplate] = []

    private let storageKey = "viewu_local_notification_templates_v1"

    private init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            templates = []
            return
        }
        do {
            templates = try JSONDecoder().decode([LocalNotificationTemplate].self, from: data)
        } catch {
            templates = []
        }
    }

    func persist() {
        do {
            let data = try JSONEncoder().encode(templates)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // no-op
        }
    }

    func upsert(_ t: LocalNotificationTemplate) {
        if let idx = templates.firstIndex(where: { $0.id == t.id }) {
            templates[idx] = t
        } else {
            templates.append(t)
        }
        templates.sort { $0.updatedAt > $1.updatedAt }
        persist()
    }

    func delete(id: UUID) {
        templates.removeAll { $0.id == id }
        persist()
    }

    func duplicate(id: UUID) {
        guard let t = templates.first(where: { $0.id == id }) else { return }
        var copy = t
        copy.id = UUID()
        copy.name = "\(t.name) Copy"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        copy.lastSentAt = nil
        templates.insert(copy, at: 0)
        persist()
    }

    func rename(id: UUID, name: String) {
        guard let idx = templates.firstIndex(where: { $0.id == id }) else { return }
        templates[idx].name = name
        templates[idx].updatedAt = Date()
        persist()
    }

    func markSent(id: UUID) {
        guard let idx = templates.firstIndex(where: { $0.id == id }) else { return }
        templates[idx].lastSentAt = Date()
        templates[idx].updatedAt = Date()
        persist()
    }
}
