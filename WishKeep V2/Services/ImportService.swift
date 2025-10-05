import Foundation
import Photos
internal import CoreData
import UIKit

final class ImportService: NSObject {
    static let shared = ImportService()

    private var screenshotsCollection: PHAssetCollection?
    private var assetsFetchResult: PHFetchResult<PHAsset>?
    private var isObserving = false

    private override init() { }

    func startIfNeeded(context: NSManagedObjectContext) {
        requestPhotosIfNeeded { [weak self] granted in
            guard granted else { return }
            self?.resolveScreenshotsCollection()
            self?.registerChangeObserverIfNeeded()
            self?.scanForNewScreenshots(context: context)
        }
    }

    func scanForNewScreenshots(context: NSManagedObjectContext, completion: (() -> Void)? = nil) {
        guard let collection = screenshotsCollection ?? resolveScreenshotsCollection() else {
            completion?(); return
        }

        let fetchOptions = PHFetchOptions()

        if let last = UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.lastIndexedAt) as? Date {
            let buffer = Date(timeInterval: -AppConstants.scanNegativeBufferSeconds, since: last)
            fetchOptions.predicate = NSPredicate(format: "creationDate > %@", buffer as NSDate)
        } else {
            // First run or unknown index: scan only recent items (last 1 day) to avoid scanning the whole library
            let since = Date().addingTimeInterval(-86400)
            fetchOptions.predicate = NSPredicate(format: "creationDate > %@", since as NSDate)
        }

        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        var assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        if assets.count == 0 {
            // Fallback: fetch last 50 items if predicate filtered everything (clock drift or missing date)
            let fallback = PHFetchOptions()
            fallback.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            assets = PHAsset.fetchAssets(in: collection, options: fallback)
        }
        self.assetsFetchResult = assets

        var newestDate: Date?

        assets.enumerateObjects { [weak self] asset, _, _ in
            if let date = asset.creationDate {
                newestDate = max(newestDate ?? date, date)
            }
            self?.importAsset(asset: asset, context: context)
        }

        if let newest = newestDate {
            UserDefaults.standard.set(newest, forKey: AppConstants.UserDefaultsKeys.lastIndexedAt)
        }

        completion?()
    }

    private func requestPhotosIfNeeded(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async { completion(newStatus == .authorized || newStatus == .limited) }
            }
        default:
            completion(false)
        }
    }

    @discardableResult
    private func resolveScreenshotsCollection() -> PHAssetCollection? {
        if let existing = screenshotsCollection { return existing }
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenshots, options: nil)
        let collection = collections.firstObject
        self.screenshotsCollection = collection
        return collection
    }

    private func registerChangeObserverIfNeeded() {
        guard !isObserving else { return }
        PHPhotoLibrary.shared().register(self)
        isObserving = true
    }

    private func importAsset(asset: PHAsset, context: NSManagedObjectContext) {
        // Dedupe by imageLocalIdentifier
        let fetch: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Note")
        fetch.fetchLimit = 1
        fetch.predicate = NSPredicate(format: "imageLocalIdentifier == %@", asset.localIdentifier)
        if let count = (try? context.count(for: fetch)), count > 0 {
            return
        }

        context.perform {
            guard let entity = NSEntityDescription.entity(forEntityName: "Note", in: context) else { return }
            let note = NSManagedObject(entity: entity, insertInto: context)
            note.setValue(UUID(), forKey: "id")
            note.setValue(asset.localIdentifier, forKey: "imageLocalIdentifier")
            note.setValue(asset.creationDate ?? Date(), forKey: "dateCaptured")
            note.setValue(Date(), forKey: "dateImported")
            note.setValue("[pending OCR]", forKey: "text")
            note.setValue(Date(), forKey: "createdAt")
            note.setValue(asset.localIdentifier, forKey: "coverImageLocalIdentifier")
            note.setValue(CaptureMode.screenshots.rawValue, forKey: "captureMode")
            // Grouping: assign threadGroupId if another note in the last 90s exists
            if let dc = asset.creationDate {
                let windowStart = dc.addingTimeInterval(-AppConstants.groupingWindowSeconds)
                let fetch: NSFetchRequest<Note> = Note.fetchRequest()
                fetch.predicate = NSPredicate(format: "dateCaptured >= %@ AND dateCaptured <= %@", windowStart as NSDate, dc as NSDate)
                fetch.sortDescriptors = [NSSortDescriptor(key: "dateCaptured", ascending: false)]
                if let recent = try? context.fetch(fetch), let neighbor = recent.first, let group = neighbor.threadGroupId, !group.isEmpty {
                    note.setValue(group, forKey: "threadGroupId")
                } else {
                    note.setValue(UUID().uuidString, forKey: "threadGroupId")
                }
            }
            // Save immediately so the list updates, then fetch thumbnail asynchronously
            do { try context.save() } catch { }
            self.generateThumbnail(for: asset) { data in
                context.perform {
                    if let data { note.setValue(data, forKey: "thumbnail") }
                    try? context.save()
                }
            }
            if let objectID = note.objectID as NSManagedObjectID? {
                OCRService.shared.enqueue(noteObjectID: objectID, assetLocalIdentifier: asset.localIdentifier, context: context)
            }
            self.showSavedBanner()
            print("[Import] Inserted screenshot note id=\((note.value(forKey: "id") as? UUID)?.uuidString ?? "?") at \(String(describing: note.value(forKey: "dateCaptured")))")
        }
    }

    private func generateThumbnail(for asset: PHAsset, completion: @escaping (Data?) -> Void) {
        let manager = PHImageManager.default()
        let targetSize = CGSize(width: AppConstants.thumbnailWidth, height: AppConstants.thumbnailWidth)
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast

        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
            let data = image?.jpegData(compressionQuality: 0.8)
            completion(data)
        }
    }

    private func showSavedBanner() {
        NotificationCenter.default.post(name: .showInboxBanner, object: nil)
    }

    // MARK: - Clipboard Merge/Create

    func mergeOrCreate(fromClipboard text: String, context: NSManagedObjectContext) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let tenMinAgo = Date().addingTimeInterval(-600)
        let fetch: NSFetchRequest<Note> = Note.fetchRequest()
        fetch.predicate = NSPredicate(format: "dateCaptured >= %@", tenMinAgo as NSDate)
        fetch.sortDescriptors = [NSSortDescriptor(key: "dateCaptured", ascending: false)]
        let recent = (try? context.fetch(fetch)) ?? []

        switch CapturePolicy.decideOnClipboardSave(text: trimmed, recentScreenshots: recent) {
        case .createNew(let mode):
            context.perform {
                guard let entity = NSEntityDescription.entity(forEntityName: "Note", in: context) else { return }
                let note = NSManagedObject(entity: entity, insertInto: context) as! Note
                note.id = UUID()
                note.text = trimmed
                note.textHash = OCRService.shared.computeTextHash(trimmed)
                note.dateCaptured = Date()
                note.dateImported = Date()
                note.createdAt = Date()
                note.captureMode = mode.rawValue
                note.isLongMessage = trimmed.count > 400
                note.threadGroupId = UUID().uuidString
                try? context.save()
                print("[Clipboard] Created new note")
                self.showSavedBanner()
            }
        case .mergeIntoScreenshot(let screenshotId, let mode):
            context.perform {
                let fetch: NSFetchRequest<Note> = Note.fetchRequest()
                fetch.fetchLimit = 1
                fetch.predicate = NSPredicate(format: "id == %@", screenshotId as CVarArg)
                guard let target = try? context.fetch(fetch).first else { return }
                target.text = trimmed
                target.textHash = OCRService.shared.computeTextHash(trimmed)
                target.captureMode = mode.rawValue
                target.isTruncated = false
                target.isLongMessage = trimmed.count > 400
                try? context.save()
                print("[Clipboard] Merged into screenshot note: \(screenshotId)")
                self.showSavedBanner()
            }
        }
    }
}

extension ImportService: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fetchResult = self.assetsFetchResult,
              changeInstance.changeDetails(for: fetchResult) != nil else {
            return
        }
        DispatchQueue.main.async {
            guard UIApplication.shared.connectedScenes.first is UIWindowScene else { return }
            // We don't have direct access to context here; rely on the root SwiftUI environment by notifying.
            NotificationCenter.default.post(name: .photoLibraryChangedReimport, object: nil)
        }
    }
}

extension Notification.Name {
    static let showInboxBanner = Notification.Name("ImportShowInboxBanner")
    static let photoLibraryChangedReimport = Notification.Name("PhotoLibraryChangedReimport")
}
