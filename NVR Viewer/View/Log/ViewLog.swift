//
//  ViewLog.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/3/24.
//

import SwiftUI

@MainActor
struct ViewLog: View {

    // Snapshot of log entries when the view is created
    @State private var entries: [LogItem]
    // ["All", "DEBUG", "WARNING", "ERROR", ...] derived from LogLevel.label
    private let typeOptions: [String]

    @State private var selectedType: String = "All"

    @Environment(\.dismiss) private var dismiss

    init() {
        // Using the new Log API: read the published list directly
        let allEntries = Log.shared().list
        _entries = State(initialValue: allEntries)

        // Distinct types based on LogLevel labels
        let distinctTypes = Set(allEntries.map { $0.level.label })
        self.typeOptions = ["All"] + distinctTypes.sorted()
    }

    // Filtered list based on selected type
    private var filteredEntries: [LogItem] {
        if selectedType == "All" {
            return entries
        } else {
            return entries.filter { $0.level.label == selectedType }
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 8) {

                // MARK: - Type filter (segmented control)
                if typeOptions.count > 1 {
                    Picker("Type", selection: $selectedType) {
                        ForEach(typeOptions, id: \.self) { type in
                            Text(type)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 8)
                }

                // MARK: - Actions row (Clear / Scroll to Top)
                HStack {
                    Button {
                        // Clear global log and on-screen snapshot
                        Log.shared().clear()
                        entries.removeAll()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }

                    Spacer()

                    Button {
                        withAnimation {
                            proxy.scrollTo("LOG_TOP", anchor: .top)
                        }
                    } label: {
                        Label("Top", systemImage: "arrow.up.to.line")
                    }
                }
                .font(.caption)
                .padding(.horizontal, 8)

                // MARK: - Log list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {

                        // Invisible anchor at the top for scrollTo
                        Color.clear
                            .frame(height: 0)
                            .id("LOG_TOP")

                        ForEach(filteredEntries) { row in
                            LogRowView(entry: row)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                }
            }
        }
        .navigationTitle("Log")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(content: toolbarContent)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "chevron.backward")
                    Text("Back")
                }
            }
        }
    }
}


// MARK: - Row View

private struct LogRowView: View {
    let entry: LogItem

    @Environment(\.colorScheme) private var colorScheme

    // Per-row expansion state
    @State private var isExpanded: Bool = false

    // Tune this to taste
    private let previewCharacterLimit: Int = 280

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header line: level badge, page, function
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                // Level badge (DEBUG / WARNING / ERROR)
                Text(entry.level.label)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    //.background(typeColor.opacity(0.15))
                    .foregroundColor(typeColor)
                    .clipShape(Capsule())

                // Page label
                Text(entry.page)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Function name
                Text(entry.fn)
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            // Log message (truncated or full)
            Text(displayedText)
                .font(.footnote)
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)

            // "Show more / Show less" control only when needed
            if needsTruncation {
                Button {
                    isExpanded.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Show less" : "Show more")
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .padding(.top, 2)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    Color.black.opacity(colorScheme == .dark ? 0.35 : 0.06),
                    lineWidth: 0.5
                )
        )
    }

    // MARK: - Truncation helpers

    private var needsTruncation: Bool {
        entry.message.count > previewCharacterLimit
    }

    private var displayedText: String {
        guard !isExpanded, needsTruncation else {
            return entry.message
        }

        let text = entry.message
        let prefixEnd = text.index(
            text.startIndex,
            offsetBy: previewCharacterLimit,
            limitedBy: text.endIndex
        ) ?? text.endIndex

        return String(text[..<prefixEnd]) + "…"
    }

    // MARK: - Color based on level

    private var typeColor: Color {
        switch entry.level {
        case .error:
            return .red
        case .warning:
            return .orange
        case .debug:
            return Color(red: 0.153, green: 0.69, blue: 1)
        }
    }
}


////
////  ViewLog.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 6/3/24.
////
//
//import SwiftUI
//
//@MainActor
//struct ViewLog: View {
//
//    // Now mutable so Clear can update it
//    @State private var entries: [LogItem]
//    private let typeOptions: [String]   // ["All", "ERROR", "INFO", ...]
//
//    @State private var selectedType: String = "All"
//
//    @Environment(\.dismiss) private var dismiss
//
//    init() {
//        let allEntries = Log.shared().getList()
//        _entries = State(initialValue: allEntries)
//
//        let distinctTypes = Set(allEntries.map { $0.type })
//        self.typeOptions = ["All"] + distinctTypes.sorted()
//    }
//
//    // Filtered list based on selected type
//    private var filteredEntries: [LogItem] {
//        if selectedType == "All" {
//            return entries
//        } else {
//            return entries.filter { $0.type == selectedType }
//        }
//    }
//
//    var body: some View {
//        ScrollViewReader { proxy in
//            VStack(spacing: 8) {
//
//                // MARK: - Type filter (segmented control)
//                if typeOptions.count > 1 {
//                    Picker("Type", selection: $selectedType) {
//                        ForEach(typeOptions, id: \.self) { type in
//                            Text(type)
//                                .tag(type)
//                        }
//                    }
//                    .pickerStyle(.segmented)
//                    .padding(.horizontal, 8)
//                }
//
//                // MARK: - Actions row (Clear / Scroll to Top)
//                HStack {
//                    Button {
//                        // Clear global log and on-screen snapshot
//                        Log.shared().clear()        // Make sure you have this method on your Log class
//                        entries.removeAll()
//                    } label: {
//                        Label("Clear", systemImage: "trash")
//                    }
//
//                    Spacer()
//
//                    Button {
//                        withAnimation {
//                            proxy.scrollTo("LOG_TOP", anchor: .top)
//                        }
//                    } label: {
//                        Label("Top", systemImage: "arrow.up.to.line")
//                    }
//                }
//                .font(.caption)
//                .padding(.horizontal, 8)
//
//                // MARK: - Log list
//                ScrollView {
//                    LazyVStack(alignment: .leading, spacing: 12) {
//
//                        // Invisible anchor at the top for scrollTo
//                        Color.clear
//                            .frame(height: 0)
//                            .id("LOG_TOP")
//
//                        ForEach(filteredEntries, id: \.self) { row in
//                            LogRowView(entry: row)
//                        }
//                    }
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 10)
//                }
//            }
//        }
//        .navigationTitle("Log")
//        .navigationBarTitleDisplayMode(.inline)
//        .navigationBarBackButtonHidden(true)
//        .toolbar(content: toolbarContent)
//    }
//
//    // MARK: - Toolbar
//
//    @ToolbarContentBuilder
//    private func toolbarContent() -> some ToolbarContent {
//        ToolbarItem(placement: .navigationBarLeading) {
//            Button {
//                dismiss()
//            } label: {
//                HStack {
//                    Image(systemName: "chevron.backward")
//                    Text("Back")
//                }
//            }
//        }
//    }
//}
//
//
//// MARK: - Row View
//
//private struct LogRowView: View {
//    let entry: LogItem
//
//    @Environment(\.colorScheme) private var colorScheme
//
//    // NEW: per-row expansion state
//    @State private var isExpanded: Bool = false
//
//    // NEW: tune this to taste
//    private let previewCharacterLimit: Int = 280
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            // Header line: type badge, page, function
//            HStack(alignment: .firstTextBaseline, spacing: 8) {
//                // Type badge
//                Text(entry.type.uppercased())
//                    .font(.caption2.weight(.semibold))
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 4)
//                    .background(typeColor.opacity(0.15))
//                    .foregroundColor(typeColor)
//                    .clipShape(Capsule())
//
//                // Page label
//                Text(entry.page)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//
//                Spacer()
//
//                // Function name
//                Text(entry.fn)
//                    .font(.caption.monospaced())
//                    .foregroundColor(.secondary)
//                    .lineLimit(1)
//                    .truncationMode(.middle)
//            }
//
//            // Log message (truncated or full)
//            Text(displayedText)
//                .font(.footnote)
//                .foregroundColor(.primary)
//                .textSelection(.enabled)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .animation(.easeInOut(duration: 0.2), value: isExpanded)
//
//            // "Show more / Show less" control only when needed
//            if needsTruncation {
//                Button {
//                    isExpanded.toggle()
//                } label: {
//                    HStack(spacing: 4) {
//                        Text(isExpanded ? "Show less" : "Show more")
//                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
//                            .font(.caption2.weight(.semibold))
//                    }
//                }
//                .font(.caption)
//                .buttonStyle(.plain)
//                .foregroundColor(.accentColor)
//                .padding(.top, 2)
//            }
//        }
//        .padding(10)
//        .background(
//            RoundedRectangle(cornerRadius: 12, style: .continuous)
//                .fill(Color(.secondarySystemBackground))
//        )
//        .overlay(
//            RoundedRectangle(cornerRadius: 12, style: .continuous)
//                .stroke(
//                    Color.black.opacity(colorScheme == .dark ? 0.35 : 0.06),
//                    lineWidth: 0.5
//                )
//        )
//    }
//
//    // MARK: - Truncation helpers
//
//    private var needsTruncation: Bool {
//        entry.text.count > previewCharacterLimit
//    }
//
//    private var displayedText: String {
//        guard !isExpanded, needsTruncation else {
//            return entry.text
//        }
//
//        let prefixEnd = entry.text.index(
//            entry.text.startIndex,
//            offsetBy: previewCharacterLimit,
//            limitedBy: entry.text.endIndex
//        ) ?? entry.text.endIndex
//
//        return String(entry.text[..<prefixEnd]) + "…"
//    }
//
//    private var typeColor: Color {
//        switch entry.type.lowercased() {
//        case "error":
//            return .red
//        case "warning", "warn":
//            return .orange
//        case "info":
//            return .blue
//        case "debug":
//            return .gray
//        default:
//            return .secondary
//        }
//    }
//}
