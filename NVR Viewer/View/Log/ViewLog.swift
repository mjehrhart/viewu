//
//  ViewLog.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/3/24.
//

import SwiftUI

@MainActor
struct ViewLog: View {

    // Snapshot of the log at the time this screen is opened
    private let entries: [LogItem]
    private let typeOptions: [String]   // ["All", "ERROR", "INFO", ...]

    @State private var selectedType: String = "All"

    // Use the dismiss action
    @Environment(\.dismiss) private var dismiss

    init() {
        let allEntries = Log.shared().getList()
        self.entries = allEntries

        let distinctTypes = Set(allEntries.map { $0.type })
        self.typeOptions = ["All"] + distinctTypes.sorted()
    }

    // Filtered list based on selected type
    private var filteredEntries: [LogItem] {
        if selectedType == "All" {
            return entries
        } else {
            return entries.filter { $0.type == selectedType }
        }
    }

    var body: some View {
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

            // MARK: - Log list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(filteredEntries, id: \.self) { row in
                        LogRowView(entry: row)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
        }
        .navigationTitle("Log")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss() // Manually dismiss the view
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header line: type badge, page, function
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                // Type badge
                Text(entry.type.uppercased())
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeColor.opacity(0.15))
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

            // Log message
            Text(entry.text)
                .font(.footnote)
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
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

    private var typeColor: Color {
        switch entry.type.lowercased() {
        case "error":
            return .red
        case "warning", "warn":
            return .orange
        case "info":
            return .blue
        case "debug":
            return .gray
        default:
            return .secondary
        }
    }
}


/*
 import SwiftUI
 
 struct User: Identifiable {
 let id: Int
 var name: String
 var score: Int
 var page: String
 }
 
 struct ViewLog: View {
 
 var list: [LogItem] = []
 
 @State private var users = [
 User(id: 1, name: "Taylor Swift", score: 95, page: "MQTTSTATE"),
 User(id: 2, name: "Justin Bieber", score: 80, page: "ContentView"),
 User(id: 3, name: "Adele Adkins", score: 85, page: "EventStorage")
 ]
 
 //Use the dismiss action
 @Environment(\.dismiss) var dismiss
 
 init() {
 self.list = Log.shared().getList()
 }
 var body: some View {
 
 VStack{
 ScrollView{
 ForEach(list, id: \.self) { row in
 
 HStack{
 Text(row.type)
 .font(.caption)
 .frame(width: 50, alignment: .topLeading)
 Divider().frame(width: 1)
 Text(row.page)
 .font(.caption)
 .frame(width: 100, alignment: .topLeading)
 Divider().frame(width: 1)
 Text(row.fn)
 .font(.caption)
 .frame( maxWidth: .infinity, alignment: .topLeading) //changed from width
 }
 .frame(width: UIScreen.screenWidth, alignment: .topLeading)
 
 Text(row.text)
 .font(.callout)
 .frame(width: UIScreen.screenWidth, alignment: .topLeading)
 .textSelection(.enabled)
 
 Divider()
 }
 }
 .frame(width: UIScreen.screenWidth, alignment: .topLeading)
 }
 .padding([.leading, .trailing], 5)
 .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight - 140, alignment: .topLeading)
 .navigationBarBackButtonHidden(true)
 .toolbar {
 ToolbarItem(placement: .topBarLeading) {
 Button(action: {
 dismiss() // Manually dismiss the view
 }) {
 HStack {
 Image(systemName: "chevron.backward")
 Text("Back")
 }
 }
 }
 }
 }
 }
 
 //#Preview {
 //    ViewLog()
 //}
 */
