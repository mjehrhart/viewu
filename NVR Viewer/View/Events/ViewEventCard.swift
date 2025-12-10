//
//  ViewEventCard.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/15/24.
//

import SwiftUI

struct ViewEventCard: View {

    // Events that share the same frameTime (group)
    @State private var containers: [EndpointOptions]

    @ObservedObject private var epsSuper = EndpointOptionsSuper.shared()

    @AppStorage("developerModeIsOn") private var developerModeIsOn: Bool = false
    @AppStorage("frigatePlusOn")     private var frigatePlusOn: Bool = false

    private let nvr = NVRConfig.shared()
    private let api = APIRequester()

    private let fontSizeDate: CGFloat = 20
    private let fontSizeLabel: CGFloat = 13

    // Device type helper
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    // MARK: - Init

    init(frameTime: Double) {
        _containers = State(
            initialValue: EventStorage.shared.getEventByFrameTime(frameTime3: frameTime)
        )
    }

    // MARK: - Layout helpers

    private func setWidth() -> CGFloat {
        idiom == .pad ? 200 : 110
    }

    private func setHeight() -> CGFloat {
        if idiom == .pad {
            return setWidth() * 16 / 9
        } else {
            return 166
        }
    }

    // MARK: - Body

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        ForEach(containers.indices, id: \.self) { index in
            let container = containers[index]

            VStack {
                // One event row
                HStack(alignment: .top, spacing: 12) {

                    // LEFT: time + meta
                    VStack(alignment: .leading, spacing: 4) {

                        // Time (NavigationLink)
                        NavigationLink(convertTime(time: container.frameTime ?? 0),
                                       value: container)
                        .font(.system(size: fontSizeDate, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.18, green: 0.18, blue: 0.18))
                        .padding(.top, 4)

                        // Date
                        Text(convertDate(time: container.frameTime ?? 0))
                            .foregroundColor(.gray)
                            .font(.system(size: fontSizeLabel, weight: .regular))

                        // Label
                        Text(container.label ?? "")
                            .font(.system(size: fontSizeLabel, weight: .regular))
                            .foregroundColor(.gray.opacity(0.9))

                        if developerModeIsOn, let score = container.score {
                            Text("\(score)")
                                .font(.system(size: fontSizeLabel, weight: .regular))
                                .foregroundColor(.gray.opacity(0.9))
                        }

                        if let sublabel = container.sublabel, !sublabel.isEmpty {
                            Text(sublabel)
                                .font(.system(size: fontSizeLabel, weight: .thin))
                                .foregroundColor(.gray.opacity(0.8))
                        }

                        if developerModeIsOn, let type = container.type {
                            Text(type)
                                .font(.system(size: fontSizeLabel, weight: .thin))
                                .foregroundColor(.gray.opacity(0.8))
                        }

                        Spacer(minLength: 4)

                        // Optional Frigate+ button
                        if frigatePlusOn,
                           (container.frigatePlus ?? false) == false,
                           let eventId = container.id {
                            Button {
                                handleFrigatePlusTap(for: index, eventId: eventId)
                            } label: {
                                Text("Frigate+")
                                    .font(.system(size: 11, weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule().fill(Color.black.opacity(0.08))
                                    )
                            }
                            .buttonStyle(CustomPressEffectButtonStyle())
                            .tint(Color(white: 0.58))
                            .padding(.top, 4)
                            .padding(.bottom, 8)
                        }

                        if developerModeIsOn, let transportType = container.transportType {
                            Text(transportType)
                                .font(.system(size: fontSizeLabel, weight: .thin))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: setWidth(), maxHeight: .infinity, alignment: .leading)

                    // RIGHT: snapshot image
                    ZStack(alignment: .topTrailing) {
                        if let snapshot = container.snapshot,
                           let frameTime = container.frameTime {
                            ViewEventImage(
                                urlString: snapshot,
                                frameTime: frameTime,
                                frigatePlus: container.frigatePlus ?? false,
                                widthG: 302,
                                heightG: 180
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    cardShape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(.secondarySystemBackground).opacity(0.46),
                                    Color(.secondarySystemBackground).opacity(0.96)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    ZStack {
                        // Outer border
                        cardShape
                            .stroke(Color.black.opacity(0.05), lineWidth: 0.7)

                        // Inner “glass” border
                        cardShape
                            .inset(by: 4)
                            .stroke(Color(.secondarySystemBackground).opacity(0.45), lineWidth: 0.6)
                    }
                )
                .shadow(color: Color.gray.opacity(0.10), radius: 10, x: 0, y: 6)
                .contentShape(Rectangle())
                .padding(.horizontal, 2)
                .padding(.vertical, 3)

                // Developer-only: show snapshot URL
                if developerModeIsOn, let snapshot = container.snapshot {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(snapshot)
                            .font(.system(size: fontSizeLabel))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .bottomLeading)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .onDelete(perform: handleDelete)
    }

    // MARK: - Actions

    private func handleFrigatePlusTap(for index: Int, eventId: String) {
        Task {
            // Optimistically mark in local state
            containers[index].frigatePlus = true

            let url = nvr.getUrl()
            let endpoint = "/api/events/\(eventId)/plus"

            await api.postImageToFrigatePlus(
                urlString: url,
                endpoint: endpoint,
                eventId: eventId,
                authType: nvr.getAuthType()
            ) { data, error in
                guard let data = data else {
                    // revert if no data
                    containers[index].frigatePlus = false
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(
                        with: data,
                        options: .fragmentsAllowed
                    ) as? [String: Any] {

                        if let res = json["success"] as? Int, res == 1 {
                            EventStorage.shared.updateFrigatePlus(id: eventId, value: true)
                            EventStorage.shared.readAll3 { res in
                                epsSuper.list3 = res ?? []
                            }
                        } else if let msg = json["message"] as? String,
                                  msg == "PLUS_API_KEY environment variable is not set" {
                            containers[index].frigatePlus = false
                            EventStorage.shared.updateFrigatePlus(id: eventId, value: false)
                        }
                    }
                } catch {
                    Log.shared().print(
                        page: "ViewEventCard",
                        fn: "FrigatePlusButton",
                        type: "ERROR",
                        text: "\(error)"
                    )
                }
            }
        }
    }

    private func handleDelete(_ indexSet: IndexSet) {
        guard !containers.isEmpty else { return }

        var didChange = false

        for index in indexSet.sorted(by: >) {
            guard containers.indices.contains(index),
                  let frameTime = containers[index].frameTime else { continue }

            let success = EventStorage.shared.delete(frameTime: frameTime)
            if success {
                containers.remove(at: index)
                didChange = true
            }
        }

        if didChange {
            EventStorage.shared.readAll3 { res in
                epsSuper.list3 = res ?? []
            }
        }
    }

    // MARK: - Date helpers (cached formatters)

    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .none
        df.timeZone = .current
        return df
    }()

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .none
        df.dateStyle = .medium
        df.timeZone = .current
        return df
    }()

    private func convertDate(time: Double) -> String {
        let date = Date(timeIntervalSince1970: time)
        return Self.dateFormatter.string(from: date)
    }

    private func convertTime(time: Double) -> String {
        let date = Date(timeIntervalSince1970: time)
        return Self.timeFormatter.string(from: date)
    }
}

// MARK: - Button style (can be shared in its own file)

//struct CustomPressEffectButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .padding(8)
//            .background(configuration.isPressed ? Color.gray : Color.orange.opacity(0.6))
//            .foregroundColor(.white)
//            .cornerRadius(10)
//    }
//}

#Preview {
    ViewEventCard(frameTime: 1710541384.496615)
        .modelContainer(for: ImageContainer.self)
}
