import SwiftUI
import SwiftData
import UIKit

struct InboxView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \SwiftNote.dateCaptured, order: .reverse)
    private var notes: [SwiftNote]

    var body: some View {
        List {
            ForEach(notes) { note in
                NavigationLink(destination: NoteDetailView(note: note)) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 60, height: 60)
                            if let data = note.thumbnail, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(8)
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.text)
                                .lineLimit(2)
                            Text(note.dateCaptured, formatter: Self.dateFormatter)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Inbox")
        .refreshable {
            ImportService.shared.scanForNewScreenshots(context: context)
        }
        .onAppear {
            ImportService.shared.startIfNeeded(context: context)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    NavigationStack {
        InboxView()
            .modelContainer(PersistenceController.preview.container)
    }
}


