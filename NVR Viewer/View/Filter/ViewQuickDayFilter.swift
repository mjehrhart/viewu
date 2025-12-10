//
//  ViewQuickDayFilter.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 11/10/25.
//

import SwiftUI

struct ViewQuickDayFilter: View {

    // width used for each chip
    private let dateSpacer: CGFloat = (UIScreen.screenWidth - 0) / 4

    @ObservedObject private var filter2 = EventFilter.shared()
    @ObservedObject private var epsSuper = EndpointOptionsSuper.shared()

    @AppStorage("frigateAlertsRetain") private var frigateAlertsRetain: Int = 10
    @AppStorage("frigateDetectionsRetain") private var frigateDetectionsRetain: Int = 10

    // height to clear the custom bottom toolbar (tweak from caller if needed)
    private let bottomToolbarClearance: CGFloat = 0

    // MARK: - Derived data

    /// How many days we show, based on the larger Frigate retain setting.
    private var retain: Int {
        max(frigateAlertsRetain, frigateDetectionsRetain)
    }

    /// Represents one day chip (label + epoch).
    private struct DayItem: Identifiable {
        let label: String
        let epoch: Double   // start-of-day epoch
        var id: Double { epoch }
    }

    /// Generate the list of days to show, from oldest to today.
    private var dayItems: [DayItem] {
        guard retain > 0 else { return [] }

        let cal = Calendar.current
        var items: [DayItem] = []

        // Start at the beginning of today, then walk back (retain - 1) days.
        var date = cal.startOfDay(for: Date())
        if let start = cal.date(byAdding: .day, value: -(retain - 1), to: date) {
            date = start
        }

        for _ in 0..<retain {
            let comps = cal.dateComponents([.day, .month], from: date)
            let day = comps.day ?? 0
            let month = comps.month ?? 0

            let label = "\(month)/\(day)"
            let epoch = date.timeIntervalSince1970
            items.append(DayItem(label: label, epoch: epoch))

            // next day
            if let next = cal.date(byAdding: .day, value: 1, to: date) {
                date = next
            }
        }

        return items
    }

    // MARK: - Body

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 8) {

                // Orange “timeline” line
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 2)
                    .cornerRadius(1)
                    .padding(.horizontal, 32)

                // Date chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 8) {
                        ForEach(dayItems) { item in
                            let isSelected = isSameCalendarDay(
                                epoch: item.epoch,
                                date: filter2.startDate
                            )

                            DayChip(
                                title: item.label,
                                width: dateSpacer,
                                isSelected: isSelected
                            ) {
                                handleDayTapped(item)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 30)
                }
                .defaultScrollAnchor(.trailing)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
        }
        .padding(.bottom, bottomToolbarClearance)
    }

    // MARK: - Interaction

    private func handleDayTapped(_ item: DayItem) {
        // Start date: that day's midnight
        filter2.startDate = Date(timeIntervalSince1970: item.epoch)

        // End date: same day's midnight (you can expand this to +1 day if you want a range)
        filter2.endDate = Date(timeIntervalSince1970: getStartOfDayEpoch(for: item.epoch))

        EventStorage.shared.readAll3 { res in
            guard let res = res else {
                epsSuper.list3 = []
                return
            }
            epsSuper.list3 = res
        }
    }

    // MARK: - Helpers

    /// Returns the start-of-day epoch for the given epoch.
    private func getStartOfDayEpoch(for epoch: Double) -> Double {
        let cal = Calendar.current
        let date = Date(timeIntervalSince1970: epoch)
        let start = cal.startOfDay(for: date)
        return start.timeIntervalSince1970
    }

    private func isSameCalendarDay(epoch: Double, date: Date) -> Bool {
        let cal = Calendar.current
        return cal.isDate(Date(timeIntervalSince1970: epoch), inSameDayAs: date)
    }
}

// MARK: - Chip style

struct DayChip: View {
    let title: String
    let width: CGFloat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                .frame(width: width, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.16) : .clear)
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
    }
}
