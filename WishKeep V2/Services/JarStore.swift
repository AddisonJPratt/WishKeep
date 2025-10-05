import Foundation
internal import CoreData

final class JarStore {
    static let shared = JarStore()
    private init() {}

    func create(name: String, icon: String? = nil, colorHex: String? = nil, context: NSManagedObjectContext) throws -> Jar {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw NSError(domain: "JarStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Name required"]) }

        // uniqueness check (case-insensitive)
        let fetch: NSFetchRequest<Jar> = Jar.fetchRequest()
        fetch.predicate = NSPredicate(format: "(name =[c] %@)", trimmed)
        if let existing = try? context.fetch(fetch), existing.count > 0 {
            throw NSError(domain: "JarStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "Duplicate name"]) }

        let jar = Jar(context: context)
        jar.id = UUID()
        jar.name = trimmed
        jar.icon = icon
        jar.colorHex = colorHex
        jar.createdAt = Date()
        jar.sortOrder = (try? maxSortOrder(context)) ?? 0 + 1
        try context.save()
        return jar
    }

    func rename(_ jar: Jar, to name: String, context: NSManagedObjectContext) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw NSError(domain: "JarStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Name required"]) }
        let fetch: NSFetchRequest<Jar> = Jar.fetchRequest()
        fetch.predicate = NSPredicate(format: "(name =[c] %@) AND self != %@", trimmed, jar)
        if let dup = try? context.fetch(fetch), dup.count > 0 { throw NSError(domain: "JarStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "Duplicate name"]) }
        jar.name = trimmed
        try context.save()
    }

    func add(_ note: Note, to jar: Jar, context: NSManagedObjectContext) {
        jar.addToNotes(note)
        try? context.save()
    }

    func remove(_ note: Note, from jar: Jar, context: NSManagedObjectContext) {
        jar.removeFromNotes(note)
        try? context.save()
    }

    func reorder(_ jars: [Jar], context: NSManagedObjectContext) {
        for (idx, jar) in jars.enumerated() { jar.sortOrder = Int16(idx) }
        try? context.save()
    }

    private func maxSortOrder(_ context: NSManagedObjectContext) throws -> Int16 {
        let fetch: NSFetchRequest<Jar> = Jar.fetchRequest()
        fetch.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: false)]
        fetch.fetchLimit = 1
        if let top = try context.fetch(fetch).first { return top.sortOrder }
        return 0
    }
}

extension Note {
    var isUnsorted: Bool { (self.jars as? Set<Jar>)?.isEmpty ?? true }
}


