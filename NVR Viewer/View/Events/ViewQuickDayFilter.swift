import SwiftUI

struct ViewQuickDayFilter: View {

    let fontSize: CGFloat = 20
    let dateSpacer: CGFloat = (UIScreen.screenWidth - 0) / 4

    var days = [String]()
    var daysEpoch = [Double]()

    @ObservedObject var filter2 = EventFilter.shared()
    @ObservedObject var epsSuper = EndpointOptionsSuper.shared()

    @AppStorage("frigateAlertsRetain")  var frigateAlertsRetain: Int = 10
    @AppStorage("frigateDetectionsRetain")  var frigateDetectionsRetain: Int = 10
    var retain = 5

    @Environment(\.scenePhase) var scenePhase

    // height to clear the custom bottom toolbar
    private let bottomToolbarClearance: CGFloat = 0

    init() {
        if frigateAlertsRetain > frigateDetectionsRetain {
            retain = frigateAlertsRetain
        } else {
            retain = frigateDetectionsRetain
        }

        let cal = Calendar.current
        var date = cal.startOfDay(for: Date())
        date = cal.date(byAdding: .day, value: -(retain - 1), to: date)!

        for _ in 1...retain {
            let day = cal.component(.day, from: date)
            let month = cal.component(.month, from: date)
            days.append("\(month)/\(day)")
            daysEpoch.append(date.timeIntervalSince1970)
            date = cal.date(byAdding: .day, value: 1, to: date)!
        }
    }

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
                        ForEach(0..<days.count, id: \.self) { index in
                            let isSelected = isSameCalendarDay(
                                epoch: daysEpoch[index],
                                date: filter2.startDate
                            )

                            DayChip(
                                title: days[index],
                                width: dateSpacer,
                                isSelected: isSelected
                            ) {
                                // tap
                                filter2.startDate = Date(timeIntervalSince1970: daysEpoch[index])
                                filter2.endDate = Date(
                                    timeIntervalSince1970:
                                        getDays(time: getDays(time: daysEpoch[index]))
                                )

                                EventStorage.shared.readAll3 { res in
                                    epsSuper.list3 = res!
                                }
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
//            .background(
//                // glassy floating card, same style as bottom toolbar
//                RoundedRectangle(cornerRadius: 24, style: .continuous)
//                    .fill(.ultraThinMaterial)
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 24, style: .continuous)
//                    .stroke(Color.white.opacity(0.10))
//            )
//            .shadow(radius: 8, y: 2)
            .padding(.horizontal, 16)
        }
        .padding(.bottom, bottomToolbarClearance)
    }

    // MARK: - Helpers

    private func getDays(time: Double) -> Double {
        let cal = Calendar.current
        var date = cal.startOfDay(for: Date(timeIntervalSince1970: time))
        date = cal.date(byAdding: .day, value: 0, to: date)!
        return date.timeIntervalSince1970
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
