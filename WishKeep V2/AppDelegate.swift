import UIKit
internal import CoreData

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let saveClipboardShortcutType = "com.wishkeep.saveClipboard"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let item = UIApplicationShortcutItem(type: saveClipboardShortcutType, localizedTitle: "Save Clipboard", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "doc.on.clipboard"), userInfo: nil)
        application.shortcutItems = [item]
        return true
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        guard shortcutItem.type == saveClipboardShortcutType else { completionHandler(false); return }
        let context = PersistenceController.shared.container.viewContext
        ClipboardManager.shared.saveClipboardIfAvailable(context: context)
        completionHandler(true)
    }
}


