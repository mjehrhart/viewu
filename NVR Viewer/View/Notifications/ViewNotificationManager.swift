//
//  ViewNotificationManager.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/5/24.
//

import SwiftUI
import TipKit
import PopupView
import UIKit
 

// MARK: - APN View

@MainActor
struct ViewAPN: View {

    let title: String

    // Observe singleton so UI reflects changes if NVR config updates
    @ObservedObject private var nvrManager = NVRConfig.shared()

    @AppStorage("apnTitle") private var apnTitle: String = ""

    // Legacy storage (keep for backward compatibility)
    @AppStorage("apnDomain") private var apnDomain: String = ""

    // New storage for UX
    // 0 = Auto, 1 = Custom
    @AppStorage("apnDomainMode")   private var apnDomainMode: Int = 0
    @AppStorage("apnCustomDomain") private var apnCustomDomain: String = ""

    // Connection type (already in your app)
    @AppStorage("authType") private var authType: AuthType = .none

    // Store which auth type the DOMAIN was last synced against (AuthType.rawValue is String)
    @AppStorage("apnDomainLastSyncedAuthType") private var apnDomainLastSyncedAuthType: String = ""

    @AppStorage("viewu_server_version") private var viewuServerVersion: String = "0.0.0"

    @AppStorage("tipShowNotificationGeneral") private var tipShowNotificationGeneral: Bool = true
    @AppStorage("tipsNotificationTemplate")  private var tipsNotificationTemplate: Bool = true
    @AppStorage("tipsNotificationDomain")    private var tipsNotificationDomain: Bool = true
    @AppStorage("tipsNotificationDefault")   private var tipsNotificationDefault: Bool = true

    @StateObject private var nts         = NotificationTemplateString.shared()
    @StateObject private var mqttManager = MQTTManager.shared()

    // Device-tracked templates (no server fetch)
    @ObservedObject private var localTemplateStore = ViewuLocalNotificationTemplateStore.shared

    // Builder state (pure draft string; avoids publishing during body updates)
    @State private var builderDraftRaw: String = ""
    @State private var builderPresetRaw: String? = nil
    @State private var builderResetToken: UUID = UUID()

    // Raw template sheet (item-based to avoid blank/cached sheets)
    @State private var rawTemplateSheetItem: RawTemplateSheetItem? = nil
    private struct RawTemplateSheetItem: Identifiable {
        let id = UUID()
        let title: String
        let template: String
    }

    // Edit / delete / rename state
    @State private var editingTemplateID: UUID? = nil
    @State private var deleteCandidateTemplate: ViewuLocalNotificationTemplate? = nil
    @State private var renameCandidateTemplate: ViewuLocalNotificationTemplate? = nil

    // UI
    private let savedTemplateCarouselHeight: CGFloat = 355// 292
    private let builderCornerRadius: CGFloat = 18
    @State private var suppressTemplateDotUpdates: Bool = false
     
//    private var apnCustomDomainState: String {
//        apnCustomDomain
//    }
    private let apnCustomDomainState: String
    
    init(title: String) {
        self.title = title
        self.apnCustomDomainState = UserDefaults.standard.string(forKey: "apnCustomDomain") ?? ""
    }
    
    // Hide the bottom preview “filters” pills for now (future release)
    private let showTemplatePreviewPills: Bool = false

    private var isCustomDomainMode: Bool { apnDomainMode == 1 }

    private var effectiveAPNDomain: String {
        let raw = isCustomDomainMode ? apnCustomDomain : nvrManager.getUrl()
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Validation (compact + only shown in Custom mode)

    private enum DomainValidation {
        case empty, valid, invalid
    }

    private var domainValidation: DomainValidation {
        let s = effectiveAPNDomain.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return .empty }

        guard let url = URL(string: s),
              let scheme = url.scheme?.lowercased(),
              (scheme == "http" || scheme == "https"),
              (url.host?.isEmpty == false)
        else {
            return .invalid
        }
        return .valid
    }

    private var domainValidationRow: some View {
        let state = domainValidation

        return HStack(spacing: 8) {
            Image(systemName: state == .valid ? "checkmark.circle.fill"
                 : state == .invalid ? "exclamationmark.triangle.fill"
                 : "questionmark.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(state == .valid ? .green : state == .invalid ? .red : .secondary)

            Text(
                state == .valid ? "Looks good."
                : state == .invalid ? "Invalid URL. Include http(s):// and a host."
                : "Enter a URL."
            )
            .font(.caption)
            .foregroundStyle(state == .invalid ? .red : .secondary)

            Spacer()
        }
        .padding(.top, 2)
    }

    private var recommendedPill: some View {
        Text("Recommended")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule(style: .continuous).fill(Color(red: 0.153, green: 0.69, blue: 1).opacity(0.6)))
            .overlay(Capsule(style: .continuous).stroke(Color(red: 0.153, green: 0.69, blue: 1).opacity(0.2)))
            .foregroundStyle(.white)
            .fixedSize()
    }

    // MARK: - Local template helpers

    private var editingTemplate: ViewuLocalNotificationTemplate? {
        guard let id = editingTemplateID else { return nil }
        return localTemplateStore.templates.first(where: { $0.id == id })
    }

    private func canonicalTemplate(_ raw: String) -> String {
        raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ",")
    }

    private func friendlyTime(_ date: Date?) -> String {
        guard let date
        else {
            let d = Date.now
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f.string(from: d)
            //return "Never"
        }
        
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func resetBuilder(preset: String? = nil) {
        builderPresetRaw = preset.map { canonicalTemplate($0) }
        builderDraftRaw = preset.map { canonicalTemplate($0) } ?? ""
        builderResetToken = UUID()
    }

    private func publishAPN(message: String) {
        // No view animations here; publish only.
        mqttManager.publish(topic: "viewu/pairing", with: message)
    }

    // MARK: - Derived

    /// Returns true if Viewu Server is older than 0.3.x
    private var requiresNewerServer: Bool {
        let parts = viewuServerVersion.split(separator: ".")
        guard parts.count >= 2,
              let minor = Int(parts[1]) else {
            return false
        }
        return minor < 3
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                VStack(spacing: 0) {

                    if requiresNewerServer {
                        VersionWarningBanner(currentVersion: viewuServerVersion)
                    }

                    if nts.notificationPaused {
                        PausedBanner()
                    }

                    Form {
                        notificationTitleSection
                        domainSection
                        savedTemplatesSection
                        templateBuilderSection
                        pauseSection
                    }
                }

                // Popup overlay (your existing nts.alert flag)
                if nts.alert {
                    PopupMiddle {
                        nts.alert = false
                    }
                }
            }
            .navigationBarTitle(title, displayMode: .inline)
            .onAppear {
                let nvrURL = nvrManager.getUrl()

                // If auth type changed since last "domain sync", force dot red.
                if apnDomainLastSyncedAuthType != authType.rawValue {
                    nts.flagDomain = false
                }

                // Backward-compat migration:
                if !apnDomain.isEmpty,
                   apnCustomDomain.isEmpty,
                   apnDomain != nvrURL {
                    apnCustomDomain = apnDomain
                    apnDomainMode = 1
                }

                apnDomain = effectiveAPNDomain
            }
            .onChange(of: authType) { _ in
                nts.flagDomain = false
                apnDomainLastSyncedAuthType = ""

                if !isCustomDomainMode {
                    apnDomain = nvrManager.getUrl()
                }
            }
            .onChange(of: editingTemplateID) { newValue in
                guard newValue != nil else { return }
                DispatchQueue.main.async {
                    // No animation; jump-scroll.
                    proxy.scrollTo("template_builder", anchor: .top)
                }
            }
            .sheet(item: $rawTemplateSheetItem) { item in
                RawTemplateSheet(title: item.title, template: item.template)
            }
            .sheet(item: $renameCandidateTemplate) { (t: ViewuLocalNotificationTemplate) in
                RenameTemplateSheet(
                    title: "Rename Template",
                    initialName: t.name,
                    onSave: { newName in
                        localTemplateStore.rename(id: t.id, name: newName)
                        renameCandidateTemplate = nil
                    },
                    onCancel: {
                        renameCandidateTemplate = nil
                    }
                )
            }
            .confirmationDialog(
                "Delete this template?",
                isPresented: Binding(
                    get: { deleteCandidateTemplate != nil },
                    set: { if !$0 { deleteCandidateTemplate = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let t = deleteCandidateTemplate {
                        localTemplateStore.delete(id: t.id)
                        if editingTemplateID == t.id {
                            editingTemplateID = nil
                            resetBuilder(preset: nil)
                        }
                    }
                    deleteCandidateTemplate = nil
                    
                    //Synv with Viewu Server
                    let allRaw = buildAllSavedRawTemplatesForServer()
                    let msg = "viewu_device_event::::template::::\(allRaw)"
                    publishAPN(message: msg)
                    
                }
                Button("Cancel", role: .cancel) {
                    deleteCandidateTemplate = nil
                }
                 
            }
        }
    }

    // MARK: - Sections

    private var notificationTitleSection: some View {
        Section {
            TextField("Message Title", text: $apnTitle)
                .frame(alignment: .leading)
                .autocorrectionDisabled()
                .overlay(IndicatorOverlay(offset: -80, flag: nts.flagTitle))
                .onChange(of: apnTitle) { _ in
                    nts.flagTitle = false
                }

            HStack {
                Spacer()
                Button("Save") {
                    let msg = "viewu_device_event::::title::::\(apnTitle)"
                    publishAPN(message: msg)
                    nts.flagTitle = true
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        } header: {
            HStack(spacing: 6) {
                if !tipsNotificationDefault {
                    Text("Notification Title")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                ViewTipsNotificationManager(
                    title: "Notification Manager",
                    message: """
                    Important: Anytime you update or restart the Viewu Server, \
                    you will need to re-pair your device and resync these values.
                    """
                )
            }
        }
    }

    private var domainSection: some View {
        Section {
            let isSaveDisabled = isCustomDomainMode && (domainValidation == .invalid || domainValidation == .empty)

            Picker("", selection: $apnDomainMode) {
                Text("Auto").tag(0)
                Text("Custom").tag(1)
            }
            .pickerStyle(.segmented)
            .onChange(of: apnDomainMode) { _ in
                //nts.flagDomain = false
                if apnCustomDomain != apnCustomDomainState {
                    nts.flagDomain = false
                }
                

                if isCustomDomainMode,
                   apnCustomDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    apnCustomDomain = nvrManager.getUrl()
                }

                apnDomain = effectiveAPNDomain
            }

            HStack(spacing: 8) {
                Text(isCustomDomainMode
                     ? "Enter a public URL for push snapshots"
                     : "Uses existing connection info")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if !isCustomDomainMode {
                    recommendedPill
                }
            }

            if isCustomDomainMode {
                HStack(spacing: 10) {
                    TextField("https://domaintoviewnvr.com", text: $apnCustomDomain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .onChange(of: apnCustomDomain) { _ in
                            
                            print("[MJE] apnCustomDomain changed \(apnCustomDomain)")
                            print("[MJE] apnCustomDomainState value \(apnCustomDomainState)")
                            if apnCustomDomain != apnCustomDomainState {
                                nts.flagDomain = false
                            }
                            
                            
                            apnDomain = effectiveAPNDomain
                        }

                    StatusDot(flag: nts.flagDomain)
                }

                domainValidationRow

            } else {
                HStack(spacing: 12) {
                    Image(systemName: "link")
                        .foregroundStyle(.secondary)

                    Text(nvrManager.getUrl())
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    StatusDot(flag: nts.flagDomain)
                }
            }

            HStack {
                Spacer()
                Button("Save") {
                    let domainToSend = effectiveAPNDomain
                    apnDomain = domainToSend

                    let msg = "viewu_device_event::::domain::::\(domainToSend)"
                    publishAPN(message: msg)

                    apnDomainLastSyncedAuthType = authType.rawValue
                    nts.flagDomain = true
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(isSaveDisabled)
                .opacity(isSaveDisabled ? 0.55 : 1.0)
            }

        } header: {
            HStack(spacing: 6) {
                if !tipsNotificationDomain {
                    Text("Accessible Domain")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                ViewTipsNotificationDomain(
                    title: "Accessible Domain",
                    message: """
                    For secure access to clips and snapshots, Viewu should be configured \
                    with a public domain name using an https:// endpoint. \
                    Ideally, place this domain behind a VPN (for example Tailscale). \
                    If a secure public endpoint is not available, you may use http:// \
                    for local-network access only (including viewing notification images on your LAN).
                    """
                )
            }
        }
    }

    // MARK: - Template Builder (rounded card)

    private var templateBuilderSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {

                // Editing banner
                if let t = editingTemplate {
                    HStack(spacing: 10) {
                        Image(systemName: "pencil")
                            .foregroundStyle(.secondary)

                        Text("Editing:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(t.name)
                            .font(.caption.weight(.semibold))

                        Spacer()

                        Button("Cancel") {
                            editingTemplateID = nil
                            resetBuilder(preset: nil)
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.trailing, 10)
                    }
                }

                ViewNotificationManager(
                    presetRawTemplate: builderPresetRaw,
                    onTemplateChanged: { newRaw in
                        let draft = canonicalTemplate(newRaw)
                        builderDraftRaw = draft

                        // If this change was caused by Clear/preset/reset, do not touch the dot.
                        guard !suppressTemplateDotUpdates else { return }

                        // Optional (recommended): only turn red when draft differs from last-sent baseline.
                        let baseline = canonicalTemplate(builderPresetRaw ?? "")
                        guard !baseline.isEmpty else { return }   // no baseline -> leave dot as-is

                        nts.flagTemplate = (draft == baseline)
                    }
                )
                .id(builderResetToken)  // force clean rebuild when applying preset / clear

                // Draft line
                Text(builderDraftRaw.isEmpty ? "No filters selected (All events)" : builderDraftRaw)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.leading, 10)

                // Preview pills (hide for now)
                if showTemplatePreviewPills {
                    let rules = parseTemplateRulesAlways(builderDraftRaw)
                    TemplatePreviewLine(rules: rules)
                }

                // Actions
                HStack(spacing: 10) {
                    Button("Clear") {
                        let prior = nts.flagTemplate

                        suppressTemplateDotUpdates = true
                        editingTemplateID = nil
                        resetBuilder(preset: nil)

                        // Keep dot exactly as it was before Clear
                        nts.flagTemplate = prior

                        DispatchQueue.main.async {
                            suppressTemplateDotUpdates = false
                        }
                    }
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 10)
                    
                    Spacer()

                    Button(editingTemplateID == nil ? "Save Template" : "Update Template") {
                         
                        let raw = canonicalTemplate(builderDraftRaw)
                         
                        guard !raw.isEmpty else { return }

                        let allRaw = buildAllRawTemplatesForServer(currentRaw: raw, updatingID: editingTemplateID)
                        //print("[MJE] allRaw = \(allRaw)")
                        
                        //Synv with Viewu Server
                        let msg = "viewu_device_event::::template::::\(allRaw)"
                        publishAPN(message: msg)
                         
                        ///
                        if var existing = editingTemplate {
                            existing.rawTemplate = raw
                            existing.updatedAt = Date()
                            localTemplateStore.upsert(existing)
                            localTemplateStore.markSent(id: existing.id)
                        } else {
                            let suggested = TemplateNameSuggester.suggest(from: parseTemplateRulesAlways(raw))
                            let t = ViewuLocalNotificationTemplate(name: suggested, rawTemplate: raw)
                            localTemplateStore.upsert(t)
                            localTemplateStore.markSent(id: t.id)
                        }

                        // Baseline becomes what we just sent; the dot will stay green until user changes toggles.
                        resetBuilder(preset: nil)
                        nts.flagTemplate = true
                        editingTemplateID = nil
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .padding(.trailing, 20)
                }
            }
            // No horizontal padding; full-width card feel
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: builderCornerRadius, style: .continuous)
                    .fill(Color(uiColor: .systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: builderCornerRadius, style: .continuous)
                    .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
            )
            // Disable any implicit layout animations for this card (Disclosure expansion, button “flying”, etc.)
            .transaction { tx in
                tx.disablesAnimations = true
                tx.animation = nil
            }

        } header: {
            HStack(spacing: 8) {
                Text("Template Builder")
                    .font(.caption)
                    .foregroundColor(.orange)

                Spacer()
            .padding(.leading, 16)
            }
            .id("template_builder")
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowSeparator(.hidden)
    }

    // MARK: - Saved Templates (device-tracked)

    private var savedTemplatesSection: some View {
        Section {

            // Status row
            HStack(spacing: 8) {
                Text("Templates Saved")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(localTemplateStore.templates.count)")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule(style: .continuous).fill(Color.secondary.opacity(0.10)))
                    .foregroundStyle(.secondary)

                Spacer()

                StatusDot(flag: nts.flagTemplate)
            }
            .padding(.vertical, 2)

            if localTemplateStore.templates.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "tray")
                        .foregroundStyle(.secondary)
                    Text("No templates saved on this device yet.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                    Spacer()
                }
                .padding(.vertical, 6)
            } else {
                GeometryReader { geo in
                    let available = geo.size.width
                    let cardWidth  = min(max(available - 34, 316), 420)
                    let rowHeight  = savedTemplateCarouselHeight
                    let cardHeight = rowHeight - 18

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(Array(localTemplateStore.templates.enumerated()), id: \.element.id) { _, t in
                                let raw = canonicalTemplate(t.rawTemplate)
                                let rules = parseTemplateRulesAlways(raw)

                                SavedTemplateCardRevampB(
                                    name: t.name,
                                    lastSentText: friendlyTime(t.lastSentAt),
                                    rules: rules,
                                    width: cardWidth,
                                    height: cardHeight,
                                    onOpenRaw: {
                                        rawTemplateSheetItem = RawTemplateSheetItem(title: t.name, template: raw)
                                    },
                                    onEdit: {
                                        editingTemplateID = t.id
                                        resetBuilder(preset: raw)
                                    },
                                    onDuplicate: {
                                        localTemplateStore.duplicate(id: t.id)
                                    },
                                    onRename: {
                                        renameCandidateTemplate = t
                                    },
                                    onDelete: {
                                        
                                        deleteCandidateTemplate = t
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                }
                .frame(height: savedTemplateCarouselHeight)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .listRowSeparator(.hidden)
            }

        } header: {
            HStack(spacing: 6) {
                if !tipsNotificationTemplate {
                    Text("Saved Templates")
                        .foregroundColor(.orange)
                }

                ViewTipsNotificationTemplate(
                    title: "Notification Templates",
                    message: """
                    Templates are saved on this device. When you press Save/Update, \
                    Viewu sends the template to your server via MQTT.
                    """
                )
            }
        }
    }

    private var pauseSection: some View {
        Section {
            Toggle("Pause", isOn: nts.$notificationPaused)
                .tint(Color(red: 0.153, green: 0.69, blue: 1))
                .onChange(of: nts.notificationPaused) { newValue in
                    let msg = "viewu_device_event::::paused::::\(newValue)"
                    publishAPN(message: msg)
                }
        } header: {
            Text("Notifications")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }

    // MARK: - Parsing (pure; safe inside body)

    private enum RuleKey: String, CaseIterable {
        case camera = "camera"
        case label = "label"
        case enteredZones = "entered_zones"
        case currentZones = "current_zones"
        case type = "type"

        var title: String {
            switch self {
            case .camera: return "Camera"
            case .label: return "Label"
            case .enteredZones: return "Entered Zone"
            case .currentZones: return "Current Zone"
            case .type: return "Type"
            }
        }

        var tint: Color {
            switch self {
            case .camera: return .blue
            case .label: return .purple
            case .enteredZones: return .green
            case .currentZones: return .teal
            case .type: return .orange
            }
        }
    }

    private struct TemplateRule: Identifiable, Hashable {
        let id = UUID()
        let key: RuleKey
        let values: [String]
    }

    private func parseTemplateRulesAlways(_ raw: String) -> [TemplateRule] {
        var map: [String: [String]] = [:]

        let parts = raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        for part in parts where !part.isEmpty {
            let pieces = part.components(separatedBy: "==")
            guard pieces.count == 2 else { continue }

            let keyRaw = pieces[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let values = pieces[1]
                .split(separator: "|")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if !values.isEmpty {
                map[keyRaw, default: []].append(contentsOf: values)
            }
        }

        func dedup(_ arr: [String]) -> [String] {
            var seen = Set<String>()
            var out: [String] = []
            for v in arr {
                if !seen.contains(v) {
                    seen.insert(v)
                    out.append(v)
                }
            }
            return out
        }

        return RuleKey.allCases.map { rk in
            let vals = dedup(map[rk.rawValue] ?? [])
            return TemplateRule(key: rk, values: vals)
        }
    }

    // MARK: - UI bits (Saved cards)

    private struct SavedTemplateCardRevampB: View {
        let name: String
        let lastSentText: String
        let rules: [TemplateRule]
        let width: CGFloat
        let height: CGFloat

        let onOpenRaw: () -> Void
        let onEdit: () -> Void
        let onDuplicate: () -> Void
        let onRename: () -> Void
        let onDelete: () -> Void

        private let radius: CGFloat = 18

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {

                HStack(spacing: 10) {
                    Image(systemName: "wand.and.stars")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("Last Saved: \(lastSentText)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.red.opacity(0.67))
                            .padding(10)
                            .background(Circle().fill(Color.secondary.opacity(0.10)))
                    }
                    .buttonStyle(.plain)

                    Menu {
                        Button("Edit") { onEdit() }
                        Button("Duplicate") { onDuplicate() }
                        Button("Rename") { onRename() }
                        Button("View Raw") { onOpenRaw() }
                        Button(role: .destructive) { onDelete() } label: { Text("Delete") }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(rules) { rule in
                        TemplateRuleChipRow(
                            title: rule.key.title,
                            values: rule.values,
                            tint: rule.key.tint
                        )
                    }
                }

                Spacer(minLength: 0)

                Text("Tap card to view raw (MQTT)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(width: width, height: height, alignment: .top)
            .background(Color(uiColor: .secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .onTapGesture {
                //onOpenRaw()
            }
        }
    }

    /// Builds a single string containing all templates currently saved on this device.
    /// Uses a safe delimiter that won't collide with your template syntax.
    private func buildAllSavedRawTemplatesForServer() -> String {

        var raws: [String] = []

        for t in localTemplateStore.templates {
            let r = canonicalTemplate(t.rawTemplate)
            if !r.isEmpty { raws.append(r) }
        }

        // De-dupe while preserving order
        var seen = Set<String>()
        let orderedUnique = raws.filter { seen.insert($0).inserted }

        //return orderedUnique.joined(separator: ";;;")
        return orderedUnique.joined(separator: "::")
    }

    
    /// Builds a single string containing ALL raw templates for the server.
    /// - currentRaw: the template being saved/updated right now
    /// - updatingID: if editing an existing template, pass its id so we replace (not duplicate) it
    private func buildAllRawTemplatesForServer(currentRaw: String, updatingID: UUID?) -> String {
        let current = canonicalTemplate(currentRaw)

        // Start with existing templates (excluding the one being updated, if any)
        var raws: [String] = []
        for t in localTemplateStore.templates {
            if let updatingID, t.id == updatingID { continue }
            let r = canonicalTemplate(t.rawTemplate)
            if !r.isEmpty { raws.append(r) }
        }

        // Put the current template first (so the updated value wins)
        if !current.isEmpty { raws.insert(current, at: 0) }

        // De-dupe while preserving order
        var seen = Set<String>()
        let orderedUnique = raws.filter { seen.insert($0).inserted }

        // Concatenate with a delimiter that will NOT collide with your syntax (commas, ==, |)
        // Choose whatever your server expects; this is a safe default.
        return orderedUnique.joined(separator: "::")
    }

    
    private struct TemplatePreviewLine: View {
        let rules: [TemplateRule]

        private func value(for key: RuleKey) -> String {
            guard let r = rules.first(where: { $0.key == key }) else { return "All" }
            return r.values.isEmpty ? "All" : "\(r.values.count)"
        }

        var body: some View {
            HStack(spacing: 10) {
                PreviewPill(title: "Cams", value: value(for: .camera))
                PreviewPill(title: "Labels", value: value(for: .label))
                PreviewPill(title: "Entered", value: value(for: .enteredZones))
                PreviewPill(title: "Current", value: value(for: .currentZones))
                PreviewPill(title: "Type", value: value(for: .type))
                Spacer(minLength: 0)
            }
        }
    }

    private struct PreviewPill: View {
        let title: String
        let value: String

        var body: some View {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule(style: .continuous).fill(Color.secondary.opacity(0.10)))
        }
    }

    private struct TemplateRuleChipRow: View {
        let title: String
        let values: [String]
        let tint: Color

        private var chips: [String] {
            guard !values.isEmpty else { return ["All"] }
            let limit = 4
            if values.count <= limit { return values }
            let head = Array(values.prefix(limit))
            return head + ["+\(values.count - limit)"]
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                FlowLayout(lineSpacing: 6, itemSpacing: 6) {
                    ForEach(chips, id: \.self) { text in
                        RuleValueChip(
                            text: text,
                            tint: values.isEmpty ? Color.secondary : tint,
                            isMoreChip: text.hasPrefix("+")
                        )
                    }
                }
            }
        }
    }

    private struct RuleValueChip: View {
        let text: String
        let tint: Color
        let isMoreChip: Bool

        var body: some View {
            Text(text)
                .font(.caption2.weight(isMoreChip ? .semibold : .medium))
                .foregroundStyle(isMoreChip ? .secondary : tint)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(isMoreChip ? Color.secondary.opacity(0.10) : tint.opacity(0.12))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isMoreChip ? Color.secondary.opacity(0.18) : tint.opacity(0.22), lineWidth: 1)
                )
        }
    }

    private struct FlowLayout: Layout {
        var lineSpacing: CGFloat = 8
        var itemSpacing: CGFloat = 8

        init(lineSpacing: CGFloat = 8, itemSpacing: CGFloat = 8) {
            self.lineSpacing = lineSpacing
            self.itemSpacing = itemSpacing
        }

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let maxWidth = proposal.width ?? 320
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for s in subviews {
                let size = s.sizeThatFits(.unspecified)
                if x + size.width > maxWidth {
                    x = 0
                    y += lineHeight + lineSpacing
                    lineHeight = 0
                }
                x += size.width + itemSpacing
                lineHeight = max(lineHeight, size.height)
            }

            return CGSize(width: maxWidth, height: y + lineHeight)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            var x = bounds.minX
            var y = bounds.minY
            var lineHeight: CGFloat = 0

            for s in subviews {
                let size = s.sizeThatFits(.unspecified)

                if x + size.width > bounds.maxX {
                    x = bounds.minX
                    y += lineHeight + lineSpacing
                    lineHeight = 0
                }

                s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + itemSpacing
                lineHeight = max(lineHeight, size.height)
            }
        }
    }

    // MARK: - Sheets

    private struct RawTemplateSheet: View {
        let title: String
        let template: String
        @Environment(\.dismiss) private var dismiss
        @State private var copied = false

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This exact text is sent to MQTT.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(template.isEmpty ? "(empty)" : template)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.secondary.opacity(0.10))
                            )

                        if copied {
                            Text("Copied to clipboard.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Copy") {
                            UIPasteboard.general.string = template
                            copied = true
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }

    private struct RenameTemplateSheet: View {
        let title: String
        let initialName: String
        let onSave: (String) -> Void
        let onCancel: () -> Void

        @State private var name: String = ""

        var body: some View {
            NavigationStack {
                Form {
                    Section {
                        TextField("Template name", text: $name)
                            .textInputAutocapitalization(.words)
                    } footer: {
                        Text("This name is stored on this device.")
                    }
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { onCancel() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            onSave(trimmed.isEmpty ? initialName : trimmed)
                        }
                    }
                }
                .onAppear { name = initialName }
            }
        }
    }

    private enum TemplateNameSuggester {
        static func suggest(from rules: [TemplateRule]) -> String {
            func firstValue(_ key: RuleKey) -> String? {
                rules.first(where: { $0.key == key })?.values.first
            }

            let cam = firstValue(.camera)
            let label = firstValue(.label)
            let type = firstValue(.type)

            var parts: [String] = []
            if let label { parts.append(label.replacingOccurrences(of: "_", with: " ").capitalized) }
            if let cam { parts.append(cam.replacingOccurrences(of: "_", with: " ").capitalized) }
            if let type { parts.append(type.uppercased()) }

            return parts.isEmpty ? "Template" : parts.joined(separator: " • ")
        }
    }

    // MARK: - Nested Views (existing)

    struct IndicatorOverlay: View {
        var offset: CGFloat
        var flag: Bool

        var body: some View {
            HStack {
                Spacer()
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(flag ? .green : .red)
                    .padding(.trailing, 4)
            }
        }
    }

    struct StatusDot: View {
        var flag: Bool

        var body: some View {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(flag ? .green : .red)
                .padding(.leading, 2)
        }
    }

    struct VersionWarningBanner: View {
        let currentVersion: String

        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Viewu Server 0.3.0 or later required.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)

                    Text("You have \(currentVersion) installed.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.85))
        }
    }

    struct PausedBanner: View {
        var body: some View {
            HStack {
                Image(systemName: "pause.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                Text("Notifications Paused")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.75))
        }
    }
}


// MARK: - Template Builder View (NO publishing during body; NO disclosure animations)

struct ViewNotificationManager: View {

    // IMPORTANT: StateObject because this view CREATES it.
    @StateObject private var nt = NotificationTemplate()

    @ObservedObject private var config = NVRConfigurationSuper2.shared()

    let presetRawTemplate: String?
    let onTemplateChanged: (String) -> Void

    @State private var templateString: String = ""
    @State private var didApplyPreset: Bool = false

    // Manual expansion states (no animated DisclosureGroup)
    @State private var expandCameras = false
    @State private var expandLabels  = false
    @State private var expandEntered = false
    @State private var expandCurrent = false
    @State private var expandTypes   = false

    private func parsePreset(_ raw: String) -> [String: Set<String>] {
        var out: [String: Set<String>] = [:]
        let parts = raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for part in parts where !part.isEmpty {
            let pieces = part.components(separatedBy: "==")
            guard pieces.count == 2 else { continue }

            let key = pieces[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let values = pieces[1]
                .split(separator: "|")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if !values.isEmpty {
                out[key, default: []].formUnion(values)
            }
        }
        return out
    }

    // Template String 1
    private func rebuildTemplateString() {
        func build(forKey key: String, from items: [(String, Bool)]) -> String {
            var tmp = ""
            for (name, isOn) in items where isOn {
                tmp += name + "|"
            }
            if tmp.isEmpty { return "" }
            tmp = tmp.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
            return "\(key)==\(tmp)"
        }

        var parts: [String] = []

        let cam = build(forKey: "camera", from: nt.cameras.map { ($0.name, $0.state) })
        if !cam.isEmpty { parts.append(cam) }

        let lbl = build(forKey: "label", from: nt.labels.map { ($0.name, $0.state) })
        if !lbl.isEmpty { parts.append(lbl) }

        let ent = build(forKey: "entered_zones", from: nt.enteredZones.map { ($0.name, $0.state) })
        if !ent.isEmpty { parts.append(ent) }

        let cur = build(forKey: "current_zones", from: nt.currentZones.map { ($0.name, $0.state) })
        if !cur.isEmpty { parts.append(cur) }

        let typ = build(forKey: "type", from: nt.types.map { ($0.name, $0.state) })
        if !typ.isEmpty { parts.append(typ) }

        let joined = parts.joined(separator: ",")
        templateString = joined

        DispatchQueue.main.async {
            onTemplateChanged(joined)
        }
    }

    private func applyPresetIfNeeded() {
        guard !didApplyPreset else { return }
        didApplyPreset = true

        guard let presetRawTemplate, !presetRawTemplate.isEmpty else {
            rebuildTemplateString()
            return
        }

        let map = parsePreset(presetRawTemplate)

        let camSet = map["camera"] ?? []
        let labelSet = map["label"] ?? []
        let enteredSet = map["entered_zones"] ?? []
        let currentSet = map["current_zones"] ?? []
        let typeSet = map["type"] ?? []

        for i in nt.cameras.indices { nt.cameras[i].state = camSet.contains(nt.cameras[i].name) }
        for i in nt.labels.indices { nt.labels[i].state = labelSet.contains(nt.labels[i].name) }
        for i in nt.enteredZones.indices { nt.enteredZones[i].state = enteredSet.contains(nt.enteredZones[i].name) }
        for i in nt.currentZones.indices { nt.currentZones[i].state = currentSet.contains(nt.currentZones[i].name) }
        for i in nt.types.indices { nt.types[i].state = typeSet.contains(nt.types[i].name) }

        rebuildTemplateString()
    }

    // A no-animation “disclosure” row (prevents the wonky expansion + Form row animations)
    private struct NoAnimExpander<Content: View>: View {
        let title: String
        @Binding var isExpanded: Bool
        @ViewBuilder let content: Content

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {

                Button {
                    var tx = Transaction()
                    tx.disablesAnimations = true
                    tx.animation = nil
                    withTransaction(tx) { isExpanded.toggle() }
                } label: {
                    HStack {
                        Text(title)
                            .font(.callout.weight(.semibold))

                        Spacer()

                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                }
                .buttonStyle(.plain)
                .transaction { $0.animation = nil }

                if isExpanded {
                    content
                        .transition(.identity)
                }
            }
            .animation(nil, value: isExpanded)
        }
    }

    private func toggleList<T>(
        items: Binding<[T]>,
        name: KeyPath<T, String>,
        state: WritableKeyPath<T, Bool>
    ) -> some View {

        let indices = Array(items.wrappedValue.indices)

        return VStack(alignment: .leading, spacing: 0) {
            if indices.isEmpty {
                Text("No options available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            } else {
                ForEach(indices, id: \.self) { idx in
                    let labelText = items.wrappedValue[idx][keyPath: name]

                    let isOnBinding = Binding<Bool>(
                        get: { items.wrappedValue[idx][keyPath: state] },
                        set: { newValue in
                            var copy = items.wrappedValue
                            copy[idx][keyPath: state] = newValue
                            items.wrappedValue = copy
                            rebuildTemplateString()
                        }
                    )

                    Toggle(isOn: isOnBinding) {
                        Text(labelText)
                    }
                    .tint(Color(red: 0.153, green: 0.69, blue: 1))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .transaction { tx in
                        tx.disablesAnimations = true
                        tx.animation = nil
                    }

                    if idx != indices.last {
                        Divider().opacity(0.35)
                        .padding(.horizontal, 12)
                    }
                }
            }
        }
        .padding(.top, 6)
        .transaction { tx in
            tx.disablesAnimations = true
            tx.animation = nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            NoAnimExpander(title: "Camera", isExpanded: $expandCameras) {
                toggleList(items: $nt.cameras, name: \.name, state: \.state)
                    .padding(.horizontal, 20)
            }

            NoAnimExpander(title: "Label", isExpanded: $expandLabels) {
                toggleList(items: $nt.labels, name: \.name, state: \.state)
                    .padding(.horizontal, 20)
            }

            NoAnimExpander(title: "Entered Zone", isExpanded: $expandEntered) {
                toggleList(items: $nt.enteredZones, name: \.name, state: \.state)
                    .padding(.horizontal, 20)
            }

            NoAnimExpander(title: "Current Zone", isExpanded: $expandCurrent) {
                toggleList(items: $nt.currentZones, name: \.name, state: \.state)
                    .padding(.horizontal, 20)
            }

            NoAnimExpander(title: "Type", isExpanded: $expandTypes) {
                toggleList(items: $nt.types, name: \.name, state: \.state)
                    .padding(.horizontal, 20)
            }

        }
        .transaction { tx in
            tx.disablesAnimations = true
            tx.animation = nil
        }
        .onAppear {
            // Load lists once and apply preset once.
            nt.setCameras(items: config.item.cameras)
            nt.setLabels(items: config.item.cameras)
            nt.setZones(items: config.item.cameras)
            nt.setTypes()

            applyPresetIfNeeded()
        }
        .onChange(of: presetRawTemplate) { _ in
            didApplyPreset = false
            applyPresetIfNeeded()
        }
    }
}

// MARK: - Local template store (device-tracked; renamed to avoid collisions)

struct ViewuLocalNotificationTemplate: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var rawTemplate: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var lastSentAt: Date? = nil
}

@MainActor
final class ViewuLocalNotificationTemplateStore: ObservableObject {

    static let shared = ViewuLocalNotificationTemplateStore()

    @Published private(set) var templates: [ViewuLocalNotificationTemplate] = []

    private let storageKey = "viewu_local_notification_templates_v1"

    private init() { load() }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            templates = []
            return
        }
        do {
            templates = try JSONDecoder().decode([ViewuLocalNotificationTemplate].self, from: data)
        } catch {
            templates = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(templates)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // no-op
        }
    }

    func upsert(_ t: ViewuLocalNotificationTemplate) {
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
    
    func applyTemplatesFromMQTT(newTemplateString: String) {

        // If MQTTState passes the full message, strip prefix; otherwise treat it as payload.
        let prefix = "viewu_device_event::::template::::"
        let payload = newTemplateString.hasPrefix(prefix)
            ? String(newTemplateString.dropFirst(prefix.count))
            : newTemplateString

        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty payload => clear local templates
        guard !trimmed.isEmpty else {
            templates = []
            persist()
            return
        }

        // Split using preferred delimiter "::" (robust to whitespace)
        let parts = trimmed
            .components(separatedBy: "::")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Canonicalize to stabilize comparisons
        func canonical(_ raw: String) -> String {
            raw.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: ",")
        }

        // De-dupe while preserving order
        var seen = Set<String>()
        let incoming = parts
            .map(canonical)
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }

        // Index existing by canonical raw so we preserve ids/names/lastSentAt
        var existingByRaw: [String: ViewuLocalNotificationTemplate] = [:]
        for t in templates {
            let key = canonical(t.rawTemplate)
            if !key.isEmpty { existingByRaw[key] = t }
        }

        // Build the new list (server becomes source of truth)
        var next: [ViewuLocalNotificationTemplate] = []
        next.reserveCapacity(incoming.count)

        for raw in incoming {
            if var existing = existingByRaw[raw] {
                existing.rawTemplate = raw
                // keep existing.name, createdAt, lastSentAt
                existing.updatedAt = Date()
                next.append(existing)
            } else {
                let name = suggestName(from: raw)
                var t = ViewuLocalNotificationTemplate(name: name, rawTemplate: raw)
                t.createdAt = Date()
                t.updatedAt = Date()
                t.lastSentAt = nil
                next.append(t)
            }
        }

        templates = next
        templates.sort { $0.updatedAt > $1.updatedAt }
        persist()
    }

    private func suggestName(from raw: String) -> String {
        // Very lightweight naming: "Label • Person" etc.
        let firstRule = raw.split(separator: ",").first.map(String.init) ?? ""
        let parts = firstRule.components(separatedBy: "==")
        guard parts.count == 2 else { return "Template" }

        let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let firstVal = parts[1]
            .split(separator: "|")
            .first
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? ""

        if firstVal.isEmpty { return key.capitalized }
        return "\(key.capitalized) • \(firstVal.replacingOccurrences(of: "_", with: " ").capitalized)"
    }
}


// MARK: - Shared Button Style

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(configuration.isPressed
                          ? Color.gray.opacity(0.55)
                          : Color.orange.opacity(0.85))
            )
            .foregroundColor(.white)
    }
}
