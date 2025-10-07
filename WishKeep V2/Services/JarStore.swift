import Foundation
import SwiftData

final class JarStore {
    static let shared = JarStore()
    private init() {}

    func create(name: String, icon: String? = nil, colorHex: String? = nil, context: ModelContext) throws -> Jar {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw NSError(domain: "JarStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Name required"]) }

        // Create new jar
        let jar = Jar(name: trimmed, icon: icon, colorHex: colorHex)
        jar.sortOrder = (try? maxSortOrder(context)) ?? 0 + 1
        context.insert(jar)
        try context.save()
        return jar
    }

    func rename(_ jar: Jar, to name: String, context: ModelContext) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw NSError(domain: "JarStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Name required"]) }
        
        jar.name = trimmed
        try context.save()
    }

    func add(_ note: SwiftNote, to jar: Jar, context: ModelContext) {
        jar.notes.append(note)
        try? context.save()
    }

    func remove(_ note: SwiftNote, from jar: Jar, context: ModelContext) {
        jar.notes.removeAll { $0.id == note.id }
        try? context.save()
    }

    func reorder(_ jars: [Jar], context: ModelContext) {
        for (idx, jar) in jars.enumerated() { jar.sortOrder = Int16(idx) }
        try? context.save()
    }

    private func maxSortOrder(_ context: ModelContext) throws -> Int16 {
        var descriptor = FetchDescriptor<Jar>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.sortOrder ?? 0
    }
}

extension Notification.Name {
    static let jarAddedPing = Notification.Name("JarAddedPing")
}

extension SwiftNote {
    var isUnsorted: Bool { self.jars.isEmpty }
}