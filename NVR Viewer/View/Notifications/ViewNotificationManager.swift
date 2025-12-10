//
//  ViewNotificationManager.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/5/24.
//

import SwiftUI
import TipKit
import PopupView

// MARK: - Shared Button Style

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(configuration.isPressed
                          ? Color.gray.opacity(0.7)
                          : Color.orange.opacity(0.8))
            )
            .foregroundColor(.white)
    }
}

// MARK: - APN View

@MainActor
struct ViewAPN: View {

    let title: String

    private let nvr = NVRConfig.shared()

    @AppStorage("apnTitle") private var apnTitle: String = ""
    @AppStorage("apnDomain") private var apnDomain: String = ""
    @AppStorage("viewu_server_version") private var viewuServerVersion: String = "0.0.0"

    @AppStorage("tipShowNotificationGeneral") private var tipShowNotificationGeneral: Bool = true
    @AppStorage("tipsNotificationTemplate")  private var tipsNotificationTemplate: Bool = true
    @AppStorage("tipsNotificationDomain")    private var tipsNotificationDomain: Bool = true
    @AppStorage("tipsNotificationDefault")   private var tipsNotificationDefault: Bool = true

    @StateObject private var nts         = NotificationTemplateString.shared()
    @StateObject private var mqttManager = MQTTManager.shared()

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 0) {

                // Version warning banner
                if requiresNewerServer {
                    VersionWarningBanner(currentVersion: viewuServerVersion)
                }

                // Paused banner
                if nts.notificationPaused {
                    PausedBanner()
                }

                // Main form
                Form {
                    notificationTitleSection
                    domainSection
                    templatesSection

                    // Dynamic template builder UI
                    ForEach(nts.templateList, id: \.self) { template in
                        template
                    }

                    pauseSection
                }
            }

            // Popup overlay
            if nts.alert {
                PopupMiddle {
                    nts.alert = false
                }
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
        .task {
            // Ensure there is at least one template builder
            if nts.templateList.isEmpty {
                nts.templateList.append(ViewNotificationManager(vid: UUID()))
            }
        }
        .onAppear {
            // Default APN domain to current NVR URL if empty
            if apnDomain.isEmpty {
                apnDomain = nvr.getUrl()
            }
        }
    }

    // MARK: - Derived

    /// Returns true if Viewu Server is older than 0.3.x
    private var requiresNewerServer: Bool {
        let parts = viewuServerVersion.split(separator: ".")
        guard parts.count >= 2,
              let minor = Int(parts[1]) else {
            return false
        }
        // Require 0.3.0 or later
        return minor < 3
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
            TextField("https://domaintoviewnvr.com", text: $apnDomain)
                .frame(alignment: .leading)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .overlay(IndicatorOverlay(offset: -80, flag: nts.flagDomain))
                .onChange(of: apnDomain) { _ in
                    nts.flagDomain = false
                }

            HStack {
                Spacer()
                Button("Save") {
                    let msg = "viewu_device_event::::domain::::\(apnDomain)"
                    publishAPN(message: msg)
                }
                .buttonStyle(PrimaryActionButtonStyle())
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

    private var templatesSection: some View {
        Section {
            // Little indicator row
            Text("")
                .frame(maxWidth: .infinity, maxHeight: 4, alignment: .leading)
                .overlay(IndicatorOverlay(offset: -65, flag: nts.flagTemplate))

            // Saved templates
            ForEach(0..<nts.templates.count, id: \.self) { index in
                Text(nts.templates[index].template)
            }
            .onDelete { indexes in
                for index in indexes {
                    nts.templates.remove(at: index)
                }
                nts.flagTemplate = false
            }

            // Save button
            HStack {
                Spacer()
                Button("Save") {
                    let templateString = nts.buildTemplateString()
                    let msg = "viewu_device_event::::template::::\(templateString)"
                    publishAPN(message: msg)
                }
                .buttonStyle(PrimaryActionButtonStyle())
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
                    This helps reduce the number of notifications received and lets you specify \
                    which events you get notified for. Filtering notifications by the type field \
                    can significantly reduce noise and keep only the important events.
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

    // MARK: - Helpers

    private func publishAPN(message: String) {
        withAnimation(.easeInOut) {
            mqttManager.publish(topic: "viewu/pairing", with: message)
        }
        // nts.alert is managed elsewhere; PopupMiddle appears when that flag is true
    }

    // MARK: - Nested Views

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

    struct Popup: View {
        var body: some View {
            VStack {
                Spacer()

                VStack {
                    HStack {
                        Spacer()
                        Text("Synced with Viewu Server")
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Color.mint.opacity(0.5))
                }
                .frame(width: 300, height: 250, alignment: .center)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white)
            .ignoresSafeArea()
        }
    }
}

// MARK: - Popup Overlay

struct PopupMiddle: View {

    var onClose: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack {
                HStack {
                    VStack(spacing: 20) {
                        Text("Synced with Viewu Server")
                            .foregroundColor(.black)
                            .font(.system(size: 19))
                            .padding(.bottom, 12)

                        Image(systemName: "server.rack")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 226, maxHeight: 100)
                    }
                    .padding(EdgeInsets(top: 37, leading: 24, bottom: 40, trailing: 24))
                    .background(Color.white.cornerRadius(20))
                    .padding(.horizontal, 10)
                }
                .padding(.trailing, 40)
                .padding(.leading, 70)
            }

            Spacer()
        }
        .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .topLeading)
        .background(Color.black.opacity(0.4))
        .ignoresSafeArea()
        .onTapGesture {
            onClose()
        }
    }
}

// MARK: - ViewNotificationManager

struct ViewNotificationManager: View, Hashable, Equatable {

    let cNVR = APIRequester()
    let nvr = NVRConfig.shared()

    @StateObject var nts = NotificationTemplateString.shared()
    @ObservedObject var nt  = NotificationTemplate()
    @ObservedObject var config = NVRConfigurationSuper2.shared()

    @State var cameraTemplate      = ""
    @State var labelTemplate       = ""
    @State var currentZoneTemplate = ""
    @State var enteredZoneTemplate = ""
    @State var typeTemplate        = ""
    @State var templateString      = ""

    @State var id  = UUID()
    @State var vid = UUID()

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func ==(lhs: ViewNotificationManager, rhs: ViewNotificationManager) -> Bool {
        lhs.vid == rhs.vid &&
        lhs.id == rhs.id &&
        lhs.cameraTemplate == rhs.cameraTemplate &&
        lhs.labelTemplate == rhs.labelTemplate &&
        lhs.currentZoneTemplate == rhs.currentZoneTemplate &&
        lhs.enteredZoneTemplate == rhs.enteredZoneTemplate &&
        lhs.typeTemplate == rhs.typeTemplate &&
        lhs.templateString == rhs.templateString
    }

    // Build the template string and push into nts
    func buildTemplate() -> String {
        templateString = ""

        if !cameraTemplate.isEmpty {
            cameraTemplate = cameraTemplate.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
            templateString += "\(cameraTemplate), "
        }
        if !labelTemplate.isEmpty {
            labelTemplate = labelTemplate.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
            templateString += "\(labelTemplate), "
        }
        if !currentZoneTemplate.isEmpty {
            currentZoneTemplate = currentZoneTemplate.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
            templateString += "\(currentZoneTemplate), "
        }
        if !enteredZoneTemplate.isEmpty {
            enteredZoneTemplate = enteredZoneTemplate.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
            templateString += "\(enteredZoneTemplate), "
        }
        if !typeTemplate.isEmpty {
            typeTemplate = typeTemplate.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
            templateString += "\(typeTemplate), "
        }

        if templateString.hasSuffix(", ") {
            let startIndex = templateString.index(templateString.startIndex, offsetBy: 0)
            let endIndex = templateString.index(templateString.endIndex, offsetBy: -2)
            templateString = String(templateString[startIndex..<endIndex])
        }

        nts.pushTemplate(id: id, template: templateString)
        return templateString
    }

    var body: some View {
        Section {
            // Cameras
            DisclosureGroup {
                ForEach(0..<nt.cameras.count, id: \.self) { index in
                    Toggle(nt.cameras[index].name, isOn: $nt.cameras[index].state)
                        .onChange(of: nt.cameras[index].state) { _ in
                            var tmp = ""
                            cameraTemplate = ""

                            for camera in nt.cameras where camera.state {
                                tmp += camera.name + "|"
                            }

                            if !tmp.isEmpty {
                                cameraTemplate = "camera==\(tmp)"
                            }
                            nt.templateString = buildTemplate()
                        }
                }
            } label: {
                Text("Camera")
                    .frame(height: 40)
            }

            // Labels
            DisclosureGroup {
                ForEach(0..<$nt.labels.count, id: \.self) { index in
                    Toggle(nt.labels[index].name, isOn: $nt.labels[index].state)
                        .onChange(of: nt.labels[index].state) { _ in
                            var tmp = ""
                            labelTemplate = ""

                            for label in nt.labels where label.state {
                                tmp += label.name + "|"
                            }

                            if !tmp.isEmpty {
                                labelTemplate = "label==\(tmp)"
                            }
                            nt.templateString = buildTemplate()
                        }
                }
            } label: {
                Text("Label")
                    .frame(height: 40)
            }

            // Entered Zones
            DisclosureGroup {
                ForEach(0..<$nt.enteredZones.count, id: \.self) { index in
                    Toggle(nt.enteredZones[index].name, isOn: $nt.enteredZones[index].state)
                        .onChange(of: nt.enteredZones[index].state) { _ in
                            var tmp = ""
                            enteredZoneTemplate = ""

                            for zone in nt.enteredZones where zone.state {
                                tmp += zone.name + "|"
                            }

                            if !tmp.isEmpty {
                                enteredZoneTemplate = "entered_zones==\(tmp)"
                            }
                            nt.templateString = buildTemplate()
                        }
                }
            } label: {
                Text("Entered Zone")
                    .frame(height: 40)
            }

            // Current Zones
            DisclosureGroup {
                ForEach(0..<$nt.currentZones.count, id: \.self) { index in
                    Toggle(nt.currentZones[index].name, isOn: $nt.currentZones[index].state)
                        .onChange(of: nt.currentZones[index].state) { _ in
                            var tmp = ""
                            currentZoneTemplate = ""

                            for zone in nt.currentZones where zone.state {
                                tmp += zone.name + "|"
                            }

                            if !tmp.isEmpty {
                                currentZoneTemplate = "current_zones==\(tmp)"
                            }
                            nt.templateString = buildTemplate()
                        }
                }
            } label: {
                Text("Current Zone")
                    .frame(height: 40)
            }

            // Types
            DisclosureGroup {
                ForEach(0..<$nt.types.count, id: \.self) { index in
                    Toggle(nt.types[index].name, isOn: $nt.types[index].state)
                        .onChange(of: nt.types[index].state) { _ in
                            var tmp = ""
                            typeTemplate = ""

                            for type in nt.types where type.state {
                                tmp += type.name + "|"
                            }

                            if !tmp.isEmpty {
                                typeTemplate = "type==\(tmp)"
                            }
                            nt.templateString = buildTemplate()
                        }
                }
            } label: {
                Text("Type")
                    .frame(height: 40)
            }

            // Live template preview
            ScrollView(.horizontal) {
                Text(templateString)
                    .font(.title2)
                    .frame(maxWidth: .infinity, maxHeight: 50)
            }

            // Add Template button
            GeometryReader { geometry in
                Button("Add Template", systemImage: "plus.app") {
                    nts.templateList.removeAll()
                    nts.templateList.append(ViewNotificationManager(vid: UUID()))
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .frame(width: geometry.size.width + 5, alignment: .trailing)
            }

        } header: {
            Text("Template")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .task {
            nt.setCameras(items: config.item.cameras)
            nt.setLabels(items: config.item.cameras)
            nt.setZones(items: config.item.cameras)
            nt.setTypes()
        }
    }

    struct iOSCheckboxToggleStyle: ToggleStyle {
        func makeBody(configuration: Configuration) -> some View {
            Button(action: {
                configuration.isOn.toggle()
            }, label: {
                HStack {
                    Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                    configuration.label
                }
            })
        }
    }
}
