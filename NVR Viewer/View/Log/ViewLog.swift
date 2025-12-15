//
//  ViewLog.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/3/24.
//

import SwiftUI

@MainActor
struct ViewLog: View {

    // Observe global log so the view updates as new entries are added / cleared
    @ObservedObject private var log = Log.shared()

    @State private var selectedType: String = "All"

    @Environment(\.dismiss) private var dismiss

    // Distinct type labels from current entries
    private var typeOptions: [String] {
        let labels = Set(log.list.map { $0.level.label })
        return ["All"] + labels.sorted()
    }

    // Filtered list, with NEWEST entries first
    private var filteredEntries: [LogItem] {
        let all = log.list

        let filtered: [LogItem]
        if selectedType == "All" {
            filtered = all
        } else {
            filtered = all.filter { $0.level.label == selectedType }
        }

        // Newest at top (assuming log.list appends at the end)
        return Array(filtered.reversed())
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
                        // Clear global log
                        Log.shared().clear()
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

                        ForEach(filteredEntries) { entry in
                            LogRowView(entry: entry)
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
        .toolbar {
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
            // Header line: level badge, page, timestamp, function
            // Header (2 rows): row 1 = level + page, row 2 = timestamp + function
            // Header: row 1 = level + page + function, row 2 = timestamp (alone)
            VStack(alignment: .leading, spacing: 4) {

                // Row 1: Level badge + Page ...... Function
                HStack(alignment: .firstTextBaseline, spacing: 8) {

                    Text(entry.level.label)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundColor(typeColor)
                        .clipShape(Capsule())

                    Text(entry.page)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer()

                    Text(entry.fn)
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                // Row 2: Timestamp ONLY (full width)
                Text(entry.timestampText)
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2) // allows wrap on small screens without truncation
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
        default:
            return .secondary
        }
    }
}

 
