import Foundation
import Photos
import SwiftData
import UIKit
import CryptoKit

final class ImportService: NSObject {
    static let shared = ImportService()

    private var screenshotsCollection: PHAssetCollection?
    private var assetsFetchResult: PHFetchResult<PHAsset>?
    private var isObserving = false

    private override init() { }

    func startIfNeeded(context: ModelContext) {
        requestPhotosIfNeeded { [weak self] granted in
            guard granted else { return }
            self?.resolveScreenshotsCollection()
            self?.registerChangeObserverIfNeeded()
            self?.scanForNewScreenshots(context: context)
        }
    }

    func scanForNewScreenshots(context: ModelContext, completion: (() -> Void)? = nil) {
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

    private func importAsset(asset: PHAsset, context: ModelContext) {
        // Create new SwiftData note
        let note = SwiftNote(
            title: "Screenshot",
            text: "", // Empty - user will paste text
            captureMode: CaptureMode.screenshots.rawValue,
            createdAt: asset.creationDate ?? Date()
        )
        
        note.imageLocalIdentifier = asset.localIdentifier
        note.coverImageLocalIdentifier = asset.localIdentifier
        note.dateCaptured = asset.creationDate ?? Date()
        note.dateImported = Date()
        
        context.insert(note)
        
        // Save immediately so the list updates, then fetch thumbnail asynchronously
        do { 
            try context.save() 
            
            self.generateThumbnail(for: asset) { data in
                if let data { 
                    note.thumbnail = data
                    try? context.save()
                }
            }
            // OCR removed - user will paste text manually
            self.showSavedBanner()
            print("[Import] Inserted screenshot note id=\(note.id.uuidString) at \(note.dateCaptured)")
        } catch { 
            print("Failed to save screenshot note: \(error)")
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
    
    func computeTextHash(_ text: String) -> String {
        let lower = text.lowercased()
        let nfkd = lower.applyingTransform(.toUnicodeName, reverse: false) ?? lower
        let stripped = nfkd.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        let data = Data(stripped.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Clipboard Merge/Create

    func mergeOrCreate(fromClipboard text: String, context: ModelContext) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Create a new SwiftData note
        let note = SwiftNote(
            title: "Clipboard Note",
            text: trimmed,
            captureMode: "clipboard",
            createdAt: Date()
        )
        
        note.textHash = self.computeTextHash(trimmed)
        note.isLongMessage = trimmed.count > 400
        note.isTruncated = false
        note.userEditedContactName = false
        note.imageLocalIdentifier = ""
        note.threadGroupId = UUID().uuidString
        
        context.insert(note)
        
        do {
            try context.save()
            print("[Clipboard] Created new note")
            self.showSavedBanner()
        } catch {
            print("Failed to save clipboard note: \(error)")
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
